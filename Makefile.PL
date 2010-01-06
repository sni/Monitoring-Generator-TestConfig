use 5.000000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Monitoring::Generator::TestConfig',
    VERSION_FROM      => 'lib/Monitoring/Generator/TestConfig.pm',
    PREREQ_PM         => { 'File::Which' => 0 },
    ABSTRACT_FROM     => 'lib/Monitoring/Generator/TestConfig.pm',
    AUTHOR            => 'Sven Nierlein <nierlein@cpan.org>',
    $ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( 'LICENSE' => 'perl' ) : (),
);
