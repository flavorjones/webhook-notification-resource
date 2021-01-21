FROM ruby:alpine

COPY README.md LICENSE Rakefile Gemfile Gemfile.lock /work/
COPY resource /work/resource
COPY test /work/test
RUN cd /work && bundle config set --local without development && bundle install

COPY ./resource /opt/resource/
