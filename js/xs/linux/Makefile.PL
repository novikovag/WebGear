use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => "WebGear::SpiderMonkey",
    VERSION_FROM  => "SpiderMonkey.pm",
    AUTHOR        => "Artem Novikov",
    OPTIMIZE      => "-w -Wfatal-errors",
    INC           => "-I../../engines/spidermonkey-1.7",
    LIBS          => "-L../../engines/spidermonkey-1.7/linux -ljs -lrt",
    DEFINE        => "-DXP_UNIX",
    NO_META       => 1,
    NO_MYMETA     => 1,
);
