FROM ruby:2.6-alpine

RUN apk add \
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
    LICENSE.txt \
    README.md \
    Rakefile \
    sync_images.rb \
    update-version-wrapper \
    ./
# COPY treats directories differently /shrug
COPY \
    spec \
    ./spec
RUN chmod -R +rX * && chmod +x update-version-wrapper
RUN mkdir -p vendor/bundle && bundle install --path vendor/bundle

CMD dockerd & ./update-version-wrapper
