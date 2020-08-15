require "rest-client"

class GitterNotificationResource
  module OutParams
    STATUS = "status"
    MESSAGE = "message"
    MESSAGE_FILE = "message_file"
  end

  MESSAGE_FILES_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "messages"))
  UNKNOWN_STATUS = "unknown"

  attr_reader :webhook, :dryrun

  def initialize(source = {})
    @webhook = source.fetch("webhook")
    @dryrun = source.fetch("dryrun", false)
  end

  def out(params = {})
    if !params.key?(OutParams::STATUS) && !params.key?(OutParams::MESSAGE) && !params.key?(OutParams::MESSAGE_FILE)
      raise KeyError.new("could not find 'status', 'message', or 'message_file'")
    end

    message = if params.key?(OutParams::MESSAGE)
                params[OutParams::MESSAGE]
              elsif params.key?(OutParams::MESSAGE_FILE)
                File.read(params[OutParams::MESSAGE_FILE])
              elsif params.key?(OutParams::STATUS)
                expected_file = File.join(MESSAGE_FILES_PATH, "#{params[OutParams::STATUS]}.md")
                if File.exist?(expected_file)
                  File.read(expected_file)
                else
                  File.read(File.join(MESSAGE_FILES_PATH, "#{UNKNOWN_STATUS}.md"))
                end
              end

    metadata = []

    metadata << metadata_name_value_pair("webhook", webhook)
    metadata << metadata_name_value_pair("dryrun", dryrun)
    metadata << metadata_name_value_pair("message", message)

    { "version" => { "ref" => "none" }, "metadata" => metadata }
  end

  private

  def metadata_name_value_pair(key, value)
    { "name" => key, "value" => value }
  end
end
