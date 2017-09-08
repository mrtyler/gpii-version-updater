FROM alpine

RUN apk update
RUN apk add git openssh-client curl jq

RUN adduser app -D
WORKDIR /home/app
COPY components.conf update-version update-version-wrapper ./
RUN chmod +r components.conf
RUN chmod +rx update-version update-version-wrapper
USER app

CMD ./update-version-wrapper
