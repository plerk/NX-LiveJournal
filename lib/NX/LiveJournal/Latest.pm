package NX::LiveJournal::Latest;

use strict;
use warnings;
use NX;
use NX::LiveJournal::Latest::Item;
use XML::XPath;
use base 'NX::CacheRobot';

my $cache_dir = "/web/var/cache/lj";

sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my %arg = @_;
  my $server = $arg{server} || 'www.livejournal.com';
  my $self = bless {
    server => $server,
    ua => NX::getRobotAgent(),
  }, $class;
  
  mkdir "$cache_dir/$server", 0755 unless -d "/wev/var/cache/lj/$server";
  
  my $xml = $self->grab_cache(
    fn => "$cache_dir/$server/latest.xml",
    max_age => 15,
    url => "http://$server/stats/latest-rss.bml",
  );
  
  my $xp = new XML::XPath(xml => $xml);
  $self->{xp} = $xp;
  
  return $self;
}

sub items
{
  my $self = shift;
  my $xp = $self->xp;
  my @items;
  my $nodeset = $xp->find('/rdf:RDF/item');
  foreach my $node ($nodeset->get_nodelist)
  {
    my $about = $node->getAttribute('rdf:about');
    my $username = (split /:/, $about)[3];
    my %h;
    foreach my $child ($node->getChildNodes)
    {
      next unless ref($child) eq 'XML::XPath::Node::Element';
      $h{$child->getName} = $child->string_value;
    }
    #print "$about\n", '=' x length $about, "\n";
    #print "username = $username\n";
    #foreach my $key (keys %h)
    #{ print "$key = [\n$h{$key}]\n\n" }
    my $item = new NX::LiveJournal::Latest::Item(%h, about => $about, username => $username);
    push @items, $item;
  }
  return @items;
}

sub server { $_[0]->{server} }
sub xp { $_[0]->{xp} }
sub ua { $_[0]->{ua} }

1;
