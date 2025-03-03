#IFNDEF __LOADTURN_BI__
#DEFINE __LOADTURN_BI__
#include "WordWrap.bi"
#include "vbcompat.bi"

#include "NRCommon.bi"
#include "ParseData.bas"

const ArrayClose = "}],"
const ObjClose = "},"

#IFNDEF __DOWNLOAD_TURNS__
dim shared as string ErrorMsg
#ENDIF

function loadTurn(GameNum as integer, TurnNum as short, PrintTxt as byte = 1) as byte
	randomize timer
	
	dim as string InStream, ObjName, ObjCode, RawPath, LoadFile
	dim as integer ObjIDa, ObjIDb, RelateID, StorageID, CombatID, ErrorLog, BlockChar(2), SeekChar
	dim as byte RaceType
	dim as double ParseStart, ParseEnd

	mkdir("games/"+str(GameNum))
	mkdir("games/"+str(GameNum)+"/"+str(TurnNum))
	RawPath = "raw/"+str(GameNum)

	for ObjIDa = 1 to LimitObjs
		PlanetParser(ObjIDa) = ResetPlanPar
		ShipParser(ObjIDa) = ResetShipPar
		BaseParser(ObjIDa) = ResetBasePar
		
		IonParser(ObjIDa) = ResetIonPar
		StarParser(ObjIDa) = ResetStarPar
		NebParser(ObjIDa) = ResetNebPar
		
		ArtifactParser(ObjIDa) = ResetArtifactPar
		WormholeParser(ObjIDa) = ResetWormholePar
		RelateParser(ObjIDa) = ResetRelationsPar
		VCRParser(ObjIDa) = ResetVCRPar
	next
	
	for MetaID as integer = 1 to MetaLimit
		StockParser(MetaID) = ResetStockPar
		MinefParser(MetaID) = ResetMinefPar
	next MetaID
	
	InterShip.ShipOwner = 0
	
	for PlrID as ubyte = 1 to 35
		ProcessSlot(PlrID) = ResetSlotPar
	next PlrID

	ParseStart = timer
	RelateID = 1
	StorageID = 1
	CombatID = 1
	
	ErrorLog = open("logs/LT"+str(irandom(0,999999))+".log" for output as #9)
	if PrintTxt then
		print "Data will be exported for game #"& GameNum;" turn "& TurnNum;"."
	end if
	
	open "games/"+str(GameNum)+"/"+str(TurnNum)+"/Working" for output as #10
	close #10 
	
	GameParser = ResetGamePar

	print #9, "[";Time;", ";Date;"] Data will be exported for game #"& GameNum;" turn "& TurnNum;"."
	if FileExists("games/"+str(GameNum)+"/Settings.csv") then
		open "games/"+str(GameNum)+"/Settings.csv" for input as #5
		with GameParser
			.DynamicMap = 0
			
			do
				input #5, InStream
				select case InStream
					case "Players"
						input #5, .PlayerCount
					case "Width"
						input #5, .MapWidth
					case "Height"
						input #5, .MapHeight
					case "Academy"
						input #5, .Academy
					case "Dynamic"
						input #5, .DynamicMap
					case "AccelStart"
						input #5, .AccelStart
				end select
			loop until eof(5)
		end with
		close #5
	end if

	with GameParser
		MinXPos = 2000 - .MapWidth/2
		MaxXPos = MinXPos + .MapWidth
		MinYPos = 2000 - .MapHeight/2
		MaxYPos = MinYPos + .MapHeight
	end with

	if PrintTxt then
		print "Converting players...";
	end if
	loadTurnUI(0)
	
	for PID as ubyte = 1 to 35
		LoadFile = RawPath+"/player"+str(PID)+"-turn"+str(TurnNum)+".trn"
		if FileExists(LoadFile) = 0 then
			LoadFile = RawPath+"/"+str(TurnNum)+"/loadturn"+str(PID)
			if FileExists(LoadFile) = 0 then
				LoadFile = LoadFile + ".txt"
			end if
		end if
		
		if PID > 1 AND PID > GameParser.PlayerCount then
			exit for
		else
			if FileExists(LoadFile) = 0 then
				with ProcessSlot(PID)
					.RaceType = "Unassigned"
					.Namee = "open"
					.TotalShips = 0
					.Freighters = 0
					.Planets = 0
					.Bases = 0
					.Military = 0
					.StockDu = 0
					.StockTr = 0
					.StockMo = 0
					.StockCr = 0
				end with
				continue for
			end if
		end if
		print #9, "[";Time;", ";Date;"] Converting Player "& PID;"'s data from ";LoadFile;"..."

		open LoadFile for input as #1
		do
			line input #1, InStream
		loop until left(InStream,11) = "{"+quote("success")+":" OR eof(1)
		close #1

		if mid(InStream,12,5) = "false" then
			ProcessSlot(PID).Namee = quote("error")
			ProcessSlot(PID).RaceType = "Unknown"
		else
			'In case the Settings.csv file doesn't exist, convert settings from here
			BlockChar(0) = instr(InStream,quote("settings")+": {")
							
			if BlockChar(0) > 0 then
				BlockChar(1) = instr(BlockChar(0),InStream,ObjClose)

				with GameParser
					if PID = 1 AND FileExists("player1-turn"+str(TurnNum+1)+".trn") = 0 then
						.PlayerCount = getJsonVal(InStream,"slots",BlockChar(0))
						.MapWidth = getJsonVal(InStream,"mapwidth",BlockChar(0))
						.MapHeight = getJsonVal(InStream,"mapheight",BlockChar(0))
						
						.CloudyIonStorms = getJsonBool(InStream,"nuionstorms",BlockChar(0))
						.Sphere = getJsonBool(InStream,"sphere",BlockChar(0),BlockChar(1))
						.Academy = getJsonBool(InStream,"isacademy",BlockChar(0),BlockChar(1))
						.AccelStart = getJsonVal(InStream,"acceleratedturns",BlockChar(0))
						.TorpSet = getJsonVal(InStream,"torpedoset",BlockChar(0))
						
						MinXPos = 2000 - .MapWidth/2
						MaxXPos = MinXPos + .MapWidth
						MinYPos = 2000 - .MapHeight/2
						MaxYPos = MinYPos + .MapHeight
						
						if cmdLine("--verbose") then
							print "Acquired game settings for game "& GameNum 
						end if
						
					end if
					
					.CampaignGame = getJsonBool(InStream,"campaignmode",BlockChar(0),BlockChar(1))
				end with
				
				loadTurnKB(int(BlockChar(1)/1e3),PID)
			end if
			
			'Convert player data
			BlockChar(0) = instr(InStream,quote("player")+": {")
			if BlockChar(0) > 0 then
				BlockChar(1) = instr(BlockChar(0),InStream,ObjClose)
				
				with ProcessSlot(PID)
					RaceType = getJsonVal(InStream,"raceid",BlockChar(0))
					.Namee = getJsonStr(InStream,"username",BlockChar(0))

					'Academy resources
					.StockDu = getJsonVal(InStream,"duranium",BlockChar(0))
					.StockTr = getJsonVal(InStream,"tritanium",BlockChar(0))
					.StockMo = getJsonVal(InStream,"molybdenum",BlockChar(0))
					.StockCr = getJsonVal(InStream,"megacredits",BlockChar(0))

					select case RaceType
						case 1
							.RaceType = "Fed"
						case 2
							.RaceType = "Lizard"
						case 3
							.RaceType = "Bird Man"
						case 4
							.RaceType = "Fascist"
						case 5
							.RaceType = "Privateer"
						case 6
							.RaceType = "Cyborg"
						case 7
							.RaceType = "Crystalline"
						case 8
							.RaceType = "Empire"
						case 9
							.RaceType = "Robotic"
						case 10
							.RaceType = "Rebel"
						case 11
							.RaceType = "Colonial"
						case 12
							.RaceType = "Horwasp"
						case else
							.RaceType = "Unassigned"
					end select
				end with
				
				if cmdLine("--verbose") then
					print "Acquired player data for player "& PID 
				end if
				
				loadTurnKB(int(BlockChar(1)/1e3),PID)
			end if
			
			'Score data
			BlockChar(0) = instr(InStream,quote("scores")+": [")
			if BlockChar(0) > 0 then
				BlockChar(1) = instr(BlockChar(0),InStream,ArrayClose)
				
				SeekChar = instr(BlockChar(0),InStream,quote("ownerid")+":"+str(PID))
				if SeekChar < BlockChar(1) then
					with ProcessSlot(PID)
						'Starships
						.TotalShips = getJsonVal(InStream,"capitalships",SeekChar)
						.Freighters = getJsonVal(InStream,"freighters",SeekChar)
						.TotalShips += .Freighters
						
						'Planets/Bases/Military
						.Planets = getJsonVal(InStream,"planets",SeekChar)
						.Bases = getJsonVal(InStream,"starbases",SeekChar)
						.Military = getJsonVal(InStream,"militaryscore",SeekChar)
					end with
				end if
				
				if cmdLine("--verbose") then
					print "Acquired score data for player "& PID 
				end if
				
				loadTurnKB(int(BlockChar(1)/1e3),PID)
			end if
			
			'Planet data
			BlockChar(0) = instr(InStream,quote("planets")+": [")
			if BlockChar(0) > 0 AND instr(InStream,quote("planets")+": []") = 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				do
					with InterPlan
						'Coordinates
						.XLoc = getJsonVal(InStream,"x",BlockChar(1))
						.YLoc = getJsonVal(InStream,"y",BlockChar(1))
						
						'Colony info
						.PlanName = findReplace(getJsonStr(InStream,"name",BlockChar(1)),",","&")
						.FriendlyCode = findReplace(getJsonStr(InStream,"friendlycode",BlockChar(1)),",","&")
						
						.PlanetOwner = getJsonVal(InStream,"ownerid",BlockChar(1))
						.Colonists = getJsonVal(InStream,"clans",BlockChar(1))
						.ColTaxes = getJsonVal(InStream,"colonisttaxrate",BlockChar(1))
						.ColHappy = getJsonVal(InStream,"colonisthappypoints",BlockChar(1))
						
						.Temp = getJsonVal(InStream,"temp",BlockChar(1))
						.LastScan = getJsonVal(InStream,"infoturn",BlockChar(1))
						
						'Native info
						.Natives = getJsonVal(InStream,"nativeclans",BlockChar(1))
						.NatTaxes = getJsonVal(InStream,"nativetaxrate",BlockChar(1))
						.NatHappy = getJsonVal(InStream,"nativehappypoints",BlockChar(1))
						.NativeType = getJsonVal(InStream,"nativetype",BlockChar(1))
						.NativeGov = getJsonVal(InStream,"nativegovernment",BlockChar(1))
						
						'Surface minerals
						.Neu = getJsonVal(InStream,"neutronium",BlockChar(1))
						.Dur = getJsonVal(InStream,"duranium",BlockChar(1))
						.Trit = getJsonVal(InStream,"tritanium",BlockChar(1))
						.Moly = getJsonVal(InStream,"molybdenum",BlockChar(1))
						
						'Mineable minerals
						.GNeu = getJsonVal(InStream,"groundneutronium",BlockChar(1))
						.GDur = getJsonVal(InStream,"groundduranium",BlockChar(1))
						.GTrit = getJsonVal(InStream,"groundtritanium",BlockChar(1))
						.GMoly = getJsonVal(InStream,"groundmolybdenum",BlockChar(1))
						
						'Mineral densities
						.DNeu = getJsonVal(InStream,"densityneutronium",BlockChar(1))
						.DDur = getJsonVal(InStream,"densityduranium",BlockChar(1))
						.DTrit = getJsonVal(InStream,"densitytritanium",BlockChar(1))
						.DMoly = getJsonVal(InStream,"densitymolybdenum",BlockChar(1))
						
						'Structural info
						.Megacredits = getJsonVal(InStream,"megacredits",BlockChar(1))
						.Supplies = getJsonVal(InStream,"supplies",BlockChar(1))
						.MineralMines = getJsonVal(InStream,"mines",BlockChar(1))
						.Factories = getJsonVal(InStream,"factories",BlockChar(1))
						.DefPosts = getJsonVal(InStream,"defense",BlockChar(1))
						
						.Asteroid = getJsonVal(InStream,"debrisdisk",BlockChar(1))
					end with
					
					with InterWasp
						.WorkMine = getJsonVal(InStream,"targetmines",BlockChar(1))
						.WorkHarvest = getJsonVal(InStream,"targetfactories",BlockChar(1))
						.WorkBurrow = getJsonVal(InStream,"targetdefense",BlockChar(1))
						.WorkTerraform = getJsonVal(InStream,"builtmines",BlockChar(1))
						.Larva = getJsonVal(InStream,"larva",BlockChar(1))
						.BurrowSize = getJsonVal(InStream,"burrowsize",BlockChar(1))
						
						.PodHull = getJsonVal(InStream,"podhullid",BlockChar(1))
						.PodCargo = getJsonVal(InStream,"podcargo",BlockChar(1))
						.PodX = getJsonVal(InStream,"targetx",BlockChar(1))
						.PodY = getJsonVal(InStream,"targety",BlockChar(1))
						.PodWarp = getJsonVal(InStream,"podspeed",BlockChar(1))
					end with
					
					ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
					
					if (cmdLine("--verbose") OR cmdLine("-vp")) AND InterPlan.PlanetOwner > 0 then
						print "Identified planet #"& ObjIDa;" as belonging to player "& InterPlan.PlanetOwner
					end if
					
					WaspParser(ObjIDa) = InterWasp
					
					if InterPlan.PlanetOwner = PID then
						with PlanetParser(ObjIDa)
							if .LockOwner = 0 OR (InterPlan.Colonists > .Colonists AND TurnNum < GameParser.AccelStart) then
								print #9, "[";Time;", ";Date;"]  Registered planet #"& ObjIDa;" (";ObjName;")"
								PlanetParser(ObjIDa) = InterPlan
								WaspParser(ObjIDa) = InterWasp
								
								.LockOwner = 1
								.LastScan = TurnNum
							end if
						end with
					else
						with PlanetParser(ObjIDa)
							if .LockOwner = 0 then
								.PlanetOwner = 0
								.PlanName = InterPlan.PlanName
								.FriendlyCode = InterPlan.FriendlyCode
								.LastScan = max(InterPlan.LastScan, .LastScan)
								.Asteroid = InterPlan.Asteroid
	
								.XLoc = InterPlan.XLoc
								.YLoc = InterPlan.YLoc

								.Colonists = InterPlan.Colonists
								.ColTaxes = InterPlan.ColTaxes
								.ColHappy = InterPlan.ColHappy
								
								if InterPlan.Temp >= 0 AND InterPlan.LastScan >= .NativesUpdated then
									.NativesUpdated = InterPlan.LastScan
									.Natives = InterPlan.Natives
									.NatTaxes = InterPlan.NatTaxes
									.NatHappy = InterPlan.NatHappy
									.NativeType = InterPlan.NativeType
									.Temp = InterPlan.Temp
								end if
								
								if InterPlan.DNeu >= 0 AND InterPlan.DDur >= 0 AND InterPlan.DTrit >= 0 AND InterPlan.DMoly >= 0 AND _
									InterPlan.LastScan >= .MineralsUpdated then
									.NativeGov = InterPlan.NativeGov
									.MineralsUpdated = InterPlan.LastScan
									.Neu = InterPlan.Neu
									.Dur = InterPlan.Dur
									.Trit = InterPlan.Trit
									.Moly = InterPlan.Moly
									.GNeu = InterPlan.GNeu
									.GDur = InterPlan.GDur
									.GTrit = InterPlan.GTrit
									.GMoly = InterPlan.GMoly
									.DNeu = InterPlan.DNeu
									.DDur = InterPlan.DDur
									.DTrit = InterPlan.DTrit
									.DMoly = InterPlan.DMoly
								end if
								
								if InterPlan.Megacredits >= 0 AND InterPlan.Supplies >= 0 AND InterPlan.LastScan >= .MoneyUpdated then
									.MoneyUpdated = InterPlan.LastScan
									.Megacredits = InterPlan.Megacredits
									.Supplies = InterPlan.Supplies
								end if
								
								if InterPlan.MineralMines >= 0 AND InterPlan.Factories >= 0 AND InterPlan.LastScan >= .BuildingsUpdated then
									.BuildingsUpdated = InterPlan.LastScan
									.MineralMines = InterPlan.MineralMines
									.Factories = InterPlan.Factories
									.DefPosts = InterPlan.DefPosts
								end if
							end if
						end with
					end if
					BlockChar(1) = instr(BlockChar(1) + len(ObjClose),InStream,ObjClose)
					loadTurnKB(int(BlockChar(1)/1e3),PID)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)
			end if
			
			'Ship data
			BlockChar(0) = instr(InStream,quote("ships")+": [")
			if BlockChar(0) > 0 AND instr(InStream,quote("ships")+": []") = 0 then
				'History and Waypoints are array-ized, so ion storms is explicit for safety reasons
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose+quote("ionstorms"))
				BlockChar(1) = BlockChar(0)
				
				/'
				 ' Additionally, History and Waypoints blocks have been notorious troublemakers,
				 ' so additional exceptions are being added on top of this.
				 '/
				dim as integer HistoryBlock(1), WaypointsBlock(1)
				
				do
					HistoryBlock(0) = instr(BlockChar(1),InStream,quote("history")+":[")
					HistoryBlock(1) = instr(HistoryBlock(0),InStream,"]")
					WaypointsBlock(0) = instr(BlockChar(1),InStream,quote("waypoints")+":[")
					WaypointsBlock(1) = instr(WaypointsBlock(0),InStream,"]")
						
					with InterShip
						'Coordinates
						SeekChar = instr(BlockChar(1),InStream,quote("x"))
						if HistoryBlock(0) > 0 AND SeekChar > HistoryBlock(0) then
							SeekChar = instr(HistoryBlock(1),InStream,quote("x"))
						end if
						.XLoc = valint(mid(InStream,SeekChar+4,4))
						SeekChar = instr(BlockChar(1),InStream,quote("y"))
						if HistoryBlock(0) > 0 AND SeekChar > HistoryBlock(0) then
							SeekChar = instr(HistoryBlock(1),InStream,quote("y"))
						end if
						.YLoc = valint(mid(InStream,SeekChar+4,4))
						
						.TargetX = getJsonVal(InStream,"targetx",BlockChar(1))
						.TargetY = getJsonVal(InStream,"targety",BlockChar(1))
						.WarpFactor = getJsonVal(InStream,"warp",BlockChar(1))
						
						'Basic info
						.ShipName = findReplace(getJsonStr(InStream,"name",BlockChar(1)),",","&")
						.FriendlyCode = findReplace(getJsonStr(InStream,"friendlycode",BlockChar(1)),",","&")
						.ShipType = getJsonVal(InStream,"hullid",BlockChar(1))
						.ShipOwner = getJsonVal(InStream,"ownerid",BlockChar(1))
						.TotalMass = getJsonVal(InStream,"mass",BlockChar(1))
						
						'Equipment
						.EngineID = getJsonVal(InStream,"engineid",BlockChar(1))
						.BeamID = getJsonVal(InStream,"beamid",BlockChar(1))
						.BeamCount = getJsonVal(InStream,"beams",BlockChar(1))
						.BayCount = getJsonVal(InStream,"bays",BlockChar(1))
						.TubeID = getJsonVal(InStream,"torpedoid",BlockChar(1))
						.TubeCount = getJsonVal(InStream,"torps",BlockChar(1))
						
						'Mission
						.Mission = getJsonVal(InStream,"mission",BlockChar(1))
						.MisnTarget(1) = getJsonVal(InStream,"mission1target",BlockChar(1))
						.MisnTarget(2) = getJsonVal(InStream,"mission2target",BlockChar(1))
						.PrimEnemy = getJsonVal(InStream,"enemy",BlockChar(1))
						
						'Cargo Hold
						.Colonists = getJsonVal(InStream,"clans",BlockChar(1))
						.Neu = getJsonVal(InStream,"neutronium",BlockChar(1))
						.Dur = getJsonVal(InStream,"duranium",BlockChar(1))
						.Trit = getJsonVal(InStream,"tritanium",BlockChar(1))
						.Moly = getJsonVal(InStream,"molybdenum",BlockChar(1))
						.Megacredits = getJsonVal(InStream,"megacredits",BlockChar(1))
						.Supplies = getJsonVal(InStream,"supplies",BlockChar(1))
						
						'Ship Status
						.Damage = getJsonVal(InStream,"damage",BlockChar(1))
						.Crewmen = getJsonVal(InStream,"crew",BlockChar(1))
						.Infection = getJsonVal(InStream,"podcargo",BlockChar(1),,0)
						.Ordnance = getJsonVal(InStream,"ammo",BlockChar(1))
						.Experience = getJsonVal(InStream,"experience",BlockChar(1))
						.Cloaked = getJsonBool(InStream,"iscloaked",BlockChar(1))
					end with
					
					ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
					
					if (cmdLine("--verbose") OR cmdLine("-vs")) AND InterShip.ShipOwner > 0 then
						print "Identified ship #"& ObjIDa;" as belonging to player "& InterShip.ShipOwner
					end if
					
					if InterShip.ShipOwner = PID then
						if ShipParser(ObjIDa).LockOwner = 0 then
							ShipParser(ObjIDa) = InterShip
							ShipParser(ObjIDa).LockOwner = 1
							InterShip.Cloaked = 0

							print #9, "[";Time;", ";Date;"]  Registered ship #"& ObjIDa;" (";ObjName;")"
						end if
					end if
					
					BlockChar(1) = instr(max(HistoryBlock(1), max(WaypointsBlock(1), BlockChar(1)+len(ObjClose))) ,InStream,ObjClose)
					loadTurnKB(int(BlockChar(1)/1e3),PID)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
			end if
			
			'Ion Storms data. Only read this if the first player
			if PID = 1 then
				BlockChar(0) = instr(InStream,quote("ionstorms")+": [")
				if BlockChar(0) > 0 AND instr(InStream,quote("ionstorms")+": []") = 0 then
					BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
					BlockChar(1) = BlockChar(0)
					do
						with InterIon
							'Coordinates
							.XLoc = getJsonVal(InStream,"x",BlockChar(1))
							.YLoc = getJsonVal(InStream,"y",BlockChar(1))
							
							'Storm info
							.Radius = getJsonVal(InStream,"radius",BlockChar(1))
							.Voltage = getJsonVal(InStream,"voltage",BlockChar(1))
							.WarpFactor = getJsonVal(InStream,"warp",BlockChar(1))
							.StormHeading = getJsonVal(InStream,"heading",BlockChar(1))
							.StormGrowing = getJsonBool(InStream,"isgrowing",BlockChar(1))
							.ParentID = getJsonVal(InStream,"parentid",BlockChar(1))
							ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
						end with
	
						if cmdLine("--verbose") OR cmdLine("-vi") then
							print "Identified ion storm #"& ObjIDa
						end if

						print #9, "[";Time;", ";Date;"]  Registered ion storm #"& ObjIDa
						IonParser(ObjIDa) = InterIon
						
						BlockChar(1) = instr(BlockChar(1)+len(ObjClose),InStream,ObjClose)
						loadTurnKB(int(BlockChar(1)/1e3),PID)
					loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
				end if
			end if
			
			'Nebulae data. Only read this if non-existant or outdated
			if PID = 1 AND (FileExists("games/"+str(GameNum)+"/Nebulae.csv") = 0 OR _
				FileDateTime("games/"+str(GameNum)+"/Nebulae.csv") < DataFormat) then
				BlockChar(0) = instr(InStream,quote("nebulas")+": [")
				if BlockChar(0) > 0 AND instr(InStream,quote("nebulas")+": []") = 0 then
					BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
					BlockChar(1) = BlockChar(0)
					do
						with InterNeb
							.NebName = getJsonStr(InStream,"name",BlockChar(1))
							.XLoc = getJsonVal(InStream,"x",BlockChar(1))
							.YLoc = getJsonVal(InStream,"y",BlockChar(1))
							
							.Radius = getJsonVal(InStream,"radius",BlockChar(1))
							.Intense = getJsonVal(InStream,"intensity",BlockChar(1))
							.Gas = getJsonVal(InStream,"gas",BlockChar(1))
						end with
						
						ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
						
						if cmdLine("--verbose") OR cmdLine("-vn") then
							print "Identified a part of nebulae #"& ObjIDa
						end if

						print #9, "[";Time;", ";Date;"] Registered a part of nebula #"& ObjIDa
						NebParser(ObjIDa) = InterNeb
						
						BlockChar(1) = instr(BlockChar(1)+len(ObjClose),InStream,ObjClose)
						loadTurnKB(int(BlockChar(1)/1e3),PID)
					loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
				end if
			end if
			
			'Star Cluster data. Only read this if non-existant or outdated
			if PID = 1 AND (FileExists("games/"+str(GameNum)+"/StarClusters.csv") = 0 OR _
				FileDateTime("games/"+str(GameNum)+"/StarClusters.csv") < DataFormat) then
				BlockChar(0) = instr(InStream,quote("stars")+": [")
				if BlockChar(0) > 0 AND instr(InStream,quote("stars")+": []") = 0 then
					BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
					BlockChar(1) = BlockChar(0)
					do
						with InterStar
							.ClustName = getJsonStr(InStream,"name",BlockChar(1))
							.XLoc = getJsonVal(InStream,"x",BlockChar(1))
							.YLoc = getJsonVal(InStream,"y",BlockChar(1))
							
							.Temp = getJsonVal(InStream,"temp",BlockChar(1))
							.Radius = getJsonVal(InStream,"radius",BlockChar(1))
							.Mass = getJsonVal(InStream,"mass",BlockChar(1))
							.Planets = getJsonVal(InStream,"planets",BlockChar(1))
							
							.Neutron = 0 'NYI
						end with
						
						ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
						
						if cmdLine("--verbose") OR cmdLine("-vc") then
							print "Identified star cluster #"& ObjIDa
						end if

						print #9, "[";Time;", ";Date;"]  Registered star cluster #"& ObjIDa
						StarParser(ObjIDa) = InterStar
						
						BlockChar(1) = instr(BlockChar(1)+len(ObjClose),InStream,ObjClose)
						loadTurnKB(int(BlockChar(1)/1e3),PID)
					loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
				end if
			end if
			
			'Black Hole data. Only a preliminary implementation; not currently available in existing games
			/'
			if PID = 1 AND (FileExists("games/"+str(GameNum)+"/BlackHoles.csv") = 0 OR _
				FileDateTime("games/"+str(GameNum)+"/BlackHoles.csv") < DataFormat) then
				BlockChar(0) = instr(InStream,quote("blackholes")+": [")
				if BlockChar(0) > 0 AND instr(InStream,quote("blackholes")+": []") = 0 then
					BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
					BlockChar(1) = BlockChar(0)
					do
						with InterBlack
							.Namee = getJsonStr(InStream,"name",BlockChar(1))
							.XLoc = getJsonVal(InStream,"x",BlockChar(1))
							.YLoc = getJsonVal(InStream,"y",BlockChar(1))
							
							.Core = getJsonVal(InStream,"coreradius",BlockChar(1))
							.Band = getJsonVal(InStream,"bandradius",BlockChar(1))
						end with
						
						ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
						
						if cmdLine("--verbose") OR cmdLine("-vc") then
							print "Identified star cluster #"& ObjIDa
						end if

						print #9, "[";Time;", ";Date;"]  Registered black hole #"& ObjIDa
						BlackParser(ObjIDa) = InterBlack
						
						BlockChar(1) = instr(BlockChar(1)+len(ObjClose),InStream,ObjClose)
						loadTurnKB(int(BlockChar(1)/1e3),PID)
					loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
				end if
			end if
			'/
			
			'Artifact data
			BlockChar(0) = instr(InStream,quote("artifacts")+": [")
			if BlockChar(0) > 0 AND instr(InStream,quote("artifacts")+": []") = 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				do
					with InterArtifact
						.Namee = getJsonStr(InStream,"name",BlockChar(1))
						.XLoc = getJsonVal(InStream,"x",BlockChar(1))
						.YLoc = getJsonVal(InStream,"y",BlockChar(1))
						
						.LocationType = getJsonVal(InStream,"locationtype",BlockChar(1))
						.LocationId = getJsonVal(InStream,"locationid",BlockChar(1))
					end with
					
					ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
					
					if (cmdLine("--verbose") OR cmdLine("-va")) AND InterShip.ShipOwner > 0 then
						print "Identified artifact #"& ObjIDa
					end if
					
					ArtifactParser(ObjIDa) = InterArtifact
					print #9, "[";Time;", ";Date;"]  Registered artifact #"& ObjIDa
						
					BlockChar(1) = instr(BlockChar(1)+len(ObjClose),InStream,ObjClose)
					loadTurnKB(int(BlockChar(1)/1e3),PID)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
			end if
			
			'Wormhole data
			BlockChar(0) = instr(InStream,quote("wormholes")+": [")
			if BlockChar(0) > 0 AND instr(InStream,quote("wormholes")+": []") = 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				do
					with InterWormhole
						.Namee = getJsonStr(InStream,"name",BlockChar(1))
						
						'Coordinates
						.XLoc = getJsonVal(InStream,"x",BlockChar(1))
						.YLoc = getJsonVal(InStream,"y",BlockChar(1))
						.TargetX = getJsonVal(InStream,"targetx",BlockChar(1))
						.TargetY = getJsonVal(InStream,"targety",BlockChar(1))
						
						'Other info
						.Stability = getJsonVal(InStream,"stability",BlockChar(1))
						.LastScan = getJsonVal(InStream,"turn",BlockChar(1))
					end with
					
					ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
					
					if (cmdLine("--verbose") OR cmdLine("-vw")) AND InterShip.ShipOwner > 0 then
						print "Identified wormhole #"& ObjIDa
					end if
					
					if InterWormhole.LastScan > WormholeParser(ObjIDa).LastScan OR _
						WormholeParser(ObjIDa).XLoc = 0 OR WormholeParser(ObjIDa).TargetX = 0 then
						print #9, "[";Time;", ";Date;"]  Updated wormhole #"& ObjIDa
						WormholeParser(ObjIDa) = InterWormhole
					end if
						
					BlockChar(1) = instr(BlockChar(1)+len(ObjClose),InStream,ObjClose)
					loadTurnKB(int(BlockChar(1)/1e3),PID)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
			end if
			
			'Starbase data
			BlockChar(0) = instr(InStream,quote("starbases")+": [")
			if BlockChar(0) > 0 AND instr(InStream,quote("starbases")+": []") = 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				do
					with InterBase
						'Defense status
						.OrbitalDef = getJsonVal(InStream,"defense",BlockChar(1))
						.DamageLev = getJsonVal(InStream,"damage",BlockChar(1))
						.Fighters = getJsonVal(InStream,"fighters",BlockChar(1))
						
						'Orders
						.BaseOrders(1) = getJsonVal(InStream,"mission",BlockChar(1))
						.BaseTarget(1) = getJsonVal(InStream,"mission1target",BlockChar(1))
						.BaseOrders(2) = getJsonVal(InStream,"shipmission",BlockChar(1))
						.BaseTarget(2) = getJsonVal(InStream,"targetshipid",BlockChar(1))
						
						'Tech levels
						.HullTech = getJsonVal(InStream,"hulltechlevel",BlockChar(1))
						.EngineTech = getJsonVal(InStream,"enginetechlevel",BlockChar(1))
						.BeamTech = getJsonVal(InStream,"beamtechlevel",BlockChar(1))
						.TorpTech = getJsonVal(InStream,"torptechlevel",BlockChar(1))

						'Ship yard						
						if getJsonBool(InStream,"isbuilding",BlockChar(1)) = 0 then
							.UseHull = 0
							.UseEngine = 0
							.UseBeam = 0
							.UseTorp = 0
						else
							.UseHull = getJsonVal(InStream,"buildhullid",BlockChar(1))
							.UseEngine = getJsonVal(InStream,"buildengineid",BlockChar(1))
							.UseBeam = getJsonVal(InStream,"buildbeamid",BlockChar(1))
							.UseTorp = getJsonVal(InStream,"buildtorpedoid",BlockChar(1))
						end if
					end with
				
					ObjIDa = getJsonVal(InStream,"planetid",BlockChar(1))
					ObjIDb = getJsonVal(InStream,"id",BlockChar(1))
						
					if PlanetParser(ObjIDa).PlanetOwner = PID then
						print #9, "[";Time;", ";Date;"]  Registered starbase #"& ObjIDa
						with PlanetParser(ObjIDa)
							.BasePresent = ObjIDb
						end with
						
						BaseParser(ObjIDa) = InterBase
					end if
				
					BlockChar(1) = instr(BlockChar(1)+len(ObjClose),InStream,ObjClose)
					loadTurnKB(int(BlockChar(1)/1e3),PID)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
			end if
			
			'Base Storage data
			BlockChar(0) = instr(InStream,quote("stock")+": [")
			if BlockChar(0) > 0 AND instr(InStream,quote("stock")+": []") = 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				do
					with StockParser(StorageID)
						.ItemType = getJsonVal(InStream,"stocktype",BlockChar(1))
						.ItemId = getJsonVal(InStream,"stockid",BlockChar(1))
						.ItemAmt = getJsonVal(InStream,"amount",BlockChar(1))
						.StarbaseId = getJsonVal(InStream,"starbaseid",BlockChar(1))
					end with

					StorageID += 1
					BlockChar(1) = instr(BlockChar(1)+1,InStream,ObjClose)
					loadTurnKB(int(BlockChar(1)/1e3),PID)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
			end if
			
			'Minefield data
			BlockChar(0) = instr(InStream,quote("minefields")+": [")
			if BlockChar(0) > 0 AND instr(InStream,quote("minefields")+": []") = 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				do
					with InterMinef
						.MineOwner = getJsonVal(InStream,"ownerid",BlockChar(1))
						.Webfield = getJsonBool(InStream,"isweb",BlockChar(1))
						
						.XLoc = getJsonVal(InStream,"x",BlockChar(1))
						.YLoc = getJsonVal(InStream,"y",BlockChar(1))
						
						.Units = getJsonVal(InStream,"units",BlockChar(1))
						.Radius = getJsonVal(InStream,"radius",BlockChar(1))
						.FCode = getJsonStr(InStream,"friendlycode",BlockChar(1))
					end with
					
					ObjIDa = getJsonVal(InStream,"id",BlockChar(1))
					
					if (cmdLine("--verbose") OR cmdLine("-vm")) AND InterShip.ShipOwner > 0 then
						print "Identified minefield #"& ObjIDa;" as belonging to player "& InterMinef.MineOwner
					end if
					
					if InterMinef.MineOwner = PID then
						print #9, "[";Time;", ";Date;"]  Registered minefield #"& ObjIDa
						MinefParser(ObjIDa) = InterMinef
					end if
						
					BlockChar(1) = instr(BlockChar(1)+len(ObjClose),InStream,ObjClose)
					loadTurnKB(int(BlockChar(1)/1e3),PID)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
			end if
			
			'Diplomacy relations data
			BlockChar(0) = instr(InStream,quote("relations")+": [")
			if BlockChar(0) > 0 AND instr(InStream,quote("relations")+": []") = 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				do
					with RelateParser(RelateID)
						.FromPlr = getJsonVal(InStream,"playerid",BlockChar(1))
						.ToPlr = getJsonVal(InStream,"playertoid",BlockChar(1))
						.RelationA = getJsonVal(InStream,"relationto",BlockChar(1))
						.RelationB = getJsonVal(InStream,"relationfrom",BlockChar(1))
						.ConflictLev = getJsonVal(InStream,"conflictlevel",BlockChar(1))
					end with

					if RelateParser(RelateID).FromPlr = PID then
						if cmdLine("--verbose") OR cmdLine("-vr") then
							with RelateParser(RelateID)
								if .FromPlr < .ToPlr then
									print "Identified the relationship between players "& .FromPlr;" and "& .ToPlr;" as #"& RelateID
								end if
							end with
						end if
						RelateID += 1
					end if
						
					BlockChar(1) = instr(BlockChar(1)+len(ObjClose),InStream,ObjClose)
					loadTurnKB(int(BlockChar(1)/1e3),PID)
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
			end if
			
			'VCR data
			BlockChar(0) = instr(InStream,quote("vcrs")+": [")
			if BlockChar(0) > 0 AND instr(InStream,quote("vcrs")+": []") = 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				do
					with VCRParser(CombatID)
						'Basic specs
						.Seed = getJsonVal(InStream,"seed",BlockChar(1))
						.XLoc = getJsonVal(InStream,"x",BlockChar(1))
						.YLoc = getJsonVal(InStream,"y",BlockChar(1))
						
						.Battletype = getJsonVal(InStream,"battletype",BlockChar(1))
						.LeftOwner = getJsonVal(InStream,"leftownerid",BlockChar(1))
						.RightOwner = getJsonVal(InStream,"rightownerid",BlockChar(1))
						.Turn = getJsonVal(InStream,"turn",BlockChar(1))
						.InternalID = getJsonVal(InStream,"id",BlockChar(1))
						
						for VCRSide as byte = 1 to 2
							with .Combatants(VCRSide)
								'Ship/planet piece
								.PieceID = getJsonVal(InStream,"objectid",BlockChar(1))
								.Namee = findReplace(getJsonStr(InStream,"name",BlockChar(1)),",","&")
								
								'Functional weapons
								.BeamCt = getJsonVal(InStream,"beamcount",BlockChar(1))
								.TubeCt = getJsonVal(InStream,"launchercount",BlockChar(1))
								.BayCt = getJsonVal(InStream,"baycount",BlockChar(1))
								
								'Ship equipment
								.HullID = getJsonVal(InStream,"hullid",BlockChar(1))
								.BeamID = getJsonVal(InStream,"beamid",BlockChar(1))
								.TorpID = getJsonVal(InStream,"torpedoid",BlockChar(1))
								
								'Ship integrity
								.Shield = getJsonVal(InStream,"shield",BlockChar(1))
								.Damage = getJsonVal(InStream,"damage",BlockChar(1))
								.Crew = getJsonVal(InStream,"crew",BlockChar(1))
								.Mass = getJsonVal(InStream,"mass",BlockChar(1))
								
								'Combat odds. Ancient games might not have this data, so its existance is checked
								.BeamKillX = getJsonVal(InStream,"beamkillbonus",BlockChar(1),,-1)
								if .BeamKillX < 0 then
									if .RaceID = 5 then
										'Privateer ships get triple crew kill on their beam banks
										.BeamKillX = 3
									else
										.BeamKillX = 1
									end if
								end if
								.BeamChargeX = getJsonVal(InStream,"beamchargerate",BlockChar(1),,1)
								.TorpChargeX = getJsonVal(InStream,"torpchargerate",BlockChar(1),,1)
								.TorpMissChance = getJsonVal(InStream,"torpmisspercent",BlockChar(1),,35)
								.CrewDefense = getJsonVal(InStream,"crewdefensepercent",BlockChar(1),,0)
								
								'Miscellaneous
								.RaceID = getJsonVal(InStream,"raceid",BlockChar(1))
								.TorpAmmo = getJsonVal(InStream,"torpedos",BlockChar(1))
								.Fighters = getJsonVal(InStream,"fighters",BlockChar(1))
								.Temperature = getJsonVal(InStream,"temperature",BlockChar(1))
								.Starbase = getJsonBool(InStream,"hasstarbase",BlockChar(1))
								
								if GameNum < 51690 then
									/'
									 ' Older games do not correctly handle freighters and damaged ships in the API data
									 ' This override should cover most (if not all) holes
									 '/
									if GameParser.CampaignGame = 0 then
										.Shield = max(min(.Shield, 100 - .Damage),0)
									end if
									
									if .BeamCt + .TubeCt + .BayCt = 0 AND .HullID <> 108 then
										.Shield = 0
									end if
								end if
								
								BlockChar(1) = instr(BlockChar(1)+len(ObjClose),InStream,ObjClose)
								loadTurnKB(int(BlockChar(1)/1e3),PID)
							end with
						next VCRSide
					end with

					if VCRParser(CombatID).LeftOwner = PID then
						if cmdLine("--verbose") OR cmdLine("-vc") then
							print "Registered a VCR between piece #"& VCRParser(CombatID).Combatants(1).PieceID;
							print " and piece #"& VCRParser(CombatID).Combatants(2).PieceID;"."
						end if
						CombatID += 1
					end if
				loop until BlockChar(1) = 0 OR BlockChar(1) > BlockChar(2)  
			end if
		end if
	
		with ProcessSlot(PID)
			#IFDEF __DEDICATED__
			if Command(3) <> "" then
				print "Finished player "& PID;"!"
			end if
			#ENDIF

			print #9, "[";Time;", ";Date;"]  Done for ";.RaceType;" (";trim(.Namee,chr(34));")"
			loadTurnUI(PID)
		end with
	next PID
	
	if PrintTxt then
		print " All players done."
	end if

	print #9, "[";Time;", ";Date;"] Compiling all lists... ";
	exportCSVfiles(GameNum,TurnNum)
	print #9, " Done"
	
	createMap(GameNum,TurnNum)

	ParseEnd = timer
	print #9, "[";Time;", ";Date;"] Export all done! Conversion required ";
	print #9, using "##.## minute(s)";(ParseEnd - ParseStart)/60
	if PrintTxt then
		if ErrorLog = 0 then
			print "Export all done and logged."
		else
			print "Export all done."
		end if
	end if
	close #9
	
	kill("games/"+str(GameNum)+"/"+str(TurnNum)+"/Working")
	return 0
end function
#ENDIF
