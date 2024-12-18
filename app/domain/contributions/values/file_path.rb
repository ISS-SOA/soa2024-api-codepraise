# frozen_string_literal: true

require_relative 'code_language'

module CodePraise
  module Value
    # Value of a file's full path (delegates to String)
    class FilePath < SimpleDelegator
      # rubocop:disable Style/RedundantSelf
      FILE_PATH_REGEX = %r{(?<directory>.*/)(?<filename>[^/]+)}

      attr_reader :directory, :filename

      def initialize(filepath)
        super
        parse_path
      end

      def extension
        @extension ||= filename.match(/\.([a-zA-Z0-9]+$)/).captures.first
      end

      def language
        CodeLanguage.extension_language(extension)
      end

      def folder_after(root)
        raise(ArgumentError, 'Path mismatch') unless
          self.start_with?(root) || root.empty?

        matches = self.match(%r{(?<folder>^#{root}[^/]+)/?})
        matches[:folder]
      end

      private

      def parse_path
        names = self.match(FILE_PATH_REGEX)
        @directory = names ? names[:directory] : ''
        @filename = names ? names[:filename] : self
      end
      # rubocop:enable Style/RedundantSelf
    end
  end
end
