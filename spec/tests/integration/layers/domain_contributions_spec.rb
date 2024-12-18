# frozen_string_literal: true

require_relative '../../../helpers/spec_helper'
require_relative '../../../helpers/vcr_helper'
require_relative '../../../helpers/database_helper'

describe 'Test Git Commands Mapper and Gateway' do
  VcrHelper.setup_vcr

  before do
    VcrHelper.configure_vcr_for_github
    DatabaseHelper.wipe_database

    gh_project = CodePraise::Github::ProjectMapper
      .new(GITHUB_TOKEN)
      .find(USERNAME, PROJECT_NAME)

    project = CodePraise::Repository::For.entity(gh_project)
      .create(gh_project)

    @gitrepo = CodePraise::GitRepo.new(project)
    @gitrepo.clone unless @gitrepo.exists_locally?
  end

  after do
    VcrHelper.eject_vcr
  end

  it 'HAPPY: should get contributions summary for entire repo' do
    root = CodePraise::Mapper::Contributions.new(@gitrepo).for_folder('')
    _(root.subfolders.count).must_equal 10
    _(root.base_files.count).must_equal 2

    first_file = root.base_files.first
    _(%w[init.rb README.md]).must_include first_file.file_path.filename
    _(root.subfolders.first.path.size).must_be :>, 0

    subfolders_plus_basefiles =
      root.subfolders.map(&:credit_share).reduce(&:+) +
      root.base_files.map(&:credit_share).reduce(&:+)

    _(subfolders_plus_basefiles.share.values.sort)
      .must_equal(root.credit_share.share.values.sort)

    _(subfolders_plus_basefiles.contributors.map(&:email).sort)
      .must_equal(root.credit_share.contributors.map(&:email).sort)
  end

  it 'HAPPY: should get accurate contributions summary for specific folder' do
    forms = CodePraise::Mapper::Contributions.new(@gitrepo).for_folder('forms')

    _(forms.subfolders.count).must_equal 1
    _(forms.subfolders.count).must_equal 1

    _(forms.base_files.count).must_equal 2

    count = forms['url_request.rb'].credit_share.by_email 'b37582000@gmail.com'
    _(count).must_equal 5

    count = forms['url_request.rb'].credit_share.by_email 'orange6318@hotmail.com'
    _(count).must_equal 2

    count = forms['init.rb'].credit_share.by_email 'b37582000@gmail.com'
    _(count).must_equal 4
  end
end
