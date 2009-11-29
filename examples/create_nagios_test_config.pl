#!/usr/bin/env perl

=head1 NAME

create_nagios_test_config.pl - create a test nagios config

=head1 SYNOPSIS

./create_nagios_test_config.pl [ -h ] [ -v ] <directory>

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

=item directory

    output directory for export

=back

=head1 EXAMPLE

./create_nagios_test_config.pl /tmp/test-nagios-config/

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
my ($opt_h, $opt_v, $opt_d);
Getopt::Long::Configure('no_ignore_case');
if(!GetOptions (
   "h"              => \$opt_h,
   "v"              => \$opt_v,
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


#########################################################################
my $nagios_user  = getlogin();
my @userinfo     = getpwnam($nagios_user);
my @groupinfo    = getgrgid($userinfo[3]);
my $nagios_group = $groupinfo[0];
my $ngt = Nagios::Generator::TestConfig->new(
                    'output_dir'                => $opt_d,
                    'verbose'                   => 1,
                    'overwrite_dir'             => 1,
                    'hostcount'                 => 10,
                    'services_per_host'         => 5,
                    'nagios_cfg'                => {
                            'broker_module' => '/opt/projects/git/check_mk/livestatus/src/livestatus.o /tmp/live.sock',
                            'nagios_user'   => $nagios_user,
                            'nagios_group'  => $nagios_group,
                        },
                    'host_settings'             => {
                            'normal_check_interval' => 30,
                            'retry_check_interval'  => 5,
                        },
                    'service_settings'          => {
                            'normal_check_interval' => 30,
                            'retry_check_interval'  => 5,
                        },
);
$ngt->create();
#########################################################################

sub add_dir {
    my $dir = shift;
    $opt_d  = $dir;
}
