use Test::More tests => 5;
use Config::YAML;

my $c = Config::YAML->new(config => 't/test.yaml');
ok($c->{clobber} == 1, "This should always work if the previous tests did");
ok($c->get('clobber') == 1, "OO value retreival works");
$c->set('clobber',5);
ok($c->get('clobber') == 5, "OO value specification works");

my $media = $c->get('media');
ok($media->[1] eq "ogg", "get()ting data structures works");

my @newmedia = qw(oil stucco acrylics latex);
$c->set('media',\@newmedia);
ok($c->{media}[1] eq "stucco", "set()ting data structures works");
