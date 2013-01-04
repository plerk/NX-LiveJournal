package NX::LiveJournal::Latest::Item;

use strict;
use warnings;

sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless {@_}, $class;
  return $self;
}

sub about { $_[0]->{about} }
sub category { $_[0]->{category} }
sub creator { $_[0]->{'dc:creator'} }
sub date { $_[0]->{'dc:date'} }
sub publisher { $_[0]->{'dc:publisher'} }
sub dctitle { $_[0]->{'dc:title'} }
sub description { $_[0]->{description} }
sub link { $_[0]->{link} }
sub location { $_[0]->{'lj:location'} }
sub mood { $_[0]->{'lj:mood'} }
sub music { $_[0]->{'lj:music'} }
sub pickeyword { $_[0]->{'lj:pickeyword'} }
sub title { $_[0]->{title} }
sub username { $_[0]->{username} }

#about = 112
#category = 17
#dc:creator = 112
#dc:date = 112
#dc:publisher = 2
#dc:title = 70
#description = 112
#link = 112
#lj:location = 15
#lj:mood = 39
#lj:music = 27
#lj:pickeyword = 17
#title = 112
#username = 112

1;
