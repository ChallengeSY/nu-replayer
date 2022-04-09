FBC=fbc #compiler
TARGET=NuReplay #target file

all:
	$(FBC) -x $(TARGET) -s gui NuReplay.bas
	
clean:
	rm *.o $(TARGET)
