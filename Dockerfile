FROM ruby:alpine

# install dependencies
COPY . /work
RUN cd /work && bundle install --local --with=test --without=development
RUN rm -rf /work/vendor

# move scripts and direct dependencies to /opt/resource
COPY ./resource /opt/resource/
