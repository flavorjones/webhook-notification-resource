require "rest-client"

class GitterNotificationResource
  attr_reader :webhook, :dryrun

  def initialize(source = {})
    @webhook = source.fetch("webhook")
    @dryrun = source.fetch("dryrun", false)
  end
end
