require "helper"

describe "GitterNotificationResource" do
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
    let(:resource) {
      GitterNotificationResource.new("webhook" => "https://webhooks.gitter.im/e/c0ffeec0ffeecafecafe",
                                     "dryrun" => true)
    }
    let(:absolute_message_file_path) { File.expand_path(File.join(File.dirname(__FILE__), "test-message.md")) }
    let(:relative_message_file_path) { "test/test-message.md" } # relative to project root

    it "requires one of 'status', 'message', or 'message_file'" do
      assert_raises(KeyError) { resource.out }
      assert_raises(KeyError) { resource.out({}) }

      resource.out("status" => "success")
      resource.out("message" => "this is a markdown message")
      resource.out("message_file" => absolute_message_file_path)
    end

    describe "return value is a hash" do
      it "contains a placeholder version" do
        output = resource.out("status" => "success")
        assert_equal({ "ref" => "none" }, output["version"])
      end

      it "contains descriptive metadata for source and params" do
        output = resource.out("message" => "this is a markdown message")
        assert_includes(output["metadata"], { "name" => "dryrun",
                                              "value" => true })
        assert_includes(output["metadata"], { "name" => "webhook",
                                              "value" => "https://webhooks.gitter.im/e/c0ffeec0ffeecafecafe" })
        assert_includes(output["metadata"], { "name" => "message",
                                              "value" => "this is a markdown message" })
      end
    end

    describe "when passing 'message_file'" do
      describe "and the file exists at that absolute path" do
        it "sets the message to the file contents" do
          output = resource.out("message_file" => absolute_message_file_path)
          assert_includes(output["metadata"], { "name" => "message",
                                                "value" => "this is a markdown message from a file\n" })
        end
      end

      describe "and the file exists at that relative path" do
        it "sets the message to the file contents" do
          output = resource.out("message_file" => relative_message_file_path)
          assert_includes(output["metadata"], { "name" => "message",
                                                "value" => "this is a markdown message from a file\n" })
        end
      end

      describe "and the file does not exist" do
        it "raises an exception" do
          assert_raises { resource.out("message_file" => "road/to/nowhere") }
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
            output = resource.out("status" => status)
            actual = output["metadata"].find { |datum| datum["name"] == "message" }
            assert_equal message_file_contents, actual["value"]
          end
        end
      end

      describe "and the status is invalid" do
        let(:message_file_path) {
          File.expand_path(File.join(File.basename(__FILE__), "..", "resource", "messages", "unknown.md"))
        }
        it "returns the 'unknown' message" do
          output = resource.out("status" => "not-a-valid-status")
          actual = output["metadata"].find { |datum| datum["name"] == "message" }
          assert_equal message_file_contents, actual["value"]
        end
      end
    end

    describe "concourse metadata" do
      # see https://gist.github.com/steakknife/4606598 for some ideas
      it "expands standard concourse metadata in the message"
      it "expands custom BUILD_URL metadata in the message"
    end
  end
end
