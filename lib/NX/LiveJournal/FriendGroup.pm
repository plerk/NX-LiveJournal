package NX::LiveJournal::FriendGroup;

use strict;
use warnings;
use NX::LiveJournal::Thingie;
our @ISA = qw/ NX::LiveJournal::Thingie /;

sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless {}, $class;
  my %arg = @_;
  $self->{public} = $arg{public};
  $self->{name} = $arg{name};
  $self->{id} = $arg{id};
  $self->{sortorder} = $arg{sortorder};
  return $self;
}

sub public { $_[0]->{public} }
sub name { $_[0]->{name} }
sub id { $_[0]->{id} }
sub sortorder { $_[0]->{sortorder} }

sub toStr { 
  my $self = shift;
  my $name = $self->name;
  my $id = $self->id;
  my $mask = $self->mask;
  my $bin = sprintf "%b", $mask;
  "[friendgroup $name ($id $mask $bin)]"; 
}

sub mask
{
  my $self = shift;
  my $id = $self->id;
  2**$id;
}

1;
