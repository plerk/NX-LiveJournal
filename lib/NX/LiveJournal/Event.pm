package NX::LiveJournal::Event;

use strict;
use warnings;
use RPC::XML;
use NX::LiveJournal::Thingie;
our @ISA = qw/ NX::LiveJournal::Thingie /;

sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless {}, $class;
  my %arg = @_;
  
  $self->{props} = $arg{props} || {};
  $self->{itemid} = $arg{itemid} if defined $arg{itemid};
  $self->{subject} = $arg{subject} || '';
  $self->{url} = $arg{url} if defined $arg{url};
  $self->{anum} = $arg{anum} if defined $arg{anum};
  $self->{event} = $arg{event} || ' ';
  $self->eventtime($arg{eventtime}) if defined $arg{eventtime};
  $self->{security} = $arg{security} || 'public';
  $self->{allowmask} = $arg{allowmask} if defined $arg{allowmask};
  $self->{usejournal} = $arg{usejournal} if defined $arg{usejournal};
  $self->{client} = $arg{client};

  $self->{year} = $arg{year} if defined $arg{year}; 
  $self->{month} = $arg{month} if defined $arg{month}; 
  $self->{day} = $arg{day} if defined $arg{day}; 
  $self->{hour} = $arg{hour} if defined $arg{hour}; 
  $self->{min} = $arg{min} if defined $arg{min}; 

  return $self;
}

# itemid (req)    # (int)
# event (req)    # (string) set to empty to delete
# lineendings (req)  # (string) "unix"
# subject (req)    # (string)
# security (opt)  # (string) public|private|usemask (defaults to public)
# allowmask (opt)  # (int)
# year (req)    # (4-digit int)
# mon (req)    # (1- or 2-digit month int)
# day (req)    # (1- or 2-digit day int)
# hour (req)    # (1- or 2-digit hour int 0..23)
# min (req)    # (1- or 2-digit day int 0..60)
# props (req)    # (struct)
# usejournal (opt)  # (string)
# 

sub _prep
{
  my $self = shift;
  my @list;
  push @list,
    event => new RPC::XML::string($self->event),
    subject => new RPC::XML::string($self->subject),
    security => new RPC::XML::string($self->security),
    lineendings => $NX::LiveJournal::Client::lineendings_unix,

    year  => new RPC::XML::int($self->year),
    mon  => new RPC::XML::int($self->month),
    day  => new RPC::XML::int($self->day),
    hour  => new RPC::XML::int($self->hour),
    min  => new RPC::XML::int($self->min),    
  ;
  push @list, allowmask => new RPC::XML::int($self->allowmask) if $self->security eq 'usemask';
  push @list, usejournal => new RPC::XML::string($self->usejournal) if defined $self->usejournal;
  
  my @props;
  foreach my $key (keys %{ $self->{props} })
  {
    push @props, $key => new RPC::XML::string($self->{props}->{$key});
  }
  push @list, props => new RPC::XML::struct(@props);
  
  @list;
}

sub _prep_flat
{
  my $self = shift;
  my @list;
  push @list,
    event => $self->event,
    subject => $self->subject,
    security => $self->security,
    lineendings => 'unix',
    year => $self->year,
    mon => $self->month,
    day => $self->day,
    hour => $self->hour,
    min => $self->min,
  ;
  push @list, allowmask => $self->allowmask if $self->security eq 'usemask';
  push @list, usejournal => $self->usejournal if defined $self->usejournal;
  foreach my $key (keys %{ $self->{props} })
  {
    push @list, "prop_$key" => $self->{props}->{$key};
  }
  
  @list;
}

sub editevent
{
  my $self = shift;
  my $client = $self->client;

  if(1)
  {
    my @list = _prep_flat($self, @_);
    push @list, itemid => $self->itemid;
    my $response = $client->send_flat_request('editevent', @list);
    if(defined $response)
    { return 1 }
    else
    { return undef }
  }
  else
  {
    my @list = _prep($self, @_);
    push @list, itemid => new RPC::XML::int($self->itemid);

    my $response = $client->send_request('editevent', @list);
    if(defined $response)
    { return 1 }
    else
    { return undef }
  }
}

sub postevent
{
  my $self = shift;
  my $client = $self->client;
  
  my $h;
  if(1)
  {
    my @list = _prep_flat($self, @_);
    $h = $client->send_flat_request('postevent', @list);
    return undef unless defined $h;
  }
  else
  {
    my @list = _prep($self, @_);
    my $response = $client->send_request('postevent', @list);
    return undef unless defined $response;
    $h = $response->value;
  }

  $self->{itemid} = $h->{itemid};
  $self->{url} = $h->{url};
  $self->{anum} = $h->{anum};
  return 1;
}

sub update
{
  my $self = shift;
  if(defined $self->itemid)
  {
    return $self->editevent;
  }
  else
  {
    return $self->postevent;
  }
}

sub toStr
{
  my $self = shift;
  my $subject = $self->subject;
  $subject = 'untitled' if !defined $subject || $subject eq '';
  "[event $subject]";
}

sub subject
{
  my $self = shift;
  my $value = shift;
  $self->{subject} = $value if defined $value;
  $self->{subject};
}

sub event
{
  my $self = shift;
  my $value = shift;
  $self->{event} = $value if defined $value;
  $self->{event};
}

sub year
{
  my $self = shift;
  my $value = shift;
  $self->{year} = $value if defined $value;
  $self->{year};
}

sub month
{
  my $self = shift;
  my $value = shift;
  $self->{month} = $value if defined $value;
  $self->{month};
}

sub day
{
  my $self = shift;
  my $value = shift;
  $self->{day} = $value if defined $value;
  $self->{day};
}

sub hour
{
  my $self = shift;
  my $value = shift;
  $self->{hour} = $value if defined $value;
  $self->{hour};
}

sub min
{
  my $self = shift;
  my $value = shift;
  $self->{min} = $value if defined $value;
  $self->{min};
}

sub eventtime
{
  my $self = shift;
  my $value = shift;
  if(defined $value)
  {
    if($value =~ m/^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/)
    {
      $self->{year} = $1;
      $self->{month} = $2;
      $self->{day} = $3;
      $self->{hour} = $4;
      $self->{min} = $5;
    }
    elsif($value eq 'now')
    {
      my($sec,$min,$hour,$mday,$month,$year,$wday,$yday,$isdst) = localtime(time);
      $self->{year} = $year+1900;
      $self->{month} = $month+1;
      $self->{day} = $mday;
      $self->{hour} = $hour;
      $self->{min} = $min;
    }
  }
  sprintf("%04d-%02d-%02d %02d:%02d:%02d", $self->year, $self->month, $self->day, $self->hour, $self->min);
}

sub security
{
  my $self = shift;
  my $value = shift;
  if(defined $value)
  {
    if($value eq 'friends')
    {
      $self->{security} = 'usemask';
      $self->{allowmask} = 1;
    }
    else
    {
      $self->{security} = $value;
    }
  }
  $self->{security};
}

sub allowmask
{
  my $self = shift;
  my $value = shift;
  $self->{allowmask} = $value if defined $value;
  $self->{allowmask};
}

sub props { $_[0]->{props} }

sub getprop { $_[0]->{props}->{$_[1]} }
sub setprop { $_[0]->{props}->{$_[1]} = $_[2] }
sub itemid { $_[0]->{itemid} }
sub url { $_[0]->{url} }
sub anum { $_[0]->{anum} }
sub usejournal { $_[0]->{usejournal} }

sub gettags
{
  my $self = shift;
  if(defined $self->{props}->{taglist})
  {
    return split /, /, $self->{props}->{taglist};
  }
  else
  {
    return ();
  }
}

sub settags
{
  my $self = shift;
  my $tags = join ', ', @_;
  $self->{props}->{taglist} = $tags;
}


sub htmlid
{
  my $self = shift;
  my $url = $self->url;
  if($url =~ m!/(\d+)\.html$!)
  {
    return $1;
  }
  else
  {
    return undef;
  }
}

sub name { itemid(@_) }

sub access
{
  my $self = shift;
  my $type = shift;
  if(defined $type)
  {
    if($type =~ /^(?:public|private)$/)
    {
      $self->security($type);
    }
    elsif($type eq 'groups')
    {
      my $mask = 0;
      foreach my $group (@_)
      {
        $mask |= $group->mask;
      }
      $self->security('usemask');
      $self->allowmask($mask);
    }
    elsif($type eq 'friends')
    {
      $self->security('usemask');
      $self->allowmask(1);
    }
    return ($type, @_);
  }
  else
  {
    my $security = $self->security;
    return $security if $security =~ /^(?:public|private)$/;
    my $allowmask = $self->allowmask;
    return 'friends' if $allowmask == 1;
    my $groups = $self->client->getfriendgroups;
    my @list;
    foreach my $group (@{ $groups })
    {
      my $mask = $group->mask;
      no warnings;
      push @list, $group if $mask & $allowmask == $mask;
    }
    return ('grops', @list);
    
  }
}

sub picture
{
  my $self = shift;
  my $value = shift;
  if(defined $value)
  {
    $self->{props}->{picture_keyword} = $value;
  }
  $self->{props}->{picture_keyword};
}

1;
