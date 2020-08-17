require "helper"

describe "WebhookNotificationResource" do
  def message_from(output)
    output["metadata"].find { |datum| datum["name"] == "message" }["value"]
  end

  describe "#initialize" do
    it "requires a url and a webhook adapter name" do
      assert_raises(KeyError) { WebhookNotificationResource.new }
      assert_raises(KeyError) { WebhookNotificationResource.new({ "url" => "https://example.com/teapot" }) }
      assert_raises(KeyError) { WebhookNotificationResource.new({ "adapter" => "MockTeapotAdapter" }) }

      WebhookNotificationResource.new({ "url" => "https://example.com/teapot",
                                        "adapter" => "MockTeapotAdapter" })
    end
  end

  describe "#url" do
    it "returns the hash key value passed to the initializer in source hash" do
      resource = WebhookNotificationResource.new({ "url" => "https://example.com/teapot",
                                                   "adapter" => "MockTeapotAdapter" })
      assert_equal("https://example.com/teapot", resource.url)
    end
  end

  describe "#adapter" do
    it "raises an exception if we ask for a non-existent adapter" do
      assert_raises(WebhookNotificationResource::AdapterNotFound) do
        WebhookNotificationResource.new({ "url" => "https://example.com/xyzzy",
                                          "adapter" => "does-not-exist" })
      end
    end

    it "returns the class implied by the adapter name" do
      resource = WebhookNotificationResource.new({ "url" => "https://example.com/xyzzy",
                                                   "adapter" => "MockTeapotAdapter" })
      assert_same MockTeapotAdapter, resource.adapter

      resource = WebhookNotificationResource.new({ "url" => "https://example.com/xyzzy",
                                                   "adapter" => "MockTeapotAdapter" })
      assert_same MockTeapotAdapter, resource.adapter

      resource = WebhookNotificationResource.new({ "url" => "https://example.com/gitter",
                                                   "adapter" => "GitterActivityFeedAdapter" })
      assert_same GitterActivityFeedAdapter, resource.adapter
    end
  end

  describe "#dryrun" do
    it "defaults to false" do
      resource = WebhookNotificationResource.new({ "url" => "https://example.com/teapot",
                                                   "adapter" => "MockTeapotAdapter" })
      refute resource.dryrun
    end

    it "may be set by adding a hash key in the initializer param" do
      resource = WebhookNotificationResource.new({ "url" => "https://example.com/teapot",
                                                   "adapter" => "MockTeapotAdapter",
                                                   "dryrun" => true })
      assert resource.dryrun

      resource = WebhookNotificationResource.new({ "url" => "https://example.com/teapot",
                                                   "adapter" => "MockTeapotAdapter",
                                                   "dryrun" => false })
      refute resource.dryrun
    end
  end

  describe "#out" do
    let(:resource_dryrun) { true }

    let(:resource) do
      WebhookNotificationResource.new({ "url" => "https://example.com/teapot",
                                        "adapter" => "MockTeapotAdapter",
                                        "dryrun" => resource_dryrun })
    end

    let(:absolute_message_file_path) { File.expand_path(File.join(File.dirname(__FILE__), "test-message.md")) }
    let(:relative_message_file_path) { "test/test-message.md" } # relative to project root

    it "requires one of 'status', 'message', or 'message_file'" do
      assert_raises(KeyError) { resource.out }
      assert_raises(KeyError) { resource.out({ "irrelevant" => "ignored" }) }

      resource.out({ "status" => "success" })
      resource.out({ "message" => "this is a markdown message" })
      resource.out({ "message_file" => absolute_message_file_path })
    end

    describe "return value is a hash" do
      it "contains a placeholder version" do
        output = resource.out({ "status" => "success" })
        assert_equal({ "ref" => "none" }, output["version"])
      end

      it "contains descriptive metadata for source and params" do
        output = resource.out({ "message" => "this is a markdown message" })
        assert_includes(output["metadata"], { "name" => "adapter",
                                              "value" => "MockTeapotAdapter" })
        assert_includes(output["metadata"], { "name" => "dryrun",
                                              "value" => "true" })
        assert_includes(output["metadata"], { "name" => "url",
                                              "value" => "https://example.com/teapot" })
        assert_includes(output["metadata"], { "name" => "message",
                                              "value" => "this is a markdown message" })
      end

      it "puts version into the metadata" do
        output = resource.out({ "message" => "this is a markdown message" })
        assert_includes(output["metadata"], { "name" => "version",
                                              "value" => WebhookNotificationResource::VERSION })
      end
    end

    describe "when passing 'message'" do
      it "contents are passed through an environment expander" do
        env_expander = Minitest::Mock.new
        env_expander.expect(:expand, "output message", ["input message"])

        output = resource.out({ "message" => "input message" }, env_expander: env_expander)
        assert_equal "output message", message_from(output)

        env_expander.verify
      end
    end

    describe "when passing 'message_file'" do
      describe "and the file exists at that absolute path" do
        it "sets the message to the file contents" do
          output = resource.out({ "message_file" => absolute_message_file_path })
          assert_includes(output["metadata"], { "name" => "message",
                                                "value" => "this is a markdown message from a file\n" })
        end
      end

      describe "and the file exists at that relative path" do
        it "sets the message to the file contents" do
          output = resource.out({ "message_file" => relative_message_file_path })
          assert_includes(output["metadata"], { "name" => "message",
                                                "value" => "this is a markdown message from a file\n" })
        end

        it "contents are passed through an environment expander" do
          env_expander = Minitest::Mock.new
          env_expander.expect(:expand, "output message", ["this is a markdown message from a file\n"])

          output = resource.out({ "message_file" => relative_message_file_path }, env_expander: env_expander)
          assert_equal "output message", message_from(output)

          env_expander.verify
        end
      end

      describe "and the file does not exist" do
        it "raises an exception" do
          assert_raises { resource.out({ "message_file" => "road/to/nowhere" }) }
        end
      end
    end

    describe "when passing 'status'" do
      class NullEnvExpander
        def self.expand(message)
          message
        end
      end

      let(:message_file_contents) { File.read(message_file_path) }

      ["succeeded", "failed", "errored", "aborted"].each do |status|
        describe "and the status is '#{status}'" do
          let(:message_file_path) {
            File.expand_path(File.join(File.basename(__FILE__), "..", "resource", "messages", "#{status}.md"))
          }

          it "returns the '#{status}' message" do
            output = resource.out({ "status" => status }, env_expander: NullEnvExpander)
            assert_equal message_file_contents, message_from(output)
          end

          it "contents are passed through an environment expander" do
            env_expander = Minitest::Mock.new
            env_expander.expect(:expand, "output message", [message_file_contents])

            output = resource.out({ "status" => status }, env_expander: env_expander)
            assert_equal "output message", message_from(output)

            env_expander.verify
          end
        end
      end

      describe "and the status is invalid" do
        let(:message_file_path) do
          File.expand_path(File.join(File.basename(__FILE__), "..", "resource", "messages", "unknown.md"))
        end

        it "returns the 'unknown' message" do
          output = resource.out({ "status" => "not-a-valid-status" }, env_expander: NullEnvExpander)
          assert_equal message_file_contents, message_from(output)
        end

        it "contents are passed through an environment expander" do
          env_expander = Minitest::Mock.new
          env_expander.expect(:expand, "output message", [message_file_contents])

          output = resource.out({ "status" => "not-a-valid-status" }, env_expander: env_expander)
          assert_equal "output message", message_from(output)

          env_expander.verify
        end
      end
    end

    describe "http post" do
      let(:success_response) { Net::HTTPOK.new("1.1", 200, "OK") }
      let(:failure_response) { Net::HTTPNotFound.new("1.1", 404, "this page is not found") }

      describe "when dryrun is true" do
        let(:resource_dryrun) { true }

        it "does not call the webhook handler" do
          webhook_adapter = Minitest::Mock.new
          # we expect no calls will be made

          output = resource.out({ "message" => "markdown message" }, webhook_adapter: webhook_adapter)
          refute output["metadata"].find { |datum| datum["name"] == "response" }

          webhook_adapter.verify
        end
      end

      describe "when dryrun is false" do
        let(:resource_dryrun) { false }

        it "does calls the webhook handler" do
          webhook_adapter = Minitest::Mock.new
          webhook_adapter.expect(:post, success_response, [resource.url, "markdown message"])

          resource.out({ "message" => "markdown message" }, webhook_adapter: webhook_adapter)

          webhook_adapter.verify
        end

        describe "on successful post" do
          it "emits response metadata" do
            webhook_adapter = Minitest::Mock.new
            webhook_adapter.expect(:post, success_response, [resource.url, "markdown message"])

            output = resource.out({ "message" => "markdown message" }, webhook_adapter: webhook_adapter)
            assert_includes(output["metadata"], { "name" => "response",
                                                  "value" => "200 OK" })

            webhook_adapter.verify
          end
        end

        describe "on failure to post" do
          it "emits response metadata" do
            webhook_adapter = Minitest::Mock.new
            webhook_adapter.expect(:post, failure_response, [resource.url, "markdown message"])

            output = resource.out({ "message" => "markdown message" }, webhook_adapter: webhook_adapter)
            assert_includes(output["metadata"], { "name" => "response",
                                                  "value" => "404 this page is not found" })

            webhook_adapter.verify
          end
        end
      end
    end
  end
end

describe "EnvExpander" do
  before { ENV["UNIT_TEST_FOOBAR"] = replacement_text }
  after { ENV.delete("UNIT_TEST_FOOBAR") }

  let(:replacement_text) { "xxx#{rand(1000)}" }

  it "expands env vars in the message" do
    output = WebhookNotificationResource::EnvExpander.expand "foo $UNIT_TEST_FOOBAR $UNIT_TEST_FOOBAR bar"
    assert_equal "foo #{replacement_text} #{replacement_text} bar", output
  end

  it "expands env vars within curly braces in the message" do
    output = WebhookNotificationResource::EnvExpander.expand "foo ${UNIT_TEST_FOOBAR} ${UNIT_TEST_FOOBAR} bar"
    assert_equal "foo #{replacement_text} #{replacement_text} bar", output
  end

  it "expands env vars with mixed syntax in the message" do
    output = WebhookNotificationResource::EnvExpander.expand "foo ${UNIT_TEST_FOOBAR} $UNIT_TEST_FOOBAR bar"
    assert_equal "foo #{replacement_text} #{replacement_text} bar", output
  end

  it "does not expand things that are not env vars" do
    output = WebhookNotificationResource::EnvExpander.expand "foo ${UNIT_TEST_QUUX} bar"
    assert_equal "foo ${UNIT_TEST_QUUX} bar", output

    output = WebhookNotificationResource::EnvExpander.expand "foo $UNIT_TEST_QUUX bar"
    assert_equal "foo $UNIT_TEST_QUUX bar", output
  end

  describe "ConcourseEnvExpander" do
    after do
      ENV.delete("ATC_EXTERNAL_URL")
      ENV.delete("BUILD_TEAM_NAME")
      ENV.delete("BUILD_PIPELINE_NAME")
      ENV.delete("BUILD_JOB_NAME")
      ENV.delete("BUILD_NAME")
    end

    it "dynamically expands custom BUILD_URL metadata in the message" do
      2.times do
        ENV["ATC_EXTERNAL_URL"] = atc_external_url = "https://ci#{rand(1000)}.example.com"
        ENV["BUILD_TEAM_NAME"] = team_name = rand(1000).to_s
        ENV["BUILD_PIPELINE_NAME"] = pipeline_name = rand(1000).to_s
        ENV["BUILD_JOB_NAME"] = job_name = rand(1000).to_s
        ENV["BUILD_NAME"] = name = rand(1000).to_s
        output = WebhookNotificationResource::ConcourseEnvExpander.expand "foo $BUILD_URL bar"
        expected = "foo #{atc_external_url}/teams/#{team_name}/pipelines/#{pipeline_name}/jobs/#{job_name}/builds/#{name} bar"
        assert_equal expected, output
      end
    end

    it "expands env vars with mixed syntax in the message" do
      output = WebhookNotificationResource::ConcourseEnvExpander.expand "foo ${UNIT_TEST_FOOBAR} $UNIT_TEST_FOOBAR bar"
      assert_equal "foo #{replacement_text} #{replacement_text} bar", output
    end
  end

  describe "Util" do
    describe "#filename_for_classname" do
      it "converts a camelcase classname into a snakecase filename" do
        assert_equal "foo_bar_baz", WebhookNotificationResource::Util.filename_for_classname("FooBarBaz")
        assert_equal "foo_bar_baz_2", WebhookNotificationResource::Util.filename_for_classname("FooBarBaz2")
        assert_equal "foo_bar_baz_id", WebhookNotificationResource::Util.filename_for_classname("FooBarBazID")

        # maybe don't do this in your class name, eh?
        assert_equal "foo_idbaz", WebhookNotificationResource::Util.filename_for_classname("FooIDBaz")
      end
    end
  end
end
