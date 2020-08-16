#
#  this makefile is intended to aid developer workflow on a docker host,
#  especially if there's no local Ruby development environment.
#  see the README.md for more information.
#
DOCKER_TAG="flavorjones/gitter-notification-resource"

image:
	docker build -t $(DOCKER_TAG) -f Dockerfile .

# run the tests inside the OCI image
test: image
	docker run -it $(DOCKER_TAG) ruby -X /work -S rake test

docker-push:
	docker push $(DOCKER_TAG)

# it's good to double-check what you're shipping
inventory: image
	docker run -it $(DOCKER_TAG) find /opt /work | sort

# sometimes you just need a commandline
sh:
	docker run -it $(DOCKER_TAG) /bin/sh

.PHONY: image test docker-push inventory sh
