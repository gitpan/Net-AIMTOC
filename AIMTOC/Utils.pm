package Net::AIMTOC::Utils;

use strict;

use Net::AIMTOC::Config;

sub printDebug {
	my $msg = shift;

	if( Net::AIMTOC::Config::DEBUG ) {
		print STDERR $msg, "\n";
	};

	return;
};

sub encodePass {
	my $password = shift;

	my @table = unpack "c*" , 'Tic/Toc';
	my @pass = unpack "c*", $password;

	my $encpass = '0x';
	foreach my $c (0 .. $#pass) {
		$encpass.= sprintf "%02x", $pass[$c] ^ $table[ ( $c % 7) ];
	};

	return( $encpass );
};

sub encode {
	my $str = shift;

	$str =~ s/([\\\}\{\(\)\[\]\$\"])/\\$1/g;
	return( "\"$str\"" );
};

sub normalize {
	my $data = shift;
    
	$data =~ s/[^A-Za-z0-9]//g;
	$data =~ tr/A-Z/a-z/;

	return( $data );
};


sub removeHtmlTags {
	my $string = shift;
	my $replacement = shift || '';

	$string =~ s/<.*?>/$replacement/g;

	return( $string );
};


sub getCurrentTime {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

	if( $sec < 10 ) { $sec = '0'.$sec };
	if( $min < 10 ) { $min = '0'.$min };

	return( "$hour:$min:$sec" );
};

1;

