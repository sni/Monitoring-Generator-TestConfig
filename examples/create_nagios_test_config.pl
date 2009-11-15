#!/usr/bin/perl

use warnings;
use strict;
use lib '../lib';
use lib 'lib';
use Nagios::Generator::TestConfig;
my $ngt = Nagios::Generator::TestConfig->new(
                    'output_dir' => '/tmp/nagios3-2.0',
                    'verbose'                   => 1,
                    'overwrite_dir'             => 1,
                    'hostcount'                 => 10,
                    'services_per_host'         => 20,
                    'nagios_cfg'                => {
                            'broker_module' => '/tmp/mk-livestatus-1.1.0beta13/livestatus.o /tmp/live.sock',
                        },
);
$ngt->create();
