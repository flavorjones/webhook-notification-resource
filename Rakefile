begin
  require "concourse"

  Concourse.new("webhook-notification-resource",
                directory: "ci",
                fly_target: "flavorjones",
                format: true,
               ).create_tasks!
rescue LoadError
  warn "#{__FILE__}: skipping concourse config"
end

require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.libs << "resource/lib"
  t.test_files = FileList["test/test*.rb"]
  t.warning = true
  t.verbose = true
  t.options = "--pride"
end

namespace "messages" do
  MESSAGE_TEMPLATE = <<~EOF
    ![__STATUS__](${ATC_EXTERNAL_URL}/public/images/__ICON__) [$BUILD_PIPELINE_NAME/$BUILD_JOB_NAME/$BUILD_NAME](${BUILD_URL}) __STATUS__
  EOF

  CONCOURSE_STATUSES_ICONS = {
    "aborted" => "favicon-aborted.png",
    "errored" => "favicon-errored.png",
    "failed" => "favicon-failed.png",
    "pending" => "favicon-pending.png",
    "started" => "favicon-started.png",
    "succeeded" => "favicon-succeeded.png",
    "unknown" => "favicon.png",
  }

  MESSAGES_DIR = "resource/messages"

  desc "regenerate the standard messages based on the template"
  task "generate" do
    FileUtils.mkdir_p MESSAGES_DIR
    CONCOURSE_STATUSES_ICONS.each do |status, icon|
      message = MESSAGE_TEMPLATE.gsub("__STATUS__", status).gsub("__ICON__", icon)
      message_path = File.join(MESSAGES_DIR, "#{status}.md")
      puts "writing #{message_path} ..."
      File.open(message_path, "w") { |f| f.write message }
    end
  end
end

task "default" => "test"
