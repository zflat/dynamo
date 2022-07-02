require "dynamo/resources/file"

module FileReader
  def read_file_content(path, allow_empty = false)
    # these are currently ResourceSkipped to maintain consistency with the resource
    # pre-refactor (which used skip_resource). These should likely be changed to
    # ResourceFailed during a major version bump.
    file = dynamo.file(path)
    unless file.file?
      raise Dynamo::Exceptions::ResourceSkipped, "Can't find file: #{path}"
    end

    raw_content = file.content
    if raw_content.nil?
      raise Dynamo::Exceptions::ResourceSkipped, "Can't read file: #{path}"
    end

    if !allow_empty && raw_content.empty?
      raise Dynamo::Exceptions::ResourceSkipped, "File is empty: #{path}"
    end

    raw_content
  end
end
