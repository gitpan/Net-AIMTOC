package Net::AIMTOC;

$VERSION = '0.9';

use strict;

use Net::AIMTOC::Connection;
use Net::AIMTOC::Error;

sub new {
	my $class = shift;

	my $self = {
		_conn => undef,
	};
	bless $self, $class;

	return( $self );
};

sub connect {
	my $self = shift;

	my $conn = Net::AIMTOC::Connection->new;

	$self->{_conn} = $conn;

	return( 1 );
};

sub sign_on {
	my $self = shift;
	my $screenname = shift;
	my $password = shift;

	if( !defined($screenname) || !defined($password) ) {
		throw Net::AIMTOC::Error( -text => 'Username/password not defined' );
	};

	my $ret = $self->{_conn}->send_signon( $screenname, $password );

	return( $ret );
};

sub disconnect {
	my $self = shift;

	$self->{_conn}->disconnect;

	return( 1 );
};

sub send_to_aol {
	my $self = shift;
	my $msg = shift;

	my $ret = $self->{_conn}->sendToAOL( $msg );

	return( $ret );
};

sub send_im_to_aol {
	my $self = shift;
	my $user = shift;
	my $msg = shift;

	my $ret = $self->{_conn}->sendIMToAOL( $user, $msg );

	return( $ret );
};

sub recv_from_aol {
	my $self = shift;

	my( $msgObj ) = $self->{_conn}->recvFromAOL;

	return( $msgObj );
};

1;

=pod

=head1 TITLE

Net::AIMTOC - Perl implementation of the AIM TOC procotol

    
=head1 DESCRIPTION

This is a work in progress, updates to documentation will follow.

=head1 KNOWN BUGS

None, but that does not mean there are not any.

=head1 AUTHOR

Alistair Francis, <cpan@alizta.com>

=cut

