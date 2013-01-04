package NX::LiveJournal::List;

use strict;
use warnings;
use overload '""' => sub { $_[0]->toStr }, '@{}' => sub { $_[0]->{list} };

sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless { list => [] }, $class;
  my %arg = @_;
  $self->{list} = $arg{list} if defined $arg{list};
  $self->init(@_);

  foreach my $member (@{ $self })
  {
    $member->setclient($arg{client});
  }

  return $self;
}

sub push
{
  my $self = shift;
  push @{ $self }, @_;
}

sub find
{
  my $self = shift;
  my $key = shift;
  foreach my $element (@{ $self })
  {
    return $element if $element->name eq $key;
  }
  return undef;
}

1;
