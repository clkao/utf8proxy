utf8proxy
=========

Proxy http servers with legecy charsets

## Usage

With docker:

    % docker run --rm -p 5000:5000 -e PROXY_CHARSET=big5 -e PROXY_HOST=http://lis.ly.gov.tw/ -t clkao/utf8proxy


With plack:

    % env PROXY_CHARSET=big5 PROXY_HOST=http://lis.ly.gov.tw/ plackup -p 5000

## License

MIT: http://clkao.mit-license.org/
