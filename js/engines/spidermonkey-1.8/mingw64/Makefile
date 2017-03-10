CC = gcc -D_WIN32 -DXP_WIN -DEXPORT_JS_API -DJS_C_STRINGS_ARE_UTF8 -DJS_THREADSAFE

EXCLUDE = jsstddef.h jskwgen.c jsdtracef.h jsdtracef.c js.c
SOURCES = $(filter-out $(EXCLUDE), $(wildcard *.c))
HEADERS = $(filter-out $(EXCLUDE), $(wildcard *.h))

# библиотека libwinmm.a нужна для timeBeginPeriod(1) из prmjtime.c

all: js.exe jsd.exe libjs.a libjsd.a 

js.exe: libjs.a
	$(CC) -o $@ js.c libjs.a -lwinmm

jsd.exe: libjsd.a
	$(CC) -o $@ js.c libjsd.a -lwinmm    
    
libjs.a: jsautokw.h $(HEADERS) $(SOURCES)
	$(CC) -c $(SOURCES)
	ar rcs $@ $(SOURCES:.c=.o)
	del *.o
 
libjsd.a: jsautokw.h $(HEADERS) $(SOURCES)
	$(CC) -DEBUG -c $(SOURCES)
	ar rcs $@ $(SOURCES:.c=.o)
	del *.o
 
jsautokw.h: jskwgen.c 
	$(CC) -o jskwgen.exe jskwgen.c  
	jskwgen.exe > jsautokw.h 

clean:
	del *.a *.exe

reset:
	del jsautokw.h *.o *.a *.exe 