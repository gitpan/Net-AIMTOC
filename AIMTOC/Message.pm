package Net::AIMTOC::Message;

use strict;

use Net::AIMTOC::Config;
use Net::AIMTOC::Utils;

sub new {
	my $class = shift;
	my $toc_type = shift;
	my $data = shift;

	my $self;

	if( $data =~ /^(ERROR):(\d*)(:(.*))?$/ ) {
		$self = Net::AIMTOC::Message::ERROR->new( $1, $2, $4, $data );
	}
	elsif( $data =~ /^(IM_IN):(\w*):([T|F]):(.*)$/ ) {
		$self = Net::AIMTOC::Message::IM_IN->new( $1, $2, $3, $4, $data );
	}
	elsif( $data =~ /^(UPDATE_BUDDY):(\w*):([T|F]):(\d):(\d+):(\d+):(.*)?$/ ) {
		$self = Net::AIMTOC::Message::UPDATE_BUDDY->new( $1, $2, $3, $4, $5, $6, $7, $data );
	}
	elsif( $data =~ /^(NICK):(.*)$/ ) {
		$self = Net::AIMTOC::Message::GENERIC->new( $1, $2 );
	}
	elsif( $data =~ /^(SIGN_ON):(.*)$/ ) {
		$self = Net::AIMTOC::Message::GENERIC->new( $1, $2 );
	}
	elsif( $data =~ /^(PAUSE):(.*)$/ ) {
		$self = Net::AIMTOC::Message::GENERIC->new( $1, $2 );
	}
	elsif( $data =~ // ) {
		$self = Net::AIMTOC::Message::BLANK_MESSAGE->new( $data );
	}
	else {
		throw Net::AIMTOC::Error( -text => "Invalid message format: $data" );
	};

	$self->{_tocType} = $toc_type;

	return( $self );
};

sub getTocType { return( $_[0]->{_tocType} ) };
sub getType { return( $_[0]->{_type} ) };
sub getMsg { return( $_[0]->{_text} ) };
sub getRawData { return( $_[0]->{_rawData} ) };



package Net::AIMTOC::Message::IM_IN;

use strict;

@Net::AIMTOC::Message::IM_IN::ISA = qw( Net::AIMTOC::Message );

sub new {
	my $class = shift;
	my $type = shift;
	my $sender = shift;
	my $autoresponse = shift;
	my $msg = shift;
	my $data = shift;

	my $self = {
		_type	=> $type,
		_sender	=> $sender,
		_autoResponse	=> $autoresponse,
		_text	=> $msg,
		_rawData	=> $data
	};
	bless $self, $class;

	$self->removeHtmlTags;

	return( $self );
};

sub removeHtmlTags {
	my $self = shift;

	if( Net::AIMTOC::Config::REMOVE_HTML_TAGS ) {
		$self->{_text} = Net::AIMTOC::Utils::removeHtmlTags( $self->{_text} );
	};

	return;
}

sub getMsg {
	my $self = shift;

	my $msg = '';

	if( $self->{_autoResponse} eq 'T' ) {
		$msg .= 'Autoresponse ';
	};

	$msg .= $self->{_sender} .': '. $self->{_text};

	return( $msg );
};

sub isAutoResponse {
	my $self = shift;

	if( $self->{_autoResponse} eq 'T' ) {
		return( 1 );
	};
	
	return;
};

sub getSender { return( $_[0]->{_sender} ) };
sub getText { return( $_[0]->{_text} ) };
sub getAutoResponse { return( $_[0]->{_autoResponse} ) };



package Net::AIMTOC::Message::ERROR;

use strict;

@Net::AIMTOC::Message::ERROR::ISA = qw( Net::AIMTOC::Message );

sub new {
	my $class = shift;
	my $type = shift;
	my $value = shift;
	my $text = shift || '';
	my $data = shift || '';

	my $self = {
		_type	=> $type,
		_value	=> $value,
		_rawData	=> $data,
	};
	bless $self, $class;

	$self->{_text} = $self->_getErrorText( $text );

	unless( $self->isRecoverable ) {
		throw Net::AIMTOC::Error( -text => $self->{_text} );
	};

	return( $self );
};

sub _getErrorText {
	my $self = shift;
	my $text = shift;

	my $raw_err = Net::AIMTOC::Config::EVENT_ERROR_STRING( $self->{_value} );
	my $err_text = sprintf( $raw_err, $text );

	return( $err_text );
};

sub isRecoverable {
	my $self = shift;
	if( $self->{_value} =~ /^98[0-9]/ ) {
		return( 0 );
	}
	return( 1 );
};



package Net::AIMTOC::Message::UPDATE_BUDDY;

use strict;

@Net::AIMTOC::Message::UPDATE_BUDDY::ISA = qw( Net::AIMTOC::Message );

sub new {
	my $class = shift;
	my $type = shift;
	my $buddy = shift;
	my $online = shift;
	my $evil = shift;
	my $signon_time = shift;
	my $idle_time = shift;
	my $user_class = shift;
	my $data = shift;

	my $self = {
		_type		=> $type,
		_buddy		=> $buddy,
		_onlineStatus	=> $online,
		_evilAmount	=> $evil,
		_signonTime	=> $signon_time,
		_idleTime	=> $idle_time,
		_userClass	=> $user_class,
		_rawData	=> $data,
	};
	bless $self, $class;

	return( $self );
};

sub getBuddy { return( $_[0]->{_buddy} ) };
sub getOnlineStatus { return( $_[0]->{_onlineStatus} ) };
sub getEvilAmount { return( $_[0]->{_evilAmount} ) };
sub getSignonTime { return( $_[0]->{_signonTime} ) };
sub getIdleTime { return( $_[0]->{_idleTime} ) };
sub getUserClass { return( $_[0]->{_userClass} ) };

sub getMsg { return( $_[0]->{_rawData} ) };



package Net::AIMTOC::Message::GENERIC;

use strict;

@Net::AIMTOC::Message::GENERIC::ISA = qw( Net::AIMTOC::Message );

sub new {
	my $class = shift;
	my $type = shift;
	my $text = shift;

	my $self = {
		_type	=> $type,
		_text	=> $text,
		_rawData	=> $text,
	};
	bless $self, $class;

	return( $self );
};



# This sometimes comes through (esp. at signon)
package Net::AIMTOC::Message::BLANK_MESSAGE;

use strict;

@Net::AIMTOC::Message::BLANK_MESSAGE::ISA = qw( Net::AIMTOC::Message );

sub new {
	my $class = shift;
	my $text = shift;

	my $self = {
		_type	=> 'BLANK_MESSAGE',
		_text	=> $text,
		_rawData	=> $text,
	};
	bless $self, $class;

	return( $self );
};

sub getType { return( $_[0]->{_type} ) };
sub getMsg { return( $_[0]->{_text} ) };
sub getRawData { return( $_[0]->{_rawData} ) };


1;
