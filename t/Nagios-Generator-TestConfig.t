#!/usr/bin/env perl

use Test::More tests => 3;
use File::Temp qw{ tempdir };
BEGIN { use_ok('Nagios::Generator::TestConfig') };

my $test_dir = tempdir(CLEANUP => 1);

my $ngt = Nagios::Generator::TestConfig->new({ 'output_dir' => $test_dir, 'overwrite_dir' => 1 });
isa_ok($ngt, 'Nagios::Generator::TestConfig');

$ngt->create();


########################################
# try to find a nagios bin
my $nagios_bin;
$nagios_bin = `which nagios3`;
$nagios_bin = `which nagios2` unless $? and defined $nagios_bin;
$nagios_bin = `which nagios`  unless $? and defined $nagios_bin;
SKIP: {
    skip 'no nagios3 bin found in path, skipping config test', 1, if($? != 0 or !defined $nagios_bin or $nagios_bin eq '');

    my $cmd = $nagios_bin.' -v '.$test_dir.'/nagios.cfg';
    open(my $ph, '-|', $cmd) or die('exec "'.$cmd.'" failed: $!');
    my $output = "";
    while(<$ph>) {
        $output .= $_;
    }
    close($ph);
    my $rt = $?>>8;
    is($rt,0,"$cmd") or diag($output);
}
