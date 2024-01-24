#IFDEF __DOWNLOAD_TURNS__
type ParseHullDesign
	TechLevel as short
	HullName as string
	HullMass as integer
	NeuMax as integer
	Cargo as integer
	Crew as integer
	Engines as short
	BeamBanks as short
	TorpTubes as short
	FighterBays as short
	MegacreditCost as integer
	DuraniumCost as integer
	TritaniumCost as integer
	MolybdenumCost as integer
	AdvantageValue as short
end type

type ParsePartDesign
	TechLevel as short
	PartName as string
	PartMass as integer
	PartCost as integer
	DuraniumCost as integer
	TritaniumCost as integer
	MolybdenumCost as integer
	AmmoCost as integer
end type

sub fetchStaticData
	dim SendBuffer as string
	dim RecvBuffer as zstring * RECVBUFFLEN+1
	dim Bytes as integer
	
	dim as integer ObjIDa, ObjIDb, ObjCount, BlockChar(2), SeekChar(2)
	dim as string InStream, TargetFile(1)
	dim as ParseHullDesign InterHull
	dim as ParsePartDesign InterPart
	SendBuffer = loadAddress("static/all?compress=false")
	TargetFile(0) = "raw/staticData.txt"
	ErrorMsg = ""
	
	cls
	print "Fetching raw static data...";
	screencopy
	NuSocket = SDLNet_TCP_Open( @NuIP )
	if( NuSocket = 0 ) then
		ErrorMsg = "Nu Replayer did not successfully open a socket to Planets Nu's servers."
	else
		if SDLNet_TCP_Send(NuSocket, strptr(SendBuffer), len(SendBuffer)) < len(SendBuffer) then
			ErrorMsg = "Nu Replayer did not successfully send its request to Planets Nu's servers."
		else
			mkdir "raw"
			mkdir "raw/"+str(GameID)+""
			open TargetFile(0) for output as #4

			do
				Bytes = SDLNet_TCP_Recv( NuSocket, strptr( RecvBuffer ), RECVBUFFLEN )
				if( Bytes <= 0 ) then
					exit do
				end if

				'' add the null-terminator
				RecvBuffer[Bytes] = 0

				'' print it as string
				print #4, RecvBuffer;
			loop
			close #4
		end if
		
		if ErrorMsg = "" then
			open TargetFile(0) for input as #5
			do
				if eof(5) then
					ErrorMsg = "Nu Replayer could not successfully download the static data file due to lack of opening brace."
					exit do
				end if
				line input #5, InStream
			loop until left(InStream,1) = "{"
			close #5
		end if
		
		if instr(Instream,"{"+quote("success")+":false") then
			ErrorMsg = "Nu Replayer could not successfully download the static data file due to API error."
		elseif ErrorMsg = "" then
			cls
			print "Converting available hulls and parts...";
			ObjCount = 0
			screencopy

			'Hulls
			BlockChar(0) = instr(InStream,quote("hulls")+": [")
			if BlockChar(0) > 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				
				TargetFile(1) = "games/Default Shiplist.csv"
				open TargetFile(1) for output as #6
				print #6, quote("ID")+","+quote("Tech")+","+quote("Hull")+","+quote("Mass")+","+_
					quote("Ne")+","+quote("Car")+","+quote("Crew")+","+quote("En")+","+_
					quote("Bm")+","+quote("Tp")+","+quote("Ftr")+","+quote("mc")+","+_
					quote("Du")+","+quote("Tr")+","+quote("Mo")+","+quote("Adv")
				
				do
					with InterHull
						SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
						SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
						.HullName = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("duranium"))
						.DuraniumCost = valint(mid(InStream,SeekChar(0)+11,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("tritanium"))
						.TritaniumCost = valint(mid(InStream,SeekChar(0)+12,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("molybdenum"))
						.MolybdenumCost = valint(mid(InStream,SeekChar(0)+13,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("fueltank"))
						.NeuMax = valint(mid(InStream,SeekChar(0)+11,5))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("crew"))
						.Crew = valint(mid(InStream,SeekChar(0)+7,5))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("engines"))
						.Engines = valint(mid(InStream,SeekChar(0)+10,3))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("mass"))
						.HullMass = valint(mid(InStream,SeekChar(0)+7,5))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("techlevel"))
						.TechLevel = valint(mid(InStream,SeekChar(0)+12,3))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("cargo"))
						.Cargo = valint(mid(InStream,SeekChar(0)+8,5))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("fighterbays"))
						.FighterBays = valint(mid(InStream,SeekChar(0)+14,3))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("launchers"))
						.TorpTubes = valint(mid(InStream,SeekChar(0)+12,3))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("beams"))
						.BeamBanks = valint(mid(InStream,SeekChar(0)+8,3))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("cost"))
						.MegacreditCost = valint(mid(InStream,SeekChar(0)+7,6))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("advantage"))
						.AdvantageValue = valint(mid(InStream,SeekChar(0)+12,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
						ObjIDa = valint(mid(InStream,SeekChar(0)+5,5))
						
						print #6, ""& ObjIDa;","& .TechLevel;",";quote(.HullName);","& .HullMass; _
							","& .NeuMax;","& .Cargo;","& .Crew;","& .Engines;","& .BeamBanks; _
							","& .TorpTubes;","& .FighterBays;","& .MegacreditCost;","& .DuraniumCost; _
							","& .TritaniumCost;","& .MolybdenumCost;","& .AdvantageValue
					end with
					
					ObjCount += 1
					BlockChar(1) = instr(BlockChar(1) + len(ObjClose),InStream,ObjClose)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)
				close #6
			end if

			'The rest of the parts belong in one file
			TargetFile(1) = "games/Default Partlist.csv"
			open TargetFile(1) for output as #7
			print #7, quote("Category")+","+quote("ID")+","+quote("Tech")+","+quote("Part")+","+_
				quote("kT")+","+quote("mc")+","+quote("Du")+","+quote("Tr")+","+quote("Mo")

			'Engines
			BlockChar(0) = instr(InStream,quote("engines")+": [")
			if BlockChar(0) > 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				
				do
					with InterPart
						SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
						SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
						.PartName = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)
						
						.PartMass = 0
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("duranium"))
						.DuraniumCost = valint(mid(InStream,SeekChar(0)+11,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("tritanium"))
						.TritaniumCost = valint(mid(InStream,SeekChar(0)+12,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("molybdenum"))
						.MolybdenumCost = valint(mid(InStream,SeekChar(0)+13,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("techlevel"))
						.TechLevel = valint(mid(InStream,SeekChar(0)+12,3))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("cost"))
						.PartCost = valint(mid(InStream,SeekChar(0)+7,6))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
						ObjIDa = valint(mid(InStream,SeekChar(0)+5,5))
						
						print #7, quote("Engine")+","& ObjIDa;","& .TechLevel;",";quote(.PartName); _
							",0,"& .PartCost;","& .DuraniumCost;","& .TritaniumCost;","& .MolybdenumCost
					end with
					
					ObjCount += 1
					BlockChar(1) = instr(BlockChar(1) + len(ObjClose),InStream,ObjClose)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)
			end if

			'Beams
			BlockChar(0) = instr(InStream,quote("beams")+": [")
			if BlockChar(0) > 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				
				do
					with InterPart
						SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
						SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
						.PartName = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("mass"))
						.PartMass = valint(mid(InStream,SeekChar(0)+7,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("duranium"))
						.DuraniumCost = valint(mid(InStream,SeekChar(0)+11,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("tritanium"))
						.TritaniumCost = valint(mid(InStream,SeekChar(0)+12,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("molybdenum"))
						.MolybdenumCost = valint(mid(InStream,SeekChar(0)+13,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("techlevel"))
						.TechLevel = valint(mid(InStream,SeekChar(0)+12,3))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("cost"))
						.PartCost = valint(mid(InStream,SeekChar(0)+7,6))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
						ObjIDa = valint(mid(InStream,SeekChar(0)+5,5))
						
						print #7, quote("Beam")+","& ObjIDa;","& .TechLevel;",";quote(.PartName); _
							","& .PartMass;","& .PartCost;","& .DuraniumCost;","& .TritaniumCost;","& .MolybdenumCost
					end with
					
					ObjCount += 1
					BlockChar(1) = instr(BlockChar(1) + len(ObjClose),InStream,ObjClose)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)
			end if

			'Tubes and Torps
			BlockChar(0) = instr(InStream,quote("torpedosall")+": [")
			if BlockChar(0) > 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				
				do
					with InterPart
						SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
						SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
						.PartName = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("mass"))
						.PartMass = valint(mid(InStream,SeekChar(0)+7,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("duranium"))
						.DuraniumCost = valint(mid(InStream,SeekChar(0)+11,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("tritanium"))
						.TritaniumCost = valint(mid(InStream,SeekChar(0)+12,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("molybdenum"))
						.MolybdenumCost = valint(mid(InStream,SeekChar(0)+13,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("techlevel"))
						.TechLevel = valint(mid(InStream,SeekChar(0)+12,3))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("launchercost"))
						.PartCost = valint(mid(InStream,SeekChar(0)+15,5))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("torpedocost"))
						.AmmoCost = valint(mid(InStream,SeekChar(0)+14,5))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
						ObjIDa = valint(mid(InStream,SeekChar(0)+5,5))
						
						print #7, quote("Tube")+","& ObjIDa;","& .TechLevel;",";quote(.PartName); _
							","& .PartMass;","& .PartCost;","& .DuraniumCost;","& .TritaniumCost;","& .MolybdenumCost

						print #7, quote("Torp")+","& ObjIDa;","& .TechLevel;",";quote(.PartName); _
							",1,"& .AmmoCost;",1,1,1"
					end with
					
					ObjCount += 1
					BlockChar(1) = instr(BlockChar(1) + len(ObjClose),InStream,ObjClose)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)
			end if
			
			close #7
		end if
	end if
	
	SDLNet_TCP_Close( NuSocket )
	if ErrorMsg <> "" then
		print " Failure! ";ErrorMsg
		screencopy
		sleep
	end if
end sub
#ENDIF
