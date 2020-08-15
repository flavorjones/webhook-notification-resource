require "helper"

describe "GitterNotificationResource" do
  def message_from(output)
    output["metadata"].find { |datum| datum["name"] == "message" }["value"]
  end

  describe "#initialize" do
    it "requires a webhook hash key" do
      e = assert_raises(KeyError) { GitterNotificationResource.new }
      assert_match(/webhook/, e.to_s)

      GitterNotificationResource.new("webhook" => "https://webhooks.gitter.im/e/c0ffeec0ffeecafecafe")
    end
  end

  describe "#webhook" do
    it "returns the hash key value passed to the initializer in source hash" do
      resource = GitterNotificationResource.new("webhook" => "https://webhooks.gitter.im/e/c0ffeec0ffeecafecafe")
      assert_equal("https://webhooks.gitter.im/e/c0ffeec0ffeecafecafe", resource.webhook)
    end
  end

  describe "#dryrun" do
    it "defaults to false" do
      resource = GitterNotificationResource.new("webhook" => "https://webhooks.gitter.im/e/c0ffeec0ffeecafecafe")
      refute resource.dryrun
    end

    it "may be set by adding a hash key in the initializer param" do
      resource = GitterNotificationResource.new("webhook" => "https://webhooks.gitter.im/e/c0ffeec0ffeecafecafe",
                                                "dryrun" => true)
      assert resource.dryrun

      resource = GitterNotificationResource.new("webhook" => "https://webhooks.gitter.im/e/c0ffeec0ffeecafecafe",
                                                "dryrun" => false)
      refute resource.dryrun
    end
  end

  describe "#out" do
    let(:resource) do
      GitterNotificationResource.new("webhook" => "https://webhooks.gitter.im/e/c0ffeec0ffeecafecafe",
                                     "dryrun" => true)
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
        assert_includes(output["metadata"], { "name" => "dryrun",
                                              "value" => true })
        assert_includes(output["metadata"], { "name" => "webhook",
                                              "value" => "https://webhooks.gitter.im/e/c0ffeec0ffeecafecafe" })
        assert_includes(output["metadata"], { "name" => "message",
                                              "value" => "this is a markdown message" })
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
      let(:message_file_contents) { File.read(message_file_path) }

      ["success", "failure", "error", "abort"].each do |status|
        describe "and the status is '#{status}'" do
          let(:message_file_path) {
            File.expand_path(File.join(File.basename(__FILE__), "..", "resource", "messages", "#{status}.md"))
          }

          it "returns the '#{status}' message" do
            output = resource.out({ "status" => status })
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
          output = resource.out({ "status" => "not-a-valid-status" })
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

    describe "concourse metadata" do
      after(:each) { ENV.delete("UNIT_TEST_FOOBAR") }

      it "expands env vars in the message" do # thereby expanding concourse metadata which is set as env vars
        ENV["UNIT_TEST_FOOBAR"] = "xxx"

        output = resource.out({ "message" => "foo $UNIT_TEST_FOOBAR $UNIT_TEST_FOOBAR bar" })
        assert_equal "foo xxx xxx bar", message_from(output)
      end

      it "expands env vars within curly braces in the message" do
        ENV["UNIT_TEST_FOOBAR"] = "xxx"

        output = resource.out({ "message" => "foo ${UNIT_TEST_FOOBAR} ${UNIT_TEST_FOOBAR} bar" })
        assert_equal "foo xxx xxx bar", message_from(output)
      end

      it "expands env vars with mixed syntax in the message" do
        ENV["UNIT_TEST_FOOBAR"] = "xxx"

        output = resource.out({ "message" => "foo $UNIT_TEST_FOOBAR ${UNIT_TEST_FOOBAR} bar" })
        assert_equal "foo xxx xxx bar", message_from(output)
      end

      it "does not expand things that are not env vars" do
        output = resource.out({ "message" => "foo ${UNIT_TEST_FOOBAR} bar" })
        assert_equal "foo ${UNIT_TEST_FOOBAR} bar", message_from(output)

        output = resource.out({ "message" => "foo $UNIT_TEST_FOOBAR bar" })
        assert_equal "foo $UNIT_TEST_FOOBAR bar", message_from(output)
      end

      it "expands custom BUILD_URL metadata in the message" do
        ENV["ATC_EXTERNAL_URL"] = "https://ci.example.com"
        ENV["BUILD_TEAM_NAME"] = "team-name"
        ENV["BUILD_PIPELINE_NAME"] = "pipeline-name"
        ENV["BUILD_JOB_NAME"] = "job-name"
        ENV["BUILD_NAME"] = "name"
        output = resource.out({ "message" => "foo $BUILD_URL bar" })
        expected = "foo https://ci.example.com/teams/team-name/pipelines/pipeline-name/jobs/job-name/builds/name bar"
        assert_equal expected, message_from(output)
      end
    end
  end
end
