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

  # desc "Push the docker image"
  # task "push" do
  #   sh "docker push #{DOCKER_TAG}"
  # end

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

task "default" => "docker:test"
