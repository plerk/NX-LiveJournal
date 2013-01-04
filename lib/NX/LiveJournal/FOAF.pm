package NX::LiveJournal::FOAF;

use strict;
use warnings;
use NX;

use XML::XPath;
use base qw/ NX::CacheRobot/;
use overload '""' => \&toStr;
use CGI::Lite qw/ url_decode /;
use Encode qw/ decode_utf8 /;


my $cache_dir = "/web/var/cache/lj";

sub new
{
  my $ob = shift;
  my $class = ref($ob)||$ob;
  my %arg = @_;
  my $server = $arg{server} || 'www.livejournal.com';
  
  my $user;
  if($arg{user} =~ /^([A-Za-z0-9_]*)$/)
  { $user = $1 }
  else
  { return undef }
  my $self = bless {
    server => $server,
    ua => NX::getRobotAgent(),
    user => $user,
  }, $class;
  
  mkdir "$cache_dir/$server", 0755 unless -d "/wev/var/cache/lj/$server";
  foreach my $subdir (qw/ foaf /)
  { mkdir "$cache_dir/$server/$subdir", 0755 }

  my $xml = $self->grab_cache(
    fn => "$cache_dir/$server/foaf/$user.xml",
    max_age => 90,
    url => "http://$server/users/$user/data/foaf",
  );
  
  my $xp = new XML::XPath(xml => $xml);
  $self->{xp} = $xp;

  foreach my $key (qw/ foaf:nick foaf:name foaf:dateOfBirth /)
  {
    $self->{$key} = $xp->getNodeText("/rdf:RDF/foaf:Person/$key");
  }
  
  my $node = ($xp->find('/rdf:RDF/foaf:Person/ya:country')->get_nodelist)[0];
  $self->{country} = $node->getAttribute('dc:title') if defined $node;
  $node = ($xp->find('/rdf:RDF/foaf:Person/ya:city')->get_nodelist)[0];
  $self->{city} = decode_utf8(url_decode($node->getAttribute('dc:title'))) if defined $node;
  $self->{city} =~ s/\+/ /g;
  
  return $self;
}

sub server { $_[0]->{server} }
sub nick { $_[0]->{"foaf:nick"} }
sub name { $_[0]->{"foaf:name"} }
sub dateOfBirth { $_[0]->{"foaf:dateOfBirth"} }
sub country { $_[0]->{country} }
sub city { $_[0]->{city} }
sub xp { $_[0]->{xp} }
sub id { $_[0]->{id} }

sub location
{
  my $self = shift;
  return $self->{location} if defined $self->{location};
  
  require NX::Geo::City;
        require NX::Location;
        require  NX::Location::Country;

  my $geocity = new NX::Geo::City(
    city => $self->city,
    country => $self->country,
  );
  if(defined $geocity)
  {
    my $name = sprintf("%s, %s", $geocity->name, $geocity->countryCode);
    my $location = NX::Location::find(
      where => 'l.name = ? AND t.name = ?',
      arg => [ $name, 'lj city' ],
    );
    unless(defined $location)
    {
      $location = new NX::Location(
        type => 'lj city',
        name => $name,
        lat => $geocity->lat,
        lon => $geocity->lng,
        elevation => $geocity->elevation,
      );
      $location->save;
    }
    if(defined $location)
    { 
      print "found $name\n";
      return $self->{location} = $location 
    }
    else
    { return undef }
  }
  return undef;
}

sub knows
{
  my $self = shift;
  my @list;
  my $nodeset = $self->xp->find('/rdf:RDF/foaf:Person/foaf:knows/foaf:Person/foaf:nick');
  foreach my $node ($nodeset->get_nodelist)
  { push @list, $node->string_value }
  return @list;
}

sub toStr
{
  my $self = shift;
  return sprintf("[lj_foaf %s (%s) %s, %s]", $self->name, $self->nick, $self->city, $self->country);
}

sub save
{
  my $self = shift;
  my $dbh = NX::ConnectDB();
  my $sth = $dbh->prepare("SELECT id FROM livejournal_servers WHERE name = ?");
  my $server = $self->server;
  $sth->execute($server);
  my $h = $sth->fetchrow_hashref;
  die "no such lj server defined $server" unless defined $h;
  my $server_id = $h->{id};

  my $id = $self->{id};
  unless(defined $id)
  {
    #print "looking for id...\n";
    $sth = $dbh->prepare("SELECT id FROM livejournal_users WHERE nick = ?");
    #print "nick = ", $self->nick, "\n";
    $sth->execute($self->nick);
    $h = $sth->fetchrow_hashref;
    $id = $h->{id} if defined $h;
  }
  #print "id = $id\n";

  my $country = $self->{country_obj} || load NX::Location::Country(code => $self->{country});
  my $country_id = $country->id if defined $country;
  
  my $location = $self->location;
  #print "location = $location\n";
  my $location_id = $location->id if defined $location;
  
  if(defined $id)
  {
    #print "update\n";
    $sth = $dbh->prepare(qq/
      UPDATE
        livejournal_users
      SET
        nick = ?,
        name = ?,
        dob = ?,
        country_id = ?,
        location_id =?,
        livejournal_server_id = ?
      WHERE
        id = ?
    /);
    $sth->execute($self->nick, $self->name, $self->dateOfBirth, 
      $country_id, ## country_id
      $location_id, ## location_id
      $server_id, $id);
  }
  else
  {
    #print "insert\n";
    $sth = $dbh->prepare(qq/
      INSERT INTO
        livejournal_users
      (nick, name, dob, country_id, location_id, livejournal_server_id)
      VALUES (?,?,?,?,?,?)
    /);
    $sth->execute($self->nick, $self->name, $self->dateOfBirth, 
      $country_id, ## country_id
      $location_id, ## location_id
      $server_id);
    
    $sth = $dbh->prepare("SELECT id FROM livejournal_users WHERE nick = ?");
    $sth->execute($self->nick);
    my $h = $sth->fetchrow_hashref;
    $id = $h->{id} if defined $h;
  }
  $self->{id} = $id;
}

sub save_friends
{
  my $self = shift;
  my $dbh = NX::ConnectDB();
  $dbh->begin_work;
  
  die "save user before trying to save friends" unless defined $self->id;
  
  my $sth = $dbh->prepare("DELETE FROM livejournal_friends WHERE livejournal_user_id = ?");
  $sth->execute($self->id);
  
  foreach my $friendid ($self->knows)
  {
    my $friend = new NX::LiveJournal::FOAF(
      server => $self->server,
      user => $friendid,
    );
    $friend->save;
    $sth = $dbh->prepare("INSERT INTO livejournal_friends (livejournal_user_id, other_user_id) VALUES (?,?)");
    $sth->execute($self->id, $friend->id);
  }
  $sth = $dbh->prepare("UPDATE livejournal_users SET friends_loaded = true WHERE id = ?");
  $sth->execute($self->id);
  $dbh->commit;
}

sub ua { $_[0]->{ua} }

1;
