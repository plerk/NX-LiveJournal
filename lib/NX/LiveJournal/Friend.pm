package NX::LiveJournal::Friend;

use strict;
use warnings;
use NX::LiveJournal::Thingie;
our @ISA = qw/ NX::LiveJournal::Thingie /;

sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless { }, $class;

  my %arg = @_;
  $self->{username} = $arg{username};  # req
  $self->{fullname} = $arg{fullname};  # req
  $self->{bgcolor} = $arg{bgcolor};  # req
  $self->{fgcolor} = $arg{fgcolor};  # req
  $self->{type} = $arg{type};    # opt
  $self->{groupmask} = $arg{groupmask};  # req

  return $self;
}

sub name { username(@_) }
sub username { $_[0]->{username} }
sub fullname { $_[0]->{fullname} }
sub bgcolor { $_[0]->{bgcolor} }
sub fgcolor { $_[0]->{fgcolor} }
sub type { $_[0]->{type} }
sub groupmask { $_[0]->{groupmask} }
sub mask { $_[0]->{groupmask} }

sub toStr { '[friend ' . $_[0]->{username} . ']' }

1;
