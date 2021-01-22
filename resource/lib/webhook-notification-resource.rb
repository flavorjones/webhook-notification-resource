require "net/http"

class WebhookNotificationResource
  VERSION = "1.1.0"

  # used to indicate that user has asked for a non-existent adapter
  class AdapterNotFound < StandardError; end

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
  #  some utility methods
  #
  module Util
    def self.filename_for_classname(classname)
      classname.gsub(/([a-z])([A-Z0-9])/) { |m| "#{m[0]}_#{m[1]}" }.downcase
    end

    def self.metadata_name_value_pair(key, value)
      { "name" => key.to_s, "value" => value.to_s }
    end
  end

  attr_reader :url, :dryrun, :adapter

  def initialize(source = {})
    @url = source.fetch("url")
    @dryrun = source.fetch("dryrun", false)
    @adapter = adapter_for(source.fetch("adapter"))
  end

  def adapter_for(adapter_class_name)
    filename = Util.filename_for_classname(adapter_class_name)
    relative_path = File.join("adapters", "#{filename}.rb")

    if !File.exist?(File.expand_path(File.join(File.dirname(__FILE__), relative_path)))
      raise AdapterNotFound.new("could not find an adapter for '#{adapter_class_name}' (at '#{relative_path}')")
    end

    require_relative relative_path

    Object.const_get(adapter_class_name)
  end

  def out(params = {}, env_expander: ConcourseEnvExpander, webhook_adapter: @adapter)
    if !params.key?(MessageSource::STATUS) && !params.key?(MessageSource::MESSAGE) && !params.key?(MessageSource::MESSAGE_FILE)
      raise KeyError.new("could not find 'status', 'message', or 'message_file'")
    end

    message = if params.key?(MessageSource::MESSAGE)
        params[MessageSource::MESSAGE]
      elsif params.key?(MessageSource::MESSAGE_FILE)
        File.read(params[MessageSource::MESSAGE_FILE])
      elsif params.key?(MessageSource::STATUS)
        if adapter.respond_to?(:status_message_for)
          adapter.status_message_for(params[MessageSource::STATUS])
        else
          expected_file = File.join(MESSAGE_FILES_PATH, "#{params[MessageSource::STATUS]}.md")
          if File.exist?(expected_file)
            File.read(expected_file)
          else
            File.read(File.join(MESSAGE_FILES_PATH, "#{UNKNOWN_STATUS}.md"))
          end
        end
      end
    message = env_expander.expand(message)

    metadata = []
    metadata << Util.metadata_name_value_pair("version", WebhookNotificationResource::VERSION)
    metadata << Util.metadata_name_value_pair("adapter", adapter.name)
    metadata << Util.metadata_name_value_pair("dryrun", dryrun)
    metadata << Util.metadata_name_value_pair("message", message)

    if !dryrun
      response = webhook_adapter.post(url, message)
      metadata << Util.metadata_name_value_pair("response", "#{response.code} #{response.message}")
    end

    { "version" => { "ref" => "none" }, "metadata" => metadata }
  end
end
