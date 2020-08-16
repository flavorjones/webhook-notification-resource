FROM ruby:alpine

COPY README.md LICENSE Rakefile Gemfile Gemfile.lock /work/
COPY resource /work/resource
COPY test /work/test
RUN cd /work && bundle install --with=test --without=development

COPY ./resource /opt/resource/
