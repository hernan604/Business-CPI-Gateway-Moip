

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::CPI::Gateway::Moip',
    VERSION_FROM => 'lib/Business/CPI/Gateway/Moip.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernan@cpan.org)',
    ABSTRACT     => 'Inteface para pagamentos moip',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
