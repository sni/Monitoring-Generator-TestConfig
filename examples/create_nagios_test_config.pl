#!/usr/bin/env perl

=head1 NAME

create_nagios_test_config.pl - create a test nagios config

=head1 SYNOPSIS

./create_nagios_test_config.pl [ -h ] [ -v ] [ -b <nagios binary> ] [ -p <prefix> ] <directory>

=head1 DESCRIPTION

this script generates a valid test nagios configuration

=head1 ARGUMENTS

script has the following arguments

=over 4

=item help

    -h

print help and exit

=item verbose

    -v

verbose output

=item prefix

    -p

add this prefix to all exported hosts and services

=item binary

    nagios binary to use

will search for nagios and nagios3 in path if not set

=item directory

    output directory for export

=back

=head1 EXAMPLE

./create_nagios_test_config.pl -p test1 /tmp/test-nagios-config/

=head1 AUTHOR

2009, Sven Nierlein, <nierlein@cpan.org>

=cut

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use lib '../lib';
use lib 'lib';
use Nagios::Generator::TestConfig;

#########################################################################
# parse and check cmd line arguments
my ($opt_h, $opt_v, $opt_p, $opt_b, $opt_d);
Getopt::Long::Configure('no_ignore_case');
if(!GetOptions (
   "h"              => \$opt_h,
   "v"              => \$opt_v,
   "p=s"            => \$opt_p,
   "b=s"            => \$opt_b,
   "<>"             => \&add_dir,
)) {
    pod2usage( { -verbose => 1, -message => 'error in options' } );
    exit 3;
}

if(defined $opt_h) {
    pod2usage( { -verbose => 1 } );
    exit 3;
}
my $verbose = 0;
if(defined $opt_v) {
    $verbose = 1;
}

if(!defined $opt_d) {
    pod2usage( { -verbose => 1, -message => 'no export directory given!' } );
    exit 3;
}

$opt_p = "" unless defined $opt_p;


#########################################################################
my $ngt = Nagios::Generator::TestConfig->new(
                    'output_dir'                => $opt_d,
                    'verbose'                   => 1,
                    'overwrite_dir'             => 1,
                    'prefix'                    => $opt_p,
                    'nagios_bin'                => $opt_b,
                    'routercount'               => 20,
                    'hostcount'                 => 200,
                    'services_per_host'         => 20,
                    'nagios_cfg'                => {
                            'broker_module' => '/opt/projects/git/check_mk/livestatus/src/livestatus.o /tmp/live.sock',
                        },
                    'hostfailrate'              => 2, # percentage
                    'servicefailrate'           => 5, # percentage
                    'host_settings'             => {
                            'normal_check_interval' => 30,
                            'retry_check_interval'  => 5,
                        },
                    'service_settings'          => {
                            'normal_check_interval' => 30,
                            'retry_check_interval'  => 5,
                        },
                    'router_types'              => {
                                    'down'         => 10, # percentage
                                    'up'           => 10,
                                    'flap'         => 10,
                                    'pending'      => 10,
                                    'random'       => 60,
                        },
                    'host_types'                => {
                                    'down'         => 5, # percentage
                                    'up'           => 50,
                                    'flap'         => 5,
                                    'pending'      => 5,
                                    'random'       => 35,
                        },
                    'service_types'             => {
                                    'ok'           => 50, # percentage
                                    'warning'      => 5,
                                    'unknown'      => 5,
                                    'critical'     => 5,
                                    'pending'      => 5,
                                    'flap'         => 5,
                                    'random'       => 25,
                        },
);
$ngt->create();
#########################################################################

sub add_dir {
    my $dir = shift;
    $opt_d  = $dir;
}
