package # hidden from cpan
    Nagios::Generator::TestConfig::HostCheckData;

use 5.000000;
use strict;
use warnings;

########################################

=over 4

=item get_test_hostcheck

    returns the test hostcheck plugin source

=back

=cut

sub get_test_hostcheck {
    my $self = shift;
    my $testhostcheck;
    while(my $line = <DATA>) { $testhostcheck .= $line; }
    return($testhostcheck);
}

1;

__DATA__
#!/usr/bin/env perl

=head1 NAME

test_hostcheck.pl - host check replacement for testing purposes

=head1 SYNOPSIS

./test_hostcheck.pl [ -v ] [ -h ]
                    [ --minimum-outage=<seconds>    ]
                    [ --failchance=<percentage>     ]
                    [ --previous-state=<state>      ]
                    [ --state-duration=<meconds>    ]

=head1 DESCRIPTION

this host check calculates a random based result. It can be used as a testing replacement
host check

example nagios configuration:

    defined command {
        command_name  check_host_alive
        command_line  $USER1$/test_hostcheck.pl --failchance=2% --previous-state=$SERVICESTATE$ --state-duration=$SERVICEDURATIONSEC$
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

=back

=head1 EXAMPLE

./test_hostcheck.pl --minimum-outage=60
                    --failchance=3%
                    --previous-state=OK
                    --state-duration=2500

=head1 AUTHOR

2009, Sven Nierlein, <nierlein@cpan.org>

=cut

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use Sys::Hostname;

#########################################################################
# parse and check cmd line arguments
my ($opt_h, $opt_v, $opt_failchance, $opt_previous_state, $opt_minimum_outage, $opt_state_duration );
Getopt::Long::Configure('no_ignore_case');
if(!GetOptions (
   "h"                        => \$opt_h,
   "v"                        => \$opt_v,
   "minimum-outage=i"         => \$opt_minimum_outage,
   "failchance=s"             => \$opt_failchance,
   "previous-state=s"         => \$opt_previous_state,
   "state-duration=i"         => \$opt_state_duration,
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
$opt_previous_state = 'UP' if !defined $opt_previous_state;

#########################################################################
my $states = {
    'UP'    => 0,
    'DOWN'  => 1,
    'DOWN'  => 2,
    'DOWN'  => 3,
    'DOWN'  => 4,
};

#########################################################################
my $hostname = hostname;
my $rand     = int(rand(100));
print "random number is $rand\n" if $verbose;

# if the host is currently up, then there is a chance to fail
if($opt_previous_state eq 'OK') {
    if($rand < $opt_failchance) {
        # failed

        # warning critical or unknown?
        my $rand2 = int(rand(100));

        # 60% chance for a critical
        if($rand2 > 60) {
            #sleep(15); # a failed check takes a while
            print "$hostname CRITICAL: random hostcheck critical\n";
            exit 2;
        }
        # 30% chance for a warning
        if($rand2 > 10) {
            #sleep(10); # a failed check takes a while
            print "$hostname WARNING: random hostcheck warning\n";
            exit 1;
        }

        # 10% chance for a unknown
        print "$hostname UNKNOWN: random hostcheck unknown\n";
        exit 3;
    }
}
else {
    # already hit the minimum outage?
    if($opt_minimum_outage > $opt_state_duration) {
        print "$hostname $opt_previous_state: random hostcheck minimum outage not reached yet\n";
        exit $states->{$opt_previous_state};
    }
    # if the host is currently down, then there is a 30% chance to recover
    elsif($rand < 30) {
        print "$hostname REVOVERED: random hostcheck recovered\n";
        exit 0;
    }
    else {
        #sleep(10); # a failed check takes a while
        print "$hostname $opt_previous_state: random hostcheck unchanged\n";
        exit $states->{$opt_previous_state};
    }
}

print "$hostname OK: random hostcheck ok\n";
exit 0;
