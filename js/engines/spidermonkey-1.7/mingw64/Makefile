CC = gcc -D_WIN32 -DXP_WIN -DEXPORT_JS_API -DJS_C_STRINGS_ARE_UTF8

EXCLUDE = ../jsstddef.h ../jsautokw.h ../jskwgen.c ../js.c
SOURCES = $(filter-out $(EXCLUDE), $(wildcard ../*.c))

all: ../jsautokw.h libjs.a js.exe 

../jsautokw.h:  
	$(CC) -o jskwgen.exe ../jskwgen.c 
	jskwgen.exe > ../jsautokw.h
    
libjs.a: $(SOURCES)
	$(CC) -c $^
	ar rcs $@ $(addsuffix .o, $(basename $(notdir $^)))
	del jskwgen.exe *.o
    
js.exe: libjs.a
	$(CC) -o $@ ../js.c libjs.a    
    
clean:
	del /Q ..\jsautokw.h* *.o *.a *.exe
    