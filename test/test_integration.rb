require "helper"

require "json"
require "open3"
require "webrick"

describe "/opt/resource/in" do
  it "emits a placeholder ref and exits 0" do
    stdout, stderr, status = Open3.capture3("resource/in", stdin_data: "ignored")
    assert status.success?, "script failed, #{stderr}"
    assert stderr.empty?
    assert_equal({ "version" => { "ref" => "none" } }, JSON.parse(stdout))
  end
end

describe "/opt/resource/check" do
  it "emits an empty array and exits 0" do
    stdout, stderr, status = Open3.capture3("resource/check", stdin_data: "ignored")
    assert status.success?, "script failed, #{stderr}"
    assert stderr.empty?
    assert_equal([], JSON.parse(stdout))
  end
end

describe "/opt/resource/out" do
  it "makes an HTTP POST to the webhook URL with the message payload" do
    # set up a dummy web server
    server = WEBrick::HTTPServer.new(Port: 0) # choose a random port
    port = server.config[:Port]
    request = nil

    server.mount_proc "/c0ffeec0ffeecafecafe" do |req, res|
      request = req.to_s # for later inspection
      res.body = "OK sure"
    end

    thread = Thread.new { server.start }

    # make the `out` call
    input = {
      "source" => {
        "webhook" => "http://localhost:#{port}/c0ffeec0ffeecafecafe",
      },
      "params" => {
        "message" => "this is a message",
      },
    }.to_json
    stdout, stderr, status = Open3.capture3("resource/out", stdin_data: input)

    # shut it down gracefully
    thread.exit

    # check if the out script ran successfully
    assert status.success?, "script failed, #{stderr}"
    assert stderr.empty?

    # make our assertions on the server side
    assert request
    assert_includes(request, "message=this+is+a+message")

    # make our assertions on the client side
    expected_stdout = {
      "version" => { "ref" => "none" },
      "metadata" => [
        { "name" => "version", "value" => GitterNotificationResource::VERSION },
        { "name" => "webhook", "value" => "http://localhost:#{port}/c0ffeec0ffeecafecafe" },
        { "name" => "dryrun", "value" => "false" },
        { "name" => "message", "value" => "this is a message" },
        { "name" => "response", "value" => "200 OK" },
      ],
    }
    assert_equal expected_stdout, JSON.parse(stdout)
  end
end
