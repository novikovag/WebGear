use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => "WebGear::SpiderMonkey",
    VERSION_FROM  => "SpiderMonkey.pm",
    AUTHOR        => "Artem Novikov",
    OPTIMIZE      => "-w -Wfatal-errors",
    INC           => "-I../../engines/spidermonkey-1.7",
    LIBS          => "-L../../engines/spidermonkey-1.7/mingw64 -ljs",
    DEFINE        => "-DXP_WIN",
    NO_META       => 1,
    NO_MYMETA     => 1,
);
