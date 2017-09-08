FROM alpine

RUN apk update
RUN apk add git openssh-client curl jq

RUN adduser app -D
COPY update-version-wrapper /home/app
RUN chmod +rx /home/app/update-version-wrapper
USER app

CMD /home/app/update-version-wrapper
