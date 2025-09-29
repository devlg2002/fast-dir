FROM elixir:1.15-alpine AS builder

RUN apk add --no-cache build-base git curl

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get --only prod
RUN mix deps.compile

COPY lib lib
COPY README.md .

RUN mix escript.build

FROM alpine:3.18

RUN apk add --no-cache ncurses-libs openssl curl

WORKDIR /app

COPY --from=builder /app/fastdir ./

RUN mkdir -p /wordlists /output /tmp

RUN curl -s -o /wordlists/common.txt \
    https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt

RUN chmod +x /app/fastdir

RUN adduser -D -s /bin/sh fastdir
USER fastdir

ENTRYPOINT ["/app/fastdir"]
CMD ["--help"]
