# Checklist for cutting a release

- [ ] Update `CHANGELOG.md`
- [ ] Update `README.md` if necessary
- [ ] Bump version in `resource/lib/webhook-notification-resource.rb`
- [ ] Commit and push.
- [ ] Create a git tag and push it
- [ ] `make image` to create a docker image
- [ ] Tag the docker image, e.g. `docker tag flavorjones/webhook-notification-resource:latest flavorjones/webhook-notification-resource:v1.1.0`
- [ ] `make docker-push`
- [ ] Copy README to [dockerhub overview](https://cloud.docker.com/repository/docker/flavorjones/webhook-notification-resource/general)
- [ ] Create a [github release](https://github.com/flavorjones/webhook-notification-resource/releases) with CHANGELOG snippet as description
- [ ] Check that the resource works by kicking off the [`standard-messages` job](https://ci.nokogiri.org/teams/flavorjones/pipelines/webhook-notification-resource/jobs/standard-messages)
