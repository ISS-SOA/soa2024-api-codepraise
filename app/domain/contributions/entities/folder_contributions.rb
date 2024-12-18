# frozen_string_literal: true

module CodePraise
  module Entity
    # Aggregate root for contributions domain
    class FolderContributions < SimpleDelegator
      include Mixins::ContributionsCalculator

      attr_reader :path, :files, :base_files, :subfolders

      def initialize(path:, files:)
        super(Types::AutoArrayHash.new)

        @path = path
        @files = files
        @base_files = assign_base_files
        @subfolders = subfolder_contributions
      end

      def line_count
        files.map(&:line_count).sum
      end

      def total_credits
        files.map(&:total_credits).sum
      end

      def lines
        files.map(&:lines).reduce(&:+)
      end

      def any_subfolders?
        subfolders.count.positive?
      end

      def any_base_files?
        base_files.count.positive?
      end

      def credit_share
        @credit_share ||= files.map(&:credit_share).reduce(&:+)
      end

      def contributors
        credit_share.contributors
      end

      private

      def folder_path
        path.empty? ? path : "#{path}/"
      end

      def nested_files
        files - base_files
      end

      def assign_base_files
        files
          .select { |file| file.file_path.directory == folder_path }
          .each   { |base_file| self[base_file.file_path.filename] = base_file }
      end

      def subfolder_files
        nested_files
          .each_with_object(Types::AutoArrayHash.new) do |nested, lookup|
            subfolder = nested.file_path.folder_after(folder_path)
            lookup[subfolder] << nested
          end
      end

      def subfolder_contributions
        folder_contribs = subfolder_files.map do |folder_name, folder_files|
          FolderContributions.new(path: folder_name, files: folder_files)
        end

        folder_contribs.each { |folder| self[folder.path] = folder }
      end
    end
  end
end
