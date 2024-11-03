FBC=fbc #compiler
MAINAPP=NuReplay
CONVERTOR=MassTurn

all:
	$(FBC) -x $(MAINAPP) -s gui $(MAINAPP).bas
	$(FBC) -x $(CONVERTOR) -s gui $(CONVERTOR).bas
	
clean:
	rm *.o $(TARGET)
