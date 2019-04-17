FROM ruby:2.6-alpine

RUN apk add --no-cache \
    curl \
    docker \
    git \
    jq \
    openssh-client
RUN gem install bundler

WORKDIR /home/app
COPY \
    Gemfile \
    Gemfile.lock \
    ./
RUN mkdir -p vendor/bundle && bundle install --path vendor/bundle

COPY \
    LICENSE.txt \
    README.md \
    Rakefile \
    sync_images.rb \
    sync_images_wrapper \
    ./
# COPY treats directories differently /shrug
COPY \
    spec \
    ./spec
RUN chmod -R +rX * && chmod +x sync_images_wrapper

# * When the container restarts, dockerd dies and orphans its pid file. This
# prevents dockerd from starting in the restarted container, so we clean it up.
#
# * Because I have seen a race between removing the pid file and dockerd looking
# for the pid file, wait a moment in between.
#
# * Since we fork to run dockerd and also the real entrypoint script, give
# dockerd a few seconds to start up before potentially trying to use it.
CMD rm -f /var/run/dockerd.pid && sleep 2 && dockerd & sleep 5 && ./sync_images_wrapper
