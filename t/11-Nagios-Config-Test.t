#!/usr/bin/env perl

use File::Which;
use Test::More;
use File::Temp qw{ tempdir };

########################################
# try to find a nagios bin
my $nagios_bin;
$nagios_bin = which('nagios3') or which('nagios2') or which('nagios');
if(!defined $nagios_bin) {
   plan( skip_all => 'no nagios(2,3) bin found in path, skipping config test' );
} else {
    plan( tests => 3 );
}


########################################
use_ok('Nagios::Generator::TestConfig');
my $test_dir = tempdir(CLEANUP => 1);

my $ngt = Nagios::Generator::TestConfig->new( 'output_dir' => $test_dir, 'overwrite_dir' => 1 );
isa_ok($ngt, 'Nagios::Generator::TestConfig');
$ngt->create();

my $cmd = $nagios_bin.' -v '.$test_dir.'/nagios.cfg';
open(my $ph, '-|', $cmd) or die('exec "'.$cmd.'" failed: $!');
my $output = "";
while(<$ph>) {
    $output .= $_;
}
close($ph);
my $rt = $?>>8;
is($rt,0,"$cmd") or diag($output);
