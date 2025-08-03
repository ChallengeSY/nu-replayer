sub createSimFiles(SlotNum as short)
	dim as string SimDir = "games/-"+str(SlotNum)+"/1"
	mkdir("games/-"+str(SlotNum))
	mkdir(SimDir)
end sub
