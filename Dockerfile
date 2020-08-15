FROM ruby:alpine

COPY . /work
RUN cd /work && bundle install --local
