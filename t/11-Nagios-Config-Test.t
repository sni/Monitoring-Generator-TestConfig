#!/usr/bin/env perl

use File::Which;
use Test::More;
use File::Temp qw{ tempdir };

use_ok('Nagios::Generator::TestConfig');
my $test_dir = tempdir(CLEANUP => 1);
my $ngt = Nagios::Generator::TestConfig->new( 'output_dir' => $test_dir, 'overwrite_dir' => 1 );

if(!defined $ngt->{'nagios_bin'}) {
   plan( skip_all => 'no nagios(3) bin found in path, skipping config test' );
}


########################################

$configtests = {
    "simple standard" => { 'output_dir' => $test_dir, 'overwrite_dir' => 1 },
    "simple prefix"   => { 'output_dir' => $test_dir, 'overwrite_dir' => 1, 'prefix' => 'pre_' },
    "small standard"  => { 'output_dir' => $test_dir, 'overwrite_dir' => 1, 'routercount' =>  1, 'hostcount' =>   1, 'services_per_host' =>  1 },
    "medium standard" => { 'output_dir' => $test_dir, 'overwrite_dir' => 1, 'routercount' => 30, 'hostcount' => 400, 'services_per_host' => 25 },
    "complex config"  => { 'output_dir' => $test_dir, 'overwrite_dir' => 1,
                           'routercount'               => 5,
                           'hostcount'                 => 50,
                           'services_per_host'         => 10,
                           'nagios_cfg'                => {
                                   'execute_servicechecks'  => 0,
                               },
                           'hostfailrate'              => 2,
                           'servicefailrate'           => 5,
                           'host_settings'             => {
                                   'normal_check_interval' => 30,
                                   'retry_check_interval'  => 5,
                               },
                           'service_settings'          => {
                                   'normal_check_interval' => 30,
                                   'retry_check_interval'  => 5,
                               },
                           'router_types'              => {
                                           'down'         => 20,
                                           'up'           => 20,
                                           'flap'         => 20,
                                           'pending'      => 20,
                                           'random'       => 20,
                               },
                           'host_types'                => {
                                           'down'         => 5,
                                           'up'           => 50,
                                           'flap'         => 5,
                                           'pending'      => 5,
                                           'random'       => 35,
                               },
                           'service_types'             => {
                                           'ok'           => 50,
                                           'warning'      => 5,
                                           'unknown'      => 5,
                                           'critical'     => 5,
                                           'pending'      => 5,
                                           'flap'         => 5,
                                           'random'       => 25,
                               },
                         },
};

for my $name (keys %{$configtests}) {
    my $test_dir = tempdir(CLEANUP => 1);

    my $conf = $configtests->{$name};
    my $ngt = Nagios::Generator::TestConfig->new( 'output_dir' => $test_dir, 'overwrite_dir' => 1 );
    isa_ok($ngt, 'Nagios::Generator::TestConfig');
    $ngt->create();

    my $testcommands = [
        $ngt->{'nagios_bin'}.' -v '.$test_dir.'/nagios.cfg',
        $test_dir.'/init.d/nagios checkconfig',
    ];
    # add some author tests
    if($ENV{TEST_AUTHOR} ) {
        push @{$testcommands}, $test_dir.'/init.d/nagios start';
        push @{$testcommands}, $test_dir.'/init.d/nagios status';
        push @{$testcommands}, $test_dir.'/init.d/nagios stop';
    }

    for $cmd (@{$testcommands}) {
        open(my $ph, '-|', $cmd) or die('exec "'.$cmd.'" failed: $!');
        my $output = "";
        while(<$ph>) {
            $output .= $_;
        }
        close($ph);
        my $rt = $?>>8;
        is($rt,0,"$name: $cmd") or diag($output);
    }
}

done_testing();
