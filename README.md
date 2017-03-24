# WebGear

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=FQCHHCBNTSR8A)

Perl HTML5 парсер с поддержкой JS.

# Установка

## *NIX

1. Настроить переменные среды:

    ```BASH
        export PERL5LIB=~/

        export WEBGEAR=~/WebGear
    ```

2. Собрать движок SpiderMonkey:        

    ```BASH
        cd %WEBGEAR%/js/engines/spidermonkey-1.7/linux
        make        
    ```

3. Собрать XS связку JSDOM:  

    ```BASH
        cd %WEBGEAR%/js/xs/linux
        perl Makefile.PL
        make
        make install
    ```        

## Windows (ActivePerl + MinGW-w64)

1. Настроить переменные среды:

    ```BAT
        set MINGW_HOME=C:\MinGW64\x86_64-6.1.0-posix-seh-rt_v5-rev0\mingw64    
        set PATH=%MINGW_HOME%\bin    
        set LIBRARY_PATH=%MINGW_HOME%\x86_64-w64-mingw32\lib

        set PERL_HOME=C:\Perl
        set PATH=%PATH%\%PERL_HOME%\bin;%PERL_HOME%\site\bin
        set PERL5LIB=C:\
        
        set WEBGEAR=C:\WebGear
    ``` 

2. Скачать [dmake](http://search.cpan.org/CPAN/authors/id/S/SH/SHAY/dmake-4.12.2.2.zip) и
   распаковать `dmake.exe` и `startup` в `%PERL_HOME%\site\bin`        
        
3. Собрать движок SpiderMonkey:    
    
    ```BAT
        cd %WEBGEAR%\js\engines\spidermonkey-1.7\mingw64
        make
    ```
     
4. Собрать XS связку JSDOM:  

    ```BAT
        cd %WEBGEAR%\js\xs\mingw64
        perl Makefile.PL
        dmake
        dmake install
    ```
        
# Тестирование

1. Перейти в тестовый каталог:

    ```BASH
        cd %WEBGEAR%/tests
    ```
        
2. Выполнить тестирование сканера:

    ```BASH
        perl stest.pl
    ```
    
3. Выполнить тестирование парсера:

    ```BASH
        perl ptest.pl
    ```
        
4. Выполнить тестирование JSDOM:

    ```BASH
        perl jtest.pl -n dom-timers -x
    ```

   **ВНИМАНИЕ: в текущей реализации таймеры поддерживаются только для *NIX и
   тестируются только в многопроцессной версии**

    ```BASH
        perl jptest.pl
    ```
        
5. Выполнить тестирование DHTML:

    ```BASH
        perl dtest.pl        
    ```
---
_Copyright (C) 2017 Artem Novikov_
