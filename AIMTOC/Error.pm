package Net::AIMTOC::Error;

use strict;

use Error;

@Net::AIMTOC::Error::ISA = qw( Error );



package Net::AIMTOC::Error::Message;

use strict;

use Error;

@Net::AIMTOC::Error::Message::ISA = qw( Net::AIMTOC::Error );

1;
