FROM moltar/plack:latest

MAINTAINER clkao <clkao@clkao.org>

RUN plenv exec cpanm Plack::App::Proxy

WORKDIR /app

ENTRYPOINT ["/sbin/my_init", "--", "plenv", "exec", "plackup"]

EXPOSE 5000
