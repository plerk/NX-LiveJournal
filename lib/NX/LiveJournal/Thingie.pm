package NX::LiveJournal::Thingie;

use strict;
use warnings;
use overload '""' => sub { $_[0]->toStr };

sub setclient { $_[0]->{client} = $_[1] }
sub client { $_[0]->{client} }

1;
