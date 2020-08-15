require "helper"
require "json"
require "open3"

describe "resource scripts" do
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
    it "does some things"
  end
end
