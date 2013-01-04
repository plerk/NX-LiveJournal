package NX::LiveJournal::FriendList;

use strict;
use warnings;
use NX::LiveJournal::List;
use NX::LiveJournal::Friend;
our @ISA = qw/ NX::LiveJournal::List /;

sub init
{
  my $self = shift;
  my %arg = @_;
  
  if(defined $arg{response})
  {
    my $friends = $arg{response}->value->{friends};
    my $friendofs = $arg{response}->value->{friendofs};
    if(defined $friends)
    {
      foreach my $f (@{ $friends })
      {
        $self->push(new NX::LiveJournal::Friend(%{ $f }));
      }
    }
    if(defined $friendofs)
    {
      foreach my $f (@{ $friendofs })
      {
        $self->push(new NX::LiveJournal::Friend(%{ $f }));
      }
    }
  }
  
  if(defined $arg{response_list})
  {
    foreach my $f (@{ $arg{response_list} })
    {
      $self->push(new NX::LiveJournal::Friend(%{ $f }));
    }
  }
  
  return $self;
}

sub toStr
{
  my $self = shift;
  my $str = '[friendlist ';
  foreach my $friend (@{ $self })
  {
    $str .= $friend->toStr;
  }
  $str .= ']';
  $str;
}

1;
