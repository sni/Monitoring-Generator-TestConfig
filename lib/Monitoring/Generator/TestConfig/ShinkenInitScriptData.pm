package # hidden from cpan
    Monitoring::Generator::TestConfig::ShinkenInitScriptData;

use strict;
use warnings;

########################################

=over 4

=item get_init_script

    returns the init script source

    adapted from the nagios debian package

=back

=cut

sub get_init_script {
    my $self      = shift;
    my $prefix    = shift;
    my $binary    = shift;
    our $initsource;
    if(!defined $initsource) {
       while(my $line = <DATA>) { $initsource .= $line; }
    }

    my $binpath = $binary;
    $binpath =~ s/^(.*)\/.*$/$1/mx;

    my $initscript = $initsource;
    $initscript =~ s/__PREFIX__/$prefix/gmx;
    $initscript =~ s/__BIN__/$binpath/gmx;
    return($initscript);
}

1;

__DATA__
#!/bin/sh

### BEGIN INIT INFO
# Provides:          shinken
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      S 0 1 6
# Short-Description: shinken
# Description:       shinken monitoring daemon
### END INIT INFO

NAME="shinken"
SCRIPTNAME=$0
CMD=$1
SUBMODULES=$2
BIN="__BIN__"
VAR="__PREFIX__/var"
ETC="__PREFIX__/etc"

if [ -z $SUBMODULES ]; then
    SUBMODULES="scheduler poller reactionner broker arbiter"
fi


# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
[ -f /etc/default/rcS ] && . /etc/default/rcS

# Define LSB log_* functions.
. /lib/lsb/init-functions

#
# return the pid for a submodule
#
getmodpid() {
    mod=$1
    pidfile="$VAR/${mod}d.pid"
    if [ $mod != 'arbiter' ]; then
        pidfile="$VAR/shinken.pid"
    fi
    if [ -s $pidfile ]; then
        cat $pidfile
    fi
}

#
# stop modules
#
do_stop() {
    ok=0
    fail=0
    echo "stoping $NAME...";
    for mod in $SUBMODULES; do
        pid=`getmodpid $mod`;
        printf "%-15s: " $mod
        if [ ! -z $pid ]; then
            for cpid in $(ps -aef | grep $pid | grep "shinken-" | awk '{print $2}'); do
                kill $cpid > /dev/null 2>&1
            done
        fi
        echo "done"
    done
    return 0
}


#
# Display status
#
do_status() {
    ok=0
    fail=0
    echo "status $NAME: ";
    for mod in $SUBMODULES; do
        pid=`getmodpid $mod`;
        printf "%-15s: " $mod
        if [ ! -z $pid ]; then
            ps -p $pid >/dev/null 2>&1
            if [ $? = 0 ]; then
                echo "RUNNING (pid $pid)"
                let ok++
            else
                echo "NOT RUNNING"
                let fail++
            fi
        else
            echo "NOT RUNNING"
            let fail++
        fi
    done
    if [ $fail -gt 0 ]; then
        return 1
    fi
    return 0
}

#
# start our modules
#
do_start() {
    echo "starting $NAME: ";
    for mod in $SUBMODULES; do
        printf "%-15s: " $mod
        if [ $mod != 'arbiter' ]; then
            $BIN/shinken-${mod} -d -c $ETC/${mod}d.cfg > /dev/null 2>&1
        else
            $BIN/shinken-${mod} -d -c $ETC/../shinken.cfg -c $ETC/shinken-specific.cfg > /dev/null 2>&1
        fi
        if [ $? = 0 ]; then
            echo "OK"
        else
            echo "FAILED"
        fi
    done
}

#
# check for our command
#
case "$1" in
  start)
    [ "$VERBOSE" != no ] && log_daemon_msg "Starting $NAME"
    do_start
    case "$?" in
        0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
        2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
    esac
    ;;
  stop)
    [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $NAME"
    do_stop
    case "$?" in
        0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
        2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
    esac
    ;;
  restart)
    [ "$VERBOSE" != no ] && log_daemon_msg "Restarting $NAME"
    do_stop
    case "$?" in
      0|1)
        do_start
        case "$?" in
            0) log_end_msg 0 ;;
            1) log_end_msg 1 ;; # Old process is still running
            *) log_end_msg 1 ;; # Failed to start
        esac
        ;;
      *)
        # Failed to stop
        log_end_msg 1
        ;;
    esac
    ;;
  status)
    do_status
    ;;
  *)
    echo "Usage: $SCRIPTNAME {start|stop|restart|status} [ <scheduler|poller|reactionner|broker|arbiter> ]" >&2
    exit 3
    ;;
esac
