FROM ruby:alpine

# install dependencies
COPY . /work
RUN cd /work && bundle install --local

# move scripts and direct dependencies to /opt/resource
COPY ./resource /opt/resource/
