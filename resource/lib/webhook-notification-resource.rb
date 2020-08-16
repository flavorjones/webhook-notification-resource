require "net/http"

class WebhookNotificationResource
  VERSION = "0.1.0"

  #
  #  "source" parameter key indicating what message to send
  #
  module MessageSource
    STATUS = "status"
    MESSAGE = "message"
    MESSAGE_FILE = "message_file"
  end

  MESSAGE_FILES_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "messages"))
  UNKNOWN_STATUS = "unknown"

  #
  #  expand environment variables in a string
  #
  module EnvExpander
    ENV_VARIABLES_REGEX = /\$([a-zA-Z_]+[a-zA-Z0-9_]*)|\$\{([a-zA-Z_]+[a-zA-Z0-9_]*)\}/

    def self.expand(message)
      message.gsub(ENV_VARIABLES_REGEX) do
        ENV[$1 || $2] || $&
      end
    end
  end

  #
  #  expand any special Concourse metadata
  #
  module ConcourseEnvExpander
    BUILD_URL_TEMPLATE = "${ATC_EXTERNAL_URL}/teams/${BUILD_TEAM_NAME}/pipelines/${BUILD_PIPELINE_NAME}/jobs/${BUILD_JOB_NAME}/builds/${BUILD_NAME}"

    def self.expand(message)
      ENV["BUILD_URL"] = EnvExpander.expand(BUILD_URL_TEMPLATE)
      EnvExpander.expand(message)
    end
  end

  #
  #  maybe the only real piece of gitter-specific behavior
  #
  module GitterWebhookHandler
    def self.post(url, message)
      Net::HTTP.post_form(URI(url), "message" => message)
    end
  end

  attr_reader :url, :dryrun

  def initialize(source = {})
    @url = source.fetch("url")
    @dryrun = source.fetch("dryrun", false)
  end

  def out(params = {}, env_expander: ConcourseEnvExpander, webhook_handler: GitterWebhookHandler)
    if !params.key?(MessageSource::STATUS) && !params.key?(MessageSource::MESSAGE) && !params.key?(MessageSource::MESSAGE_FILE)
      raise KeyError.new("could not find 'status', 'message', or 'message_file'")
    end

    message = if params.key?(MessageSource::MESSAGE)
        params[MessageSource::MESSAGE]
      elsif params.key?(MessageSource::MESSAGE_FILE)
        File.read(params[MessageSource::MESSAGE_FILE])
      elsif params.key?(MessageSource::STATUS)
        expected_file = File.join(MESSAGE_FILES_PATH, "#{params[MessageSource::STATUS]}.md")
        if File.exist?(expected_file)
          File.read(expected_file)
        else
          File.read(File.join(MESSAGE_FILES_PATH, "#{UNKNOWN_STATUS}.md"))
        end
      end
    message = env_expander.expand(message)

    metadata = []
    metadata << metadata_name_value_pair("version", WebhookNotificationResource::VERSION)
    metadata << metadata_name_value_pair("url", url)
    metadata << metadata_name_value_pair("dryrun", dryrun)
    metadata << metadata_name_value_pair("message", message)

    if !dryrun
      response = webhook_handler.post(url, message)
      metadata << metadata_name_value_pair("response", "#{response.code} #{response.message}")
    end

    { "version" => { "ref" => "none" }, "metadata" => metadata }
  end

  private

  def metadata_name_value_pair(key, value)
    { "name" => key.to_s, "value" => value.to_s }
  end
end
