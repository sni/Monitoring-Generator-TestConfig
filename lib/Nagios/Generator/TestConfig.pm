package Nagios::Generator::TestConfig;

use 5.008000;
use strict;
use warnings;
use Carp;

our $VERSION = '0.13';

########################################
sub new {
    my($class,%options) = @_;
    my $self = {
                    "verbose"                   => 0,
                    "output_dir"                => undef,
                    "overwrite_dir"             => 0,
                    "hostcount"                 => 10,
                    "services_per_host"         => 10,
                    "normal_check_interval"     => 1,
                    "retry_check_interval"      => 1,
                    "nagios_cfg"                => "",
               };
    bless $self, $class;

    for my $opt_key (keys %options) {
        if(exists $self->{$opt_key}) {
            $self->{$opt_key} = $options{$opt_key};
        }
        else {
            croak("unknown option: $opt_key");
        }
    }

    if(!defined $self->{'output_dir'}) {
        croak('no output_dir given');
    }

    if(-e $self->{'output_dir'} and !$self->{'overwrite_dir'}) {
        croak('output_dir '.$self->{'output_dir'}.' does already exist and overwrite_dir not set');
    }

    return $self;
}


########################################
sub create {
    my $self = shift;

    if(!-e $self->{'output_dir'}) {
        mkdir($self->{'output_dir'}) or croak('failed to create output_dir '.$self->{'output_dir'}.':'.$!);
    }

    # write out nagios.cfg
    open(FH, '>', $self->{'output_dir'}.'/nagios.cfg') or die('cannot write: '.$!);
    print FH $self->_get_nagios_cfg();
    close FH;

    # create some missing dirs
    if(!-d $self->{'output_dir'}.'/tmp') {
        mkdir($self->{'output_dir'}.'/tmp')
            or croak('failed to create tmp dir ('.$self->{'output_dir'}.'/tmp) :' .$!);
    }
    if(!-d $self->{'output_dir'}.'/checkresults') {
        mkdir($self->{'output_dir'}.'/checkresults')
            or croak('failed to create checkresults dir ('.$self->{'output_dir'}.'/checkresults): '.$!);
    }

    # write out resource.cfg
    open(FH, '>', $self->{'output_dir'}.'/resource.cfg') or die('cannot write: '.$!);
    print FH '$USER1$='.$self->{'output_dir'};
    close FH;

    # write out hosts.cfg
    open(FH, '>', $self->{'output_dir'}.'/hosts.cfg') or die('cannot write: '.$!);
    print FH $self->_get_hosts_cfg();
    close FH;

    # write out services.cfg
    open(FH, '>', $self->{'output_dir'}.'/services.cfg') or die('cannot write: '.$!);
    print FH $self->_get_services_cfg();
    close FH;

    # write out contacts.cfg
    open(FH, '>', $self->{'output_dir'}.'/contacts.cfg') or die('cannot write: '.$!);
    print FH $self->_get_contacts_cfg();
    close FH;

    # write out commands.cfg
    open(FH, '>', $self->{'output_dir'}.'/commands.cfg') or die('cannot write: '.$!);
    print FH $self->_get_commands_cfg();
    close FH;

    # write out timperiods.cfg
    open(FH, '>', $self->{'output_dir'}.'/timeperiods.cfg') or die('cannot write: '.$!);
    print FH $self->_get_timeperiods_cfg();
    close FH;

    print "exported test config to: $self->{'output_dir'}\n";
}


########################################
sub _get_hosts_cfg {
    my $self = shift;
    my $cfg = <<EOT;
define host{
    name                            generic-host
    notifications_enabled           1
    event_handler_enabled           1
    flap_detection_enabled          1
    failure_prediction_enabled      1
    process_perf_data               1
    retain_status_information       1
    retain_nonstatus_information    1
    check_command                   check-host-alive
    max_check_attempts              10
    normal_check_interval           $self->{'normal_check_interval'}
    retry_check_interval            $self->{'retry_check_interval'}
    notification_interval           0
    notification_period             24x7
    notification_options            d,u,r
    contact_groups                  test_contact
    register                        0
}
EOT

    for(my $x = 0; $x < $self->{'hostcount'}; $x++) {
        $cfg .= "
define host {
    host_name   test_host_$x
    alias       test_host_$x
    use         generic-host
    address     127.0.0.$x
}";
    }

    return($cfg);
}

########################################
sub _get_services_cfg {
    my $self = shift;
    my $cfg = <<EOT;
define service{
    name                            generic-service
    active_checks_enabled           1
    passive_checks_enabled          1
    parallelize_check               1
    obsess_over_service             1
    check_freshness                 0
    notifications_enabled           1
    event_handler_enabled           1
    flap_detection_enabled          1
    failure_prediction_enabled      1
    process_perf_data               1
    retain_status_information       1
    retain_nonstatus_information    1
    notification_interval           0
    is_volatile                     0
    check_period                    24x7
    normal_check_interval           $self->{'normal_check_interval'}
    retry_check_interval            $self->{'retry_check_interval'}
    max_check_attempts              4
    notification_period             24x7
    notification_options            w,u,c,r
    contact_groups                  test_contact
    register                        0
}
EOT

    for(my $x = 0; $x < $self->{'hostcount'}; $x++) {
        for(my $y = 0; $y < $self->{'services_per_host'}; $y++) {
            $cfg .= "
    define service {
            host_name                       test_host_$x
            service_description             test_service_$y
            check_command                   check_service
            use                             generic-service
    }";
        }
    }

    return($cfg);
}

########################################
sub _get_contacts_cfg {
    my $self = shift;
    my $cfg = <<EOT;
define contactgroup{
    contactgroup_name       test_contact
    alias                   test_contacts
    members                 test_contact
}
define contact{
    contact_name                    test_contact
    alias                           test_contact
    service_notification_period     24x7
    host_notification_period        24x7
    service_notification_options    w,u,c,r
    host_notification_options       d,r
    service_notification_commands   notify-service
    host_notification_commands      notify-host
    email                           nobody\@localhost
}
EOT
    return($cfg);
}

########################################
sub _get_commands_cfg {
    my $self = shift;
    my $cfg = <<EOT;
define command{
    command_name    check-host-alive
    command_line    sleep 1 && /bin/true
}
define command{
    command_name    notify-host
    command_line    sleep 1 && /bin/true
}
define command{
    command_name    notify-service
    command_line    sleep 1 && /bin/true
}
define command{
    command_name    check_service
    command_line    sleep 1 && /bin/true
}
EOT
    return($cfg);
}

########################################
sub _get_timeperiods_cfg {
    my $self = shift;
    my $cfg = <<EOT;
define timeperiod{
    timeperiod_name 24x7
    alias           24 Hours A Day, 7 Days A Week
    sunday          00:00-24:00
    monday          00:00-24:00
    tuesday         00:00-24:00
    wednesday       00:00-24:00
    thursday        00:00-24:00
    friday          00:00-24:00
    saturday        00:00-24:00
}
EOT
    return($cfg);
}

########################################
sub _get_nagios_cfg {
    my $self = shift;

    my $nagios_cfg = <<EOT;
log_file=$self->{'output_dir'}/nagios.log
cfg_file=$self->{'output_dir'}/hosts.cfg
cfg_file=$self->{'output_dir'}/services.cfg
cfg_file=$self->{'output_dir'}/contacts.cfg
cfg_file=$self->{'output_dir'}/commands.cfg
cfg_file=$self->{'output_dir'}/timeperiods.cfg
object_cache_file=$self->{'output_dir'}/objects.cache
precached_object_file=$self->{'output_dir'}/objects.precache
resource_file=$self->{'output_dir'}/resource.cfg
status_file=$self->{'output_dir'}/status.dat
status_update_interval=10
nagios_user=nagios
nagios_group=nagios
check_external_commands=0
command_check_interval=-1
command_file=$self->{'output_dir'}/nagios.cmd
external_command_buffer_slots=4096
lock_file=$self->{'output_dir'}/nagios3.pid
temp_file=$self->{'output_dir'}/nagios.tmp
temp_path=$self->{'output_dir'}/tmp
event_broker_options=-1
log_rotation_method=d
log_archive_path=$self->{'output_dir'}/archives
use_syslog=1
log_notifications=1
log_service_retries=1
log_host_retries=1
log_event_handlers=1
log_initial_states=0
log_external_commands=1
log_passive_checks=1
service_inter_check_delay_method=s
max_service_check_spread=30
service_interleave_factor=s
host_inter_check_delay_method=s
max_host_check_spread=30
max_concurrent_checks=0
check_result_reaper_frequency=10
max_check_result_reaper_time=30
check_result_path=$self->{'output_dir'}/checkresults
max_check_result_file_age=3600
cached_host_check_horizon=15
cached_service_check_horizon=15
enable_predictive_host_dependency_checks=1
enable_predictive_service_dependency_checks=1
soft_state_dependencies=0
auto_reschedule_checks=0
auto_rescheduling_interval=30
auto_rescheduling_window=180
sleep_time=0.25
service_check_timeout=60
host_check_timeout=30
event_handler_timeout=30
notification_timeout=30
ocsp_timeout=5
perfdata_timeout=5
retain_state_information=1
state_retention_file=$self->{'output_dir'}/retention.dat
retention_update_interval=60
use_retained_program_state=1
use_retained_scheduling_info=1
retained_host_attribute_mask=0
retained_service_attribute_mask=0
retained_process_host_attribute_mask=0
retained_process_service_attribute_mask=0
retained_contact_host_attribute_mask=0
retained_contact_service_attribute_mask=0
interval_length=60
use_aggressive_host_checking=0
execute_service_checks=1
accept_passive_service_checks=1
execute_host_checks=1
accept_passive_host_checks=1
enable_notifications=1
enable_event_handlers=1
process_performance_data=0
obsess_over_services=0
obsess_over_hosts=0
translate_passive_host_checks=0
passive_host_checks_are_soft=0
check_for_orphaned_services=1
check_for_orphaned_hosts=1
check_service_freshness=1
service_freshness_check_interval=60
check_host_freshness=0
host_freshness_check_interval=60
additional_freshness_latency=15
enable_flap_detection=1
low_service_flap_threshold=5.0
high_service_flap_threshold=20.0
low_host_flap_threshold=5.0
high_host_flap_threshold=20.0
date_format=iso8601
p1_file=$self->{'output_dir'}/p1.pl
enable_embedded_perl=1
use_embedded_perl_implicitly=1
illegal_object_name_chars=`~!\$%^&*|'"<>?,()=
illegal_macro_output_chars=`~\$&|'"<>
use_regexp_matching=0
use_true_regexp_matching=0
admin_email=root\@localhost
admin_pager=pageroot\@localhost
daemon_dumps_core=0
use_large_installation_tweaks=0
enable_environment_macros=1
debug_level=0
debug_verbosity=1
debug_file=$self->{'output_dir'}/nagios.debug
max_debug_file_size=1000000
EOT

    if(defined $self->{'nagios_cfg'} and ref($self->{'nagios_cfg'}) eq 'ARRAY') {
        $nagios_cfg .= join('\n', @{$self->{'nagios_cfg'}});
    }
    elsif(defined $self->{'nagios_cfg'}) {
        $nagios_cfg .= $self->{'nagios_cfg'};
    }
    return($nagios_cfg);
}


1;
__END__

=head1 NAME

Nagios::Generator::TestConfig - Perl extension for generating test nagios configurations

=head1 SYNOPSIS

  use Nagios::Generator::TestConfig;
  my $ngt = Nagios::Generator::TestConfig->new( 'output_dir' => '/tmp/test_nagios' );
  $ngt->create();

=head1 DESCRIPTION

This modul generates test configurations for nagios. This can be useful if you
want for doing load tests or testing nagios addons and plugins.

=head1 AUTHOR

Sven Nierlein, nierlein@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Sven Nierlein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
