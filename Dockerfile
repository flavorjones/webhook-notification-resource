FROM ruby:alpine

COPY . /work
RUN cd /work && bundle install --local
RUN cd /work && bundle exec rake test
