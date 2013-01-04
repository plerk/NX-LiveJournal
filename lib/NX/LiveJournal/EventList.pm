package NX::LiveJournal::EventList;

use strict;
use warnings;
use NX::LiveJournal::List;
use NX::LiveJournal::Event;
our @ISA = qw/ NX::LiveJournal::List /;

sub init
{
  my $self = shift;
  my %arg = @_;
  
  if(defined $arg{response})
  {
    my $events = $arg{response}->value->{events};
    if(defined $events)
    {
      foreach my $e (@{ $events })
      {
        $self->push(new NX::LiveJournal::Event(client => $arg{client}, %{ $e }));
      }
    }
  }
  
  return $self;
}

sub toStr
{
  my $self = shift;
  my $str = '[eventlist ';
  foreach my $friend (@{ $self })
  {
    $str .= $friend->toStr;
  }
  $str .= ']';
  $str;
}

1;
