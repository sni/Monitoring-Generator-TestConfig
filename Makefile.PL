use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Nagios::Generator::TestConfig',
    VERSION_FROM      => 'lib/Nagios/Generator/TestConfig.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/Nagios/Generator/TestConfig.pm',
    AUTHOR            => 'Sven Nierlein <nierlein@cpan.org>',
    $ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( 'LICENSE' => 'perl' ) : (),
);
