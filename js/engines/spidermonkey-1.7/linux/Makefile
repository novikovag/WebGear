CC = gcc -DXP_UNIX -DHAVE_VA_COPY -DVA_COPY=va_copy -DPIC -fPIC -DEXPORT_JS_API -DJS_C_STRINGS_ARE_UTF8

EXCLUDE = ../jsstddef.h ../jsautokw.h ../jskwgen.c ../js.c
SOURCES = $(filter-out $(EXCLUDE), $(wildcard ../*.c))

all: ../jsautocfg.h ../jsautokw.h libjs.a js

../jsautocfg.h:
	$(CC) -o jscpucfg ../jscpucfg.c
	./jscpucfg > ../jsautocfg.h

../jsautokw.h:  
	$(CC) -o jskwgen ../jskwgen.c 
	./jskwgen ../jsautokw.h
    
libjs.a: $(SOURCES)
	$(CC) -c $^
	ar rcs $@ $(addsuffix .o, $(basename $(notdir $^)))
	rm -f jscpucfg jskwgen *.o 
    
js: libjs.a
	$(CC) -o $@ ../js.c libjs.a -lm -lc   
    
clean:
	rm -f ../jsautocfg.h ../jsautokw.h ./jscpucfg ./jskwgen *.o *.a