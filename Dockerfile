FROM alpine
ADD wise-ci-trigger.sh /bin/
RUN apk update && apk add curl jq && rm -rf /var/cache/apk/*
