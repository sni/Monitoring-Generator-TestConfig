package # hidden from cpan
    Nagios::Generator::TestConfig::ServiceCheckData;

use 5.000000;
use strict;
use warnings;


########################################

=over 4

=item get_test_servicecheck

    returns the test servicecheck plugin source

=back

=cut

sub get_test_servicecheck {
    my $self = shift;
    our $testservicecheck;
    return($testservicecheck) if defined $testservicecheck;
    while(my $line = <DATA>) { $testservicecheck .= $line; }
    return($testservicecheck);
}

1;

__DATA__
#!/usr/bin/env perl

# nagios: +epn

=head1 NAME

test_servicecheck.pl - service check replacement for testing purposes

=head1 SYNOPSIS

./test_servicecheck.pl [ -v ] [ -h ]
                       [ --type=<type>                 ]
                       [ --minimum-outage=<seconds>    ]
                       [ --failchance=<percentage>     ]
                       [ --previous-state=<state>      ]
                       [ --state-duration=<meconds>    ]
                       [ --total-critical-on-host=<nr> ]
                       [ --total-warning-on-host=<nr>  ]

=head1 DESCRIPTION

this service check calculates a random based result. It can be used as a testing replacement
service check

example nagios configuration:

    defined command {
        command_name  check_service
        command_line  $USER1$/test_servicecheck.pl --failchance=2% --previous-state=$SERVICESTATE$ --state-duration=$SERVICEDURATIONSEC$ --total-critical-on-host=$TOTALHOSTSERVICESCRITICAL$ --total-warning-on-host=$TOTALHOSTSERVICESWARNING$
    }

=head1 ARGUMENTS

script has the following arguments

=over 4

=item help

    -h

print help and exit

=item verbose

    -v

verbose output

=item type

    --type

can be one of ok,warning,critical,unknown,random,flap

=back

=head1 EXAMPLE

./test_servicecheck.pl --minimum-outage=60
                       --failchance=3%
                       --previous-state=OK
                       --state-duration=2500
                       --total-critical-on-host=0
                       --total-warning-on-host=0

=head1 AUTHOR

2009, Sven Nierlein, <nierlein@cpan.org>

=cut

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use Sys::Hostname;

#########################################################################
do_check();

#########################################################################
sub do_check {
    #####################################################################
    # parse and check cmd line arguments
    my ($opt_h, $opt_v, $opt_failchance, $opt_previous_state, $opt_minimum_outage, $opt_state_duration, $opt_total_crit, $opt_total_warn, $opt_type);
    Getopt::Long::Configure('no_ignore_case');
    if(!GetOptions (
       "h"                        => \$opt_h,
       "v"                        => \$opt_v,
       "type=s"                   => \$opt_type,
       "minimum-outage=i"         => \$opt_minimum_outage,
       "failchance=s"             => \$opt_failchance,
       "previous-state=s"         => \$opt_previous_state,
       "state-duration=i"         => \$opt_state_duration,
       "total-critical-on-host=i" => \$opt_total_crit,
       "total-warning-on-host=i"  => \$opt_total_warn,
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
    if($opt_failchance =~ m/^(\d+)%/) {
        $opt_failchance = $1;
    } else {
        pod2usage( { -verbose => 1, -message => 'failchance must be a percentage' } );
        exit 3;
    }

    #########################################################################
    # Set Defaults
    $opt_minimum_outage = 0    if !defined $opt_minimum_outage;
    $opt_failchance     = 5    if !defined $opt_failchance;
    $opt_previous_state = 'OK' if !defined $opt_previous_state;
    $opt_state_duration = 0    if !defined $opt_state_duration;
    $opt_total_crit     = 0    if !defined $opt_total_crit;
    $opt_total_warn     = 0    if !defined $opt_total_warn;

    #########################################################################
    my $states = {
        'OK'       => 0,
        'WARNING'  => 1,
        'CRITICAL' => 2,
        'UNKNOWN'  => 3,
        'PENDING'  => 4,
    };

    #########################################################################
    my $hostname = hostname;

    #########################################################################
    # not a random check?
    if(defined $opt_type and lc $opt_type ne 'random') {
        if(lc $opt_type eq 'ok') {
            print "$hostname OK: ok servicecheck\n";
            exit 0;
        }
        if(lc $opt_type eq 'warning') {
            print "$hostname WARNING: warning servicecheck\n";
            exit 1;
        }
        if(lc $opt_type eq 'critical') {
            print "$hostname CRITICAL: critical servicecheck\n";
            exit 2;
        }
        if(lc $opt_type eq 'unknown') {
            print "$hostname UNKNOWN: unknown servicecheck\n";
            exit 3;
        }
        if(lc $opt_type eq 'flap') {
            if($opt_previous_state eq 'OK' or $opt_previous_state eq 'UP') {
                print "$hostname FLAP: down servicecheck down\n";
                exit 2;
            }
            print "$hostname FLAP: up servicecheck up\n";
            exit 0;
        }
    }

    my $rand     = int(rand(100));
    print "random number is $rand\n" if $verbose;

    # if the service is currently up, then there is a chance to fail
    if($opt_previous_state eq 'OK') {
        if($rand < $opt_failchance) {
            # failed

            # warning critical or unknown?
            my $rand2 = int(rand(100));

            # 60% chance for a critical
            if($rand2 > 60) {
                # a failed check takes a while
                my $sleep = 5 + int(rand(20));
                sleep($sleep);
                print "$hostname CRITICAL: random servicecheck critical\n";
                exit 2;
            }
            # 30% chance for a warning
            if($rand2 > 10) {
                # a failed check takes a while
                my $sleep = 5 + int(rand(20));
                sleep($sleep);
                print "$hostname WARNING: random servicecheck warning\n";
                exit 1;
            }

            # 10% chance for a unknown
            print "$hostname UNKNOWN: random servicecheck unknown\n";
            exit 3;
        }
    }
    else {
        # already hit the minimum outage?
        if($opt_minimum_outage > $opt_state_duration) {
            print "$hostname $opt_previous_state: random servicecheck minimum outage not reached yet\n";
            exit $states->{$opt_previous_state};
        }
        # if the service is currently down, then there is a 30% chance to recover
        elsif($rand < 30) {
            print "$hostname REVOVERED: random servicecheck recovered\n";
            exit 0;
        }
        else {
            # a failed check takes a while
            my $sleep = 5 + int(rand(20));
            sleep($sleep);
            print "$hostname $opt_previous_state: random servicecheck unchanged\n";
            exit $states->{$opt_previous_state};
        }
    }

    print "$hostname OK: random servicecheck ok\n";
    exit 0;
}
