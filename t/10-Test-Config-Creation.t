#!/usr/bin/env perl

use File::Which;
use Test::More tests => 2;
use File::Temp qw{ tempdir };

########################################
use_ok('Nagios::Generator::TestConfig');
my $test_dir = tempdir(CLEANUP => 1);

my $ngt = Nagios::Generator::TestConfig->new( 'output_dir' => $test_dir, 'overwrite_dir' => 1 );
isa_ok($ngt, 'Nagios::Generator::TestConfig');
$ngt->create();
