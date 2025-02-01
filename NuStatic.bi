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
	
	WarpEfficiency(9) as integer
	
	WepKill as short
	WepBlast as short
	Range as integer
end type

sub fetchStaticData
	dim SendBuffer as string
	dim RecvBuffer as zstring * RECVBUFFLEN+1
	dim Bytes as integer
	
	dim as integer ObjIDa, ObjIDb, ObjCount, BlockChar(2)
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
						.HullName = getJsonStr(InStream,"name",BlockChar(1))
						
						.HullName = findReplace(.HullName, "Class Torpedo ", "")
						.HullName = findReplace(.HullName, "Class ", "")
						.HullName = findReplace(.HullName, "Deep Space Freighter", "Freighter")
						if .HullName = "Bloodfang" then
							.HullName = "Bloodfang Stealth Carrier"
						end if
						
						.DuraniumCost = getJsonVal(InStream,"duranium",BlockChar(1))
						.TritaniumCost = getJsonVal(InStream,"tritanium",BlockChar(1))
						.MolybdenumCost = getJsonVal(InStream,"molybdenum",BlockChar(1))
						
						.NeuMax = getJsonVal(InStream,"fueltank",BlockChar(1))
						.Crew = getJsonVal(InStream,"crew",BlockChar(1))
						.Engines = getJsonVal(InStream,"engines",BlockChar(1))
						
						.HullMass = getJsonVal(InStream,"mass",BlockChar(1))
						.TechLevel = getJsonVal(InStream,"techlevel",BlockChar(1))
						.Cargo = getJsonVal(InStream,"cargo",BlockChar(1))
						
						.FighterBays = getJsonVal(InStream,"fighterbays",BlockChar(1))
						.TorpTubes = getJsonVal(InStream,"launchers",BlockChar(1))
						.BeamBanks = getJsonVal(InStream,"beams",BlockChar(1))
						
						.MegacreditCost = getJsonVal(InStream,"cost",BlockChar(1))
						.AdvantageValue = getJsonVal(InStream,"advantage",BlockChar(1))
						ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
						
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
				quote("kT")+","+quote("mc")+","+quote("Du")+","+quote("Tr")+","+quote("Mo")+","+_
				quote("Kill")+","+quote("Dmg")+","+quote("Range")+","+quote("W1")+","+quote("W2")+","+_
				quote("W3")+","+quote("W4")+","+quote("W5")+","+quote("W6")+","+quote("W7")+","+quote("W8")+","+quote("W9")

			'Engines
			BlockChar(0) = instr(InStream,quote("engines")+": [")
			if BlockChar(0) > 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				
				do
					with InterPart
						.PartName = getJsonStr(InStream,"name",BlockChar(1))
						.PartMass = 0
						
						.DuraniumCost = getJsonVal(InStream,"duranium",BlockChar(1))
						.TritaniumCost = getJsonVal(InStream,"tritanium",BlockChar(1))
						.MolybdenumCost = getJsonVal(InStream,"molybdenum",BlockChar(1))
						
						.TechLevel = getJsonVal(InStream,"techlevel",BlockChar(1))
						.PartCost = getJsonVal(InStream,"cost",BlockChar(1))
						
						for WID as byte = 1 to 9
							.WarpEfficiency(WID) = getJsonVal(InStream,"warp"+str(WID),BlockChar(1))
						next WID
						
						ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
						
						print #7, quote("Engine")+","& ObjIDa;","& .TechLevel;",";quote(.PartName); _
							",0,"& .PartCost;","& .DuraniumCost;","& .TritaniumCost;","& .MolybdenumCost;",0,0,0";
						
						for WID as byte = 1 to 9
							if WID < 9 then
								print #7, ","& .WarpEfficiency(WID);
							else
								print #7, ","& .WarpEfficiency(WID)
							end if
						next WID
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
						.PartName = getJsonStr(InStream,"name",BlockChar(1))
						.PartMass = getJsonVal(InStream,"mass",BlockChar(1))
						
						.DuraniumCost = getJsonVal(InStream,"duranium",BlockChar(1))
						.TritaniumCost = getJsonVal(InStream,"tritanium",BlockChar(1))
						.MolybdenumCost = getJsonVal(InStream,"molybdenum",BlockChar(1))
						
						.TechLevel = getJsonVal(InStream,"techlevel",BlockChar(1))
						.PartCost = getJsonVal(InStream,"cost",BlockChar(1))
						
						.WepKill = getJsonVal(InStream,"crewkill",BlockChar(1))
						.WepBlast = getJsonVal(InStream,"damage",BlockChar(1))
						.Range = 200
						
						ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
						
						print #7, quote("Beam")+","& ObjIDa;","& .TechLevel;",";quote(.PartName); _
							","& .PartMass;","& .PartCost;","& .DuraniumCost;","& .TritaniumCost;","& .MolybdenumCost; _
							","& .WepKill;","& .WepBlast;","& .Range
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
						.PartName = getJsonStr(InStream,"name",BlockChar(1))
						.PartMass = getJsonVal(InStream,"mass",BlockChar(1))
						
						.DuraniumCost = getJsonVal(InStream,"duranium",BlockChar(1))
						.TritaniumCost = getJsonVal(InStream,"tritanium",BlockChar(1))
						.MolybdenumCost = getJsonVal(InStream,"molybdenum",BlockChar(1))
						
						.TechLevel = getJsonVal(InStream,"techlevel",BlockChar(1))
						.PartCost = getJsonVal(InStream,"launchercost",BlockChar(1))
						.AmmoCost = getJsonVal(InStream,"torpedocost",BlockChar(1))
						
						.WepKill = getJsonVal(InStream,"crewkill",BlockChar(1))
						.WepBlast = getJsonVal(InStream,"damage",BlockChar(1))
						.Range = getJsonVal(InStream,"combatrange",BlockChar(1))
						
						ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
						
						print #7, quote("Tube")+","& ObjIDa;","& .TechLevel;",";quote(.PartName); _
							","& .PartMass;","& .PartCost;","& .DuraniumCost;","& .TritaniumCost;","& .MolybdenumCost; _
							","& .WepKill;","& .WepBlast;","& .Range

						print #7, quote("Torp")+","& ObjIDa;","& .TechLevel;",";quote(.PartName); _
							",1,"& .AmmoCost;",1,1,1,"& .WepKill;","& .WepBlast;","& .Range
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
