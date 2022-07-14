require "dynamo/errors"

module Dynamo
  module Deprecation
    class Error < Dynamo::Error; end

    class NoSuchGroupError < Error; end

    class InvalidConfigFileError < Error; end
    class MalformedConfigFileError < InvalidConfigFileError; end
    class UnrecognizedActionError < InvalidConfigFileError; end
    class UnrecognizedOutputStreamError < InvalidConfigFileError; end
  end
end
