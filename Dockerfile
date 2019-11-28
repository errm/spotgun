FROM alpine:3.10

WORKDIR /app

RUN apk add --no-cache ruby-bundler

ENV BUNDLE_SILENCE_ROOT_WARNING=true
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .

RUN rspec

FROM alpine:3.10

WORKDIR /app

ENV KUBERNETES_VERSION=1.16.3

RUN apk add --no-cache ca-certificates ruby && \
    apk add --no-cache -t build-deps curl && \
    curl -L https://storage.googleapis.com/kubernetes-release/release/v$KUBERNETES_VERSION/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    apk del --purge build-deps

COPY lib lib
COPY bin bin

CMD ["bin/spotgun"]
