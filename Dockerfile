#
#  bundle install gems (which should be in ./vendor, see Rakefile)
#
FROM ruby:alpine AS bundler
RUN apk update
RUN apk add build-base

COPY . /work
RUN cd /work && bundle install --local

#
#  run tests
#  discard the build-base compiler toolchain to have a smaller image
#
FROM ruby:alpine AS test
COPY --from=bundler /work /work/
COPY --from=bundler /usr/local/bundle /usr/local/bundle/
RUN cd /work && bundle check && bundle exec rake test
