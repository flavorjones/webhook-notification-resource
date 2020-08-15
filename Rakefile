begin
  require "concourse"

  Concourse.new("gitter-notification-resource",
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

namespace "docker" do
  DOCKER_TAG = "flavorjones/gitter-notification-resource"

  desc "Build a docker image for the resource" # and for testing the resource
  task "build" => "bundler:package" do
    sh "docker build -t #{DOCKER_TAG} -f Dockerfile ."
  end

  desc "Push the docker image"
  task "push" do
    sh "docker push #{DOCKER_TAG}"
  end

  desc "Run the tests in the docker container"
  task "test" => "docker:build" do
    sh "docker run -it #{DOCKER_TAG} /work/run-tests"
  end
end

namespace "bundler" do
  task "package" do
    sh "bundle package --quiet"
  end
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

task "default" => "docker:test"
