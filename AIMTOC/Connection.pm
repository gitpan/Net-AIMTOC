package Net::AIMTOC::Connection;

use strict;

use Net::AIMTOC::Config;
use Net::AIMTOC::Utils;
use Net::AIMTOC::Message;

use IO::Socket::INET;

sub new {
	my $class = shift;

	my $self = {
		_sock	=> undef,
		_screenname	=> undef,
		_outseq	=> int(rand(100000)),
	};

	my $sock = IO::Socket::INET->new(
		PeerAddr	=> Net::AIMTOC::Config::TOC_SERVER,
		PeerPort	=> Net::AIMTOC::Config::TOC_PORT,
		Type		=> SOCK_STREAM,
		Proto		=> 'tcp'
	);

	if( !defined($sock) ) {
		my $err_msg = 'Unable to connect to '. Net::AIMTOC::Config::TOC_SERVER .' on port '. Net::AIMTOC::Config::TOC_PORT;
		throw Net::AIMTOC::Error( -text => $err_msg );
	};

	$self->{_sock} = $sock;
	bless $self, $class;

	return( $self );
};


sub send_signon {
	my $self = shift;
	my $screenname = shift;
	my $password = shift;

	$self->{_screenname} = $screenname;

	Net::AIMTOC::Utils::printDebug( "send_signon: $screenname" );

	my $data_out = "FLAPON\r\n\r\n";
	$self->{_sock}->send( $data_out );

	my( $msgObj ) = $self->recvFromAOL;
	Net::AIMTOC::Utils::printDebug( $msgObj->getRawData );

	my $signon_data = pack "Nnna".length($screenname), 1, 1, length($screenname) , $screenname;

	my $msg = pack "aCnn", '*', 1, $self->{_outseq}, length($signon_data);
	$msg .= $signon_data;

	my $ret = $self->{_sock}->send( $msg, 0 );

	if( !defined($ret) ) {
		throw Net::AIMTOC::Error( -text => "syswrite: $!" );
	};

	my $login_string = $self->_getLoginString( $screenname, $password );

	$ret = $self->sendToAOL( $login_string );

	# receive SIGNON data from AOL
	$msgObj = $self->recvFromAOL;
	Net::AIMTOC::Utils::printDebug( $msgObj->getRawData );

	# Sending of sign on data is performed by 'recvFromAOL' to ensure
	# correct handling of PAUSE messages

	return( 1 );
};


sub _sendSignOnData {
	my $self = shift;

	# These lines are required in order to sign on
	my $ret = $self->sendToAOL( "toc_add_buddy $self->{_screenname}" );
	$ret = $self->sendToAOL( 'toc_set_config {m 1}' );

	# We're done with the signon process
	$ret = $self->sendToAOL( 'toc_init_done' );

	# remove the buddy we were required to add earlier
	$ret = $self->sendToAOL( "toc_remove_buddy $self->{_screenname}" );

	return;
};

sub _getLoginString {
	my $self = shift;
	my $screenname = shift;
	my $password = shift;

	my $login_string = 'toc_signon ' . Net::AIMTOC::Config::AUTH_SERVER . ' ' . Net::AIMTOC::Config::AUTH_PORT . ' ' . $screenname . ' ' . Net::AIMTOC::Utils::encodePass( $password ) . ' english ' . Net::AIMTOC::Utils::encode( Net::AIMTOC::Config::AGENT );

	return( $login_string );
};


sub recvFromAOL {
	my $self = shift;
	my $buffer;

	if( !defined($self->{_sock}) ) {
		throw Net::AIMTOC::Error( -text => 'We are not connected' );
	};

	my $ret = $self->{_sock}->recv( $buffer, 6 );
	if( !defined($ret) ) {
		throw Net::AIMTOC::Error( -text => "sysread: $!" );
	};
	Net::AIMTOC::Utils::printDebug( "RAW IN (header): '$buffer'" );

	my ($marker, $type, $in_seq, $len) = unpack "aCnn", $buffer;
	Net::AIMTOC::Utils::printDebug( "IN (header): '$marker', '$type', '$in_seq', '$len'" );

	$ret = $self->{_sock}->recv( $buffer, $len );
	if( !defined($ret) ) {
		throw Net::AIMTOC::Error( -text => "sysread: $!" );
	};
	Net::AIMTOC::Utils::printDebug( "RAW IN (data): '$buffer'" );

	my $data = unpack( 'a*', $buffer );
	Net::AIMTOC::Utils::printDebug( "IN (data): '$data'" );

	my $msgObj = Net::AIMTOC::Message->new( $type, $data );

	if( $msgObj->getType eq 'SIGN_ON' ) {
		$self->_sendSignOnData;
	};

	return( $msgObj );
};


sub sendToAOL {
	my $self = shift;
	my $msg = shift;

	if( !defined($self->{_sock}) ) {
		throw Net::AIMTOC::Error( -text => 'We are not connected' );
	};

	$msg .= "\0";

	Net::AIMTOC::Utils::printDebug( "RAW OUT: $msg" );
	my $data = pack "aCnna*", '*', 2, ++$self->{_outseq}, length($msg), $msg;
	Net::AIMTOC::Utils::printDebug( "OUT: $data" );

	my $ret = $self->{_sock}->send( $data, 0 );

	if( !defined($ret) ) {
		throw Net::AIMTOC::Error( -text => "syswrite: $!" );
	};

	return( $ret );
};


sub sendIMToAOL {
	my $self = shift;
	my $user = shift;
	my $msg = shift;

	if( !defined($user) || !defined($msg) ) {
		Net::AIMTOC::Utils::printDebug( "User or msg not defined\n" );
		return;
	};

	$user = Net::AIMTOC::Utils::normalize( $user );
	$msg = Net::AIMTOC::Utils::encode( $msg );

	$msg = 'toc_send_im '. $user .' '. $msg;

	my $ret = $self->sendToAOL( $msg );

	return( $ret );
};


sub disconnect {
	my $self = shift;

	$self->{_sock}->close;

	return;
};


1;

