#!/usr/bin/perl -w

use strict;

use Error qw( :try );

use Net::AIMTOC::Message;
use Net::AIMTOC::Error;

my $messages = [
	'',
	'ERROR:983',
	'ERROR:902:test_im',
	'ERROR:901:test_im',
	'IM_IN:test_im:F:test',
	'UPDATE_BUDDY:test_im:T:0:1021475933:0: U',
	'SIGN_ON:TOC1.0',
];

my $id = $ARGV[0] || 0;

my $data = $messages->[$id];

my $msg;

try {
	$msg = Net::AIMTOC::Message->new( 2, $data );

	print 'Type: '. $msg->getType ."\n";
	print 'Msg:  '. $msg->getMsg ."\n";
	print 'Data: '. $msg->getRawData ."\n";

}
catch Net::AIMTOC::Error with {
	my $err = shift;
	print $err->stringify, "\n";

};

