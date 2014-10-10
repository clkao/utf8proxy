use Plack::Builder;
use Encode qw(encode decode);

# requires listening on 5000 for now.
# Usage:
#     plackup lisproxy.psgi

use Plack::App::Proxy 0.28;
use Plack::Request;
use Plack::Response;
use URI::Escape;

my $PROXY_HOST = $ENV{PROXY_HOST} or die 'Proxy host required';
my $PROXY_CHARSET = $ENV{PROXY_CHARSET} or die 'Proxy charset required';

builder {
  enable sub {
    my $app = shift;
    sub {
      my $env = shift;
      my $req = Plack::Request->new($env);
      warn Dumper($req); use Data::Dumper;
      delete $env->{HTTP_COOKIE};
      $env->{HTTP_REFERER} =~ s!^http://@{[ $env->{HTTP_HOST} ]}/!$PROXY_HOST/!;
      $env->{'psgi.streaming'} = Plack::Util::FALSE;

      if ($req->method eq 'POST') {
        my $transcoded = '';
        # warn Dumper($req->body_parameters); use Data::Dumper;
        $req->body_parameters->each(sub {
            my ($k, $v) = @_;
            $transcoded .= uri_escape( encode($PROXY_CHARSET, decode('utf-8', $k)) );
            $transcoded .= '=';
            $transcoded .= uri_escape( encode($PROXY_CHARSET, decode('utf-8', $v)) );
            $transcoded .= '&';
        });
        open my $t, '<', \$transcoded;
        $env->{CONTENT_LENGTH} = length $transcoded;
        delete $env->{'psgix.input.buffered'};
        $env->{'psgi.input'} = $t;
      }
      my $res = $app->($env);
      my $resp = Plack::Response->new(@$res);
      if ($resp->content_type eq 'text/html') {
        if ($resp->body->[0] =~ s!<META HTTP-EQUIV="?Content-Type"? Content="text/html; charset=$PROXY_CHARSET">!<META HTTP-EQUIV=Content-Type Content="text/html; charset=utf-8">!i) {
          my $body = join('', @{$resp->body});
          Encode::from_to($body, $PROXY_CHARSET, 'utf-8');
          $resp->body($body);
          $resp->content_type('text/html; charset=UTF-8');
          return $resp->finalize;
        }
      }
      return $res;
    };

  };
  enable "BufferedStreaming";

  mount "/" => Plack::App::Proxy->new(
    backend => 'LWP',
    options => { keep_alive => 1 },
    remote => $PROXY_HOST)->to_app;
};
