require "minitest/autorun"
require "gitter-notification-resource"

describe "GitterNotificationResource" do
  describe "#initialize" do
    it "requires a webhook hash key" do
      e = assert_raises { GitterNotificationResource.new }
      assert_match(/key not found.*webhook/, e.to_s)

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
end
