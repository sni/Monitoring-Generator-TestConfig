#!/usr/bin/env perl

use File::Which;
use Test::More;
use File::Temp qw{ tempdir };

########################################
# try to find a nagios bin
my $nagios_bin;
$nagios_bin = which('nagios3') or which('nagios');
if(!defined $nagios_bin) {
   plan( skip_all => 'no nagios(3) bin found in path, skipping config test' );
}


########################################

$configtests = {
    "simple standard" => { 'output_dir' => $test_dir, 'overwrite_dir' => 1 },
    "small standard"  => { 'output_dir' => $test_dir, 'overwrite_dir' => 1, 'routercount' =>  1, 'hostcount' =>   1, 'services_per_host' =>  1 },
    "medium standard" => { 'output_dir' => $test_dir, 'overwrite_dir' => 1, 'routercount' => 30, 'hostcount' => 400, 'services_per_host' => 25 },
};

for my $name (keys %{$configtests}) {
    use_ok('Nagios::Generator::TestConfig');
    my $test_dir = tempdir(CLEANUP => 1);

    my $conf = $configtests->{$name};
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
    is($rt,0,"$name: $cmd") or diag($output);
}

done_testing();
