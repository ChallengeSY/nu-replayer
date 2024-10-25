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
	dim as integer ObjIDa, ObjIDb, RelateID, StorageID, CombatID, ErrorLog, BlockChar(2), SeekChar(2)
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
		print "Parsing players...";
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
		print #9, "[";Time;", ";Date;"] Parsing Player "& PID;"'s data from ";LoadFile;"..."

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
			if PID = 1 AND FileExists("games/"+str(GameNum)+"/Settings.csv") = 0 then
				BlockChar(0) = instr(InStream,quote("settings")+": {")
								
				if BlockChar(0) > 0 then
					BlockChar(1) = instr(BlockChar(0),InStream,ObjClose)
					
					with GameParser
						SeekChar(0) = instr(BlockChar(0),InStream,quote("slots")+":")
						.PlayerCount = valint(mid(InStream,SeekChar(0)+8,2))
						
						SeekChar(0) = instr(BlockChar(0),InStream,quote("mapwidth")+":")
						.MapWidth = valint(mid(InStream,SeekChar(0)+11,4))
						
						SeekChar(0) = instr(BlockChar(0),InStream,quote("mapheight")+":")
						.MapHeight = valint(mid(InStream,SeekChar(0)+12,4))
						
						SeekChar(0) = instr(BlockChar(0),InStream,quote("sphere")+":true")
						.Sphere = abs(sgn(SeekChar(0) > 0 AND SeekChar(0) < BlockChar(1)))
						
						SeekChar(0) = instr(BlockChar(0),InStream,quote("isacademy")+":true")
						.Academy = abs(sgn(SeekChar(0) > 0 AND SeekChar(0) < BlockChar(1)))
						
						SeekChar(0) = instr(BlockChar(0),InStream,quote("acceleratedturns")+":")
						.AccelStart = valint(mid(InStream,SeekChar(0)+19,3))
						
						MinXPos = 2000 - .MapWidth/2
						MaxXPos = MinXPos + .MapWidth
						MinYPos = 2000 - .MapHeight/2
						MaxYPos = MinYPos + .MapHeight
					end with
				end if
				
				if cmdLine("--verbose") then
					print "Acquired game settings for game "& GameNum 
				end if
				
				loadTurnKB(int(BlockChar(1)/1e3),PID)
			end if
			
			'Convert player data
			BlockChar(0) = instr(InStream,quote("player")+": {")
			if BlockChar(0) > 0 then
				BlockChar(1) = instr(BlockChar(0),InStream,ObjClose)
				
				with ProcessSlot(PID)
					SeekChar(0) = instr(BlockChar(0),InStream,quote("raceid"))
					RaceType = valint(mid(InStream,SeekChar(0)+9,2))

					SeekChar(0) = instr(BlockChar(0),InStream,quote("username"))
					SeekChar(1) = instr(SeekChar(0)+12,InStream,chr(34))
					.Namee = mid(InStream, SeekChar(0)+12, SeekChar(1)-SeekChar(0)-12)

					'Academy resources
					SeekChar(0) = instr(BlockChar(0),InStream,quote("duranium"))
					.StockDu = valint(mid(InStream,SeekChar(0)+11,7))
					SeekChar(0) = instr(BlockChar(0),InStream,quote("tritanium"))
					.StockTr = valint(mid(InStream,SeekChar(0)+12,7))
					SeekChar(0) = instr(BlockChar(0),InStream,quote("molybdenum"))
					.StockMo = valint(mid(InStream,SeekChar(0)+13,7))
					SeekChar(0) = instr(BlockChar(0),InStream,quote("megacredits"))
					.StockCr = valint(mid(InStream,SeekChar(0)+14,7))

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
				
				SeekChar(0) = instr(BlockChar(0),InStream,quote("ownerid")+":"+str(PID))
				if SeekChar(0) < BlockChar(1) then
					with ProcessSlot(PID)
						'Starships
						SeekChar(1) = instr(SeekChar(0),InStream,quote("capitalships")) 
						.TotalShips = valint(mid(InStream,SeekChar(1)+15,3))
						SeekChar(1) = instr(SeekChar(0),InStream,quote("freighters")) 
						.Freighters = valint(mid(InStream,SeekChar(1)+13,3))
						.TotalShips += .Freighters
						
						'Planets/Bases/Military
						SeekChar(1) = instr(SeekChar(0),InStream,quote("planets")) 
						.Planets = valint(mid(InStream,SeekChar(1)+10,3))
						SeekChar(1) = instr(SeekChar(0),InStream,quote("starbases")) 
						.Bases = valint(mid(InStream,SeekChar(1)+12,3))
						SeekChar(1) = instr(SeekChar(0),InStream,quote("militaryscore")) 
						.Military = valint(mid(InStream,SeekChar(1)+16,13))
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
					SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
					SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
					ObjName = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)

					SeekChar(0) = instr(BlockChar(1),InStream,quote("friendlycode"))
					SeekChar(1) = instr(SeekChar(0)+16,InStream,chr(34))
					ObjCode = mid(InStream, SeekChar(0)+16, SeekChar(1)-SeekChar(0)-16)
					
					with InterPlan
						'Coordinates
						SeekChar(0) = instr(BlockChar(1),InStream,quote("x"))
						.XLoc = valint(mid(InStream,SeekChar(0)+4,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("y"))
						.YLoc = valint(mid(InStream,SeekChar(0)+4,4))
						
						'Colony info
						.PlanName = ObjName
						.FriendlyCode = ObjCode
						SeekChar(0) = instr(BlockChar(1),InStream,quote("ownerid"))
						.PlanetOwner = valint(mid(InStream,SeekChar(0)+10,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("clans"))
						.Colonists = valint(mid(InStream,SeekChar(0)+8,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("colonisttaxrate"))
						.ColTaxes = valint(mid(InStream,SeekChar(0)+18,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("colonisthappypoints"))
						.ColHappy = valint(mid(InStream,SeekChar(0)+22,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("temp"))
						.Temp = valint(mid(InStream,SeekChar(0)+7,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("infoturn"))
						.LastScan = valint(mid(InStream,SeekChar(0)+11,4))
						
						'Native info
						SeekChar(0) = instr(BlockChar(1),InStream,quote("nativeclans"))
						.Natives = valint(mid(InStream,SeekChar(0)+14,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("nativetaxrate"))
						.NatTaxes = valint(mid(InStream,SeekChar(0)+16,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("nativehappypoints"))
						.NatHappy = valint(mid(InStream,SeekChar(0)+20,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("nativetype"))
						.NativeType = valint(mid(InStream,SeekChar(0)+13,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("nativegovernment"))
						.NativeGov = valint(mid(InStream,SeekChar(0)+19,1))
						
						'Surface minerals
						SeekChar(0) = instr(BlockChar(1),InStream,quote("neutronium"))
						.Neu = valint(mid(InStream,SeekChar(0)+13,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("duranium"))
						.Dur = valint(mid(InStream,SeekChar(0)+11,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("tritanium"))
						.Trit = valint(mid(InStream,SeekChar(0)+12,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("molybdenum"))
						.Moly = valint(mid(InStream,SeekChar(0)+13,6))
						
						'Mineable minerals
						SeekChar(0) = instr(BlockChar(1),InStream,quote("groundneutronium"))
						.GNeu = valint(mid(InStream,SeekChar(0)+19,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("groundduranium"))
						.GDur = valint(mid(InStream,SeekChar(0)+17,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("groundtritanium"))
						.GTrit = valint(mid(InStream,SeekChar(0)+18,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("groundmolybdenum"))
						.GMoly = valint(mid(InStream,SeekChar(0)+19,6))
						
						'Mineral densities
						SeekChar(0) = instr(BlockChar(1),InStream,quote("densityneutronium"))
						.DNeu = valint(mid(InStream,SeekChar(0)+20,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("densityduranium"))
						.DDur = valint(mid(InStream,SeekChar(0)+18,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("densitytritanium"))
						.DTrit = valint(mid(InStream,SeekChar(0)+19,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("densitymolybdenum"))
						.DMoly = valint(mid(InStream,SeekChar(0)+20,3))
						
						'Structural info
						SeekChar(0) = instr(BlockChar(1),InStream,quote("megacredits"))
						.Megacredits = valint(mid(InStream,SeekChar(0)+14,7))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("supplies"))
						.Supplies = valint(mid(InStream,SeekChar(0)+11,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("mines"))
						.MineralMines = valint(mid(InStream,SeekChar(0)+8,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("factories"))
						.Factories = valint(mid(InStream,SeekChar(0)+12,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("defense"))
						.DefPosts = valint(mid(InStream,SeekChar(0)+10,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("debrisdisk"))
						.Asteroid = valint(mid(InStream,SeekChar(0)+13,2))
					end with
					
					with InterWasp
						SeekChar(0) = instr(BlockChar(1),InStream,quote("targetmines"))
						.WorkMine = valint(mid(InStream,SeekChar(0)+14,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("targetfactories"))
						.WorkHarvest = valint(mid(InStream,SeekChar(0)+18,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("targetdefense"))
						.WorkBurrow = valint(mid(InStream,SeekChar(0)+16,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("builtmines"))
						.WorkTerraform = valint(mid(InStream,SeekChar(0)+13,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("larva"))
						.Larva = valint(mid(InStream,SeekChar(0)+8,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("burrowsize"))
						.BurrowSize = valint(mid(InStream,SeekChar(0)+13,8))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("podhullid"))
						.PodHull = valint(mid(InStream,SeekChar(0)+12,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("podcargo"))
						.PodCargo = valint(mid(InStream,SeekChar(0)+11,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("targetx"))
						.PodX = valint(mid(InStream,SeekChar(0)+10,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("targety"))
						.PodY = valint(mid(InStream,SeekChar(0)+10,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("podspeed"))
						.PodWarp = valint(mid(InStream,SeekChar(0)+11,2))
					end with
					
					SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
					ObjIDa = valint(mid(InStream,SeekChar(0)+5,4))
					
					if (cmdLine("--verbose") OR cmdLine("-vp")) AND InterPlan.PlanetOwner > 0 then
						print "Identified planet #"& ObjIDa;" as belonging to player "& InterPlan.PlanetOwner
					end if
					
					WaspParser(ObjIDa) = InterWasp
					
					if InterPlan.PlanetOwner = PID then
						with PlanetParser(ObjIDa)
							if .LockOwner = 0 OR (InterPlan.Colonists > .Colonists AND TurnNum < GameParser.AccelStart) then
								print #9, "[";Time;", ";Date;"]  Registered planet #"& ObjIDa;" (";ObjName;")"
								PlanetParser(ObjIDa) = InterPlan
								
								.LockOwner = 1
								.LastScan = TurnNum
							end if
						end with
					else
						with PlanetParser(ObjIDa)
							if .LockOwner = 0 then
								.PlanetOwner = 0
								.PlanName = findReplace(ObjName,",","&")
								.FriendlyCode = findReplace(ObjCode,",","&")
								if InterPlan.LastScan >= PlanetParser(ObjIDa).LastScan then
									.LastScan = InterPlan.LastScan
								end if
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
					SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
					SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
					ObjName = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)

					SeekChar(0) = instr(BlockChar(1),InStream,quote("friendlycode"))
					SeekChar(1) = instr(SeekChar(0)+16,InStream,chr(34))
					ObjCode = mid(InStream, SeekChar(0)+16, SeekChar(1)-SeekChar(0)-16)
					
					HistoryBlock(0) = instr(BlockChar(1),InStream,quote("history")+":[")
					HistoryBlock(1) = instr(HistoryBlock(0),InStream,"]")
					WaypointsBlock(0) = instr(BlockChar(1),InStream,quote("waypoints")+":[")
					WaypointsBlock(1) = instr(WaypointsBlock(0),InStream,"]")
						
					with InterShip
						'Coordinates
						SeekChar(0) = instr(BlockChar(1),InStream,quote("x"))
						if HistoryBlock(0) > 0 AND SeekChar(0) > HistoryBlock(0) then
							SeekChar(0) = instr(HistoryBlock(1),InStream,quote("x"))
						end if
						.XLoc = valint(mid(InStream,SeekChar(0)+4,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("y"))
						if HistoryBlock(0) > 0 AND SeekChar(0) > HistoryBlock(0) then
							SeekChar(0) = instr(HistoryBlock(1),InStream,quote("y"))
						end if
						.YLoc = valint(mid(InStream,SeekChar(0)+4,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("targetx"))
						.TargetX = valint(mid(InStream,SeekChar(0)+10,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("targety"))
						.TargetY = valint(mid(InStream,SeekChar(0)+10,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("warp"))
						.WarpFactor = valint(mid(InStream,SeekChar(0)+7,2))
						
						'Basic info
						.ShipName = ObJName
						.FriendlyCode = ObjCode
						SeekChar(0) = instr(BlockChar(1),InStream,quote("ownerid"))
						.ShipOwner = valint(mid(InStream,SeekChar(0)+10,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("mass"))
						.TotalMass = valint(mid(InStream,SeekChar(0)+7,6))
						
						'Equipment
						SeekChar(0) = instr(BlockChar(1),InStream,quote("beams"))
						.BeamCount = valint(mid(InStream,SeekChar(0)+8,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("bays"))
						.BayCount = valint(mid(InStream,SeekChar(0)+7,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("torps"))
						.TubeCount = valint(mid(InStream,SeekChar(0)+8,2))
						
						'Mission
						SeekChar(0) = instr(BlockChar(1),InStream,quote("mission"))
						.Mission = valint(mid(InStream,SeekChar(0)+10,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("mission1target"))
						.MisnTarget(1) = valint(mid(InStream,SeekChar(0)+17,9))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("mission2target"))
						.MisnTarget(2) = valint(mid(InStream,SeekChar(0)+17,9))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("enemy"))
						.PrimEnemy = valint(mid(InStream,SeekChar(0)+8,2))
						
						'Cargo Hold
						SeekChar(0) = instr(BlockChar(1),InStream,quote("clans"))
						.Colonists = valint(mid(InStream,SeekChar(0)+8,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("neutronium"))
						.Neu = valint(mid(InStream,SeekChar(0)+13,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("duranium"))
						.Dur = valint(mid(InStream,SeekChar(0)+11,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("tritanium"))
						.Trit = valint(mid(InStream,SeekChar(0)+12,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("molybdenum"))
						.Moly = valint(mid(InStream,SeekChar(0)+13,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("megacredits"))
						.Megacredits = valint(mid(InStream,SeekChar(0)+14,7))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("supplies"))
						.Supplies = valint(mid(InStream,SeekChar(0)+11,6))
						
						'Ship Status
						SeekChar(0) = instr(BlockChar(1),InStream,quote("damage"))
						.Damage = valint(mid(InStream,SeekChar(0)+9,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("crew"))
						.Crewmen = valint(mid(InStream,SeekChar(0)+7,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("ammo"))
						.Ordnance = valint(mid(InStream,SeekChar(0)+7,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("experience"))
						.Experience = valint(mid(InStream,SeekChar(0)+13,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("iscloaked"))
						.Cloaked = abs(sgn(mid(InStream,SeekChar(0)+11,5) = ":true"))
						
						'Ship Specs
						SeekChar(0) = instr(BlockChar(1),InStream,quote("hullid"))
						.ShipType = valint(mid(InStream,SeekChar(0)+9,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("engineid"))
						.EngineID = valint(mid(InStream,SeekChar(0)+11,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("beamid"))
						.BeamID = valint(mid(InStream,SeekChar(0)+9,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("torpedoid"))
						.TubeID = valint(mid(InStream,SeekChar(0)+12,4))
					end with
					
					SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
					ObjIDa = valint(mid(InStream,SeekChar(0)+5,3))
					
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
							SeekChar(0) = instr(BlockChar(1),InStream,quote("x"))
							.XLoc = valint(mid(InStream,SeekChar(0)+4,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("y"))
							.YLoc = valint(mid(InStream,SeekChar(0)+4,4))
							
							'Storm info
							SeekChar(0) = instr(BlockChar(1),InStream,quote("radius"))
							.Radius = valint(mid(InStream,SeekChar(0)+9,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("voltage"))
							.Voltage = valint(mid(InStream,SeekChar(0)+10,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("warp"))
							.WarpFactor = valint(mid(InStream,SeekChar(0)+7,2))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("heading"))
							.StormHeading = valint(mid(InStream,SeekChar(0)+10,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("isgrowing"))
							.StormGrowing = abs(sgn(mid(InStream,SeekChar(0)+12,5) = ":true"))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("parentid"))
							.ParentID = valint(mid(InStream,SeekChar(0)+11,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
							ObjIDa = valint(mid(InStream,SeekChar(0)+5,4))
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
						SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
						SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
						ObjName = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)
						
						with InterNeb
							SeekChar(0) = instr(BlockChar(1),InStream,quote("x"))
							.XLoc = valint(mid(InStream,SeekChar(0)+4,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("y"))
							.YLoc = valint(mid(InStream,SeekChar(0)+4,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("radius"))
							.Radius = valint(mid(InStream,SeekChar(0)+9,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("intensity"))
							.Intense = valint(mid(InStream,SeekChar(0)+12,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("gas"))
							.Gas = valint(mid(InStream,SeekChar(0)+6,3))
							
							.NebName = ObjName
						end with
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
						ObjIDa = valint(mid(InStream,SeekChar(0)+5,3))
						
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
						SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
						SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
						ObjName = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)
						
						with InterStar
							SeekChar(0) = instr(BlockChar(1),InStream,quote("x"))
							.XLoc = valint(mid(InStream,SeekChar(0)+4,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("y"))
							.YLoc = valint(mid(InStream,SeekChar(0)+4,4))
							
							SeekChar(0) = instr(BlockChar(1),InStream,quote("temp"))
							.Temp = valint(mid(InStream,SeekChar(0)+7,6))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("radius"))
							.Radius = valint(mid(InStream,SeekChar(0)+9,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("mass"))
							.Mass = valint(mid(InStream,SeekChar(0)+7,6))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("planets"))
							.Planets = valint(mid(InStream,SeekChar(0)+10,3))
							
							.ClustName = ObjName
						end with
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
						ObjIDa = valint(mid(InStream,SeekChar(0)+5,3))
						
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
			
			'Artifact data
			BlockChar(0) = instr(InStream,quote("artifacts")+": [")
			if BlockChar(0) > 0 AND instr(InStream,quote("artifacts")+": []") = 0 then
				BlockChar(2) = instr(BlockChar(0),InStream,ArrayClose)
				BlockChar(1) = BlockChar(0)
				do
					with InterArtifact
						SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
						SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
						.Namee = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)

						SeekChar(0) = instr(BlockChar(1),InStream,quote("x"))
						.XLoc = valint(mid(InStream,SeekChar(0)+4,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("y"))
						.YLoc = valint(mid(InStream,SeekChar(0)+4,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("locationtype"))
						.LocationType = valint(mid(InStream,SeekChar(0)+15,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("locationid"))
						.LocationId = valint(mid(InStream,SeekChar(0)+13,4))
					end with
					
					SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
					ObjIDa = valint(mid(InStream,SeekChar(0)+5,3))
					
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
					SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
					SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
					ObjName = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)
						
					with InterWormhole
						.Namee = ObjName
						
						'Coordinates
						SeekChar(0) = instr(BlockChar(1),InStream,quote("x"))
						.XLoc = valint(mid(InStream,SeekChar(0)+4,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("y"))
						.YLoc = valint(mid(InStream,SeekChar(0)+4,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("targetx"))
						.TargetX = valint(mid(InStream,SeekChar(0)+10,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("targety"))
						.TargetY = valint(mid(InStream,SeekChar(0)+10,4))

						'Other info
						SeekChar(0) = instr(BlockChar(1),InStream,quote("stability"))
						.Stability = valint(mid(InStream,SeekChar(0)+12,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("turn"))
						.LastScan = valint(mid(InStream,SeekChar(0)+7,4))
					end with
					
					SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
					ObjIDa = valint(mid(InStream,SeekChar(0)+5,3))
					
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
						SeekChar(0) = instr(BlockChar(1),InStream,quote("defense"))
						.OrbitalDef = valint(mid(InStream,SeekChar(0)+10,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("damage"))
						.DamageLev = valint(mid(InStream,SeekChar(0)+9,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("fighters"))
						.Fighters = valint(mid(InStream,SeekChar(0)+11,4))
						
						'Orders
						SeekChar(0) = instr(BlockChar(1),InStream,quote("mission"))
						.BaseOrders(1) = valint(mid(InStream,SeekChar(0)+10,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("mission1target"))
						.BaseTarget(1) = valint(mid(InStream,SeekChar(0)+17,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("shipmission"))
						.BaseOrders(2) = valint(mid(InStream,SeekChar(0)+14,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("targetshipid"))
						.BaseTarget(2) = valint(mid(InStream,SeekChar(0)+15,4))
						
						'Tech levels
						SeekChar(0) = instr(BlockChar(1),InStream,quote("hulltechlevel"))
						.HullTech = valint(mid(InStream,SeekChar(0)+16,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("enginetechlevel"))
						.EngineTech = valint(mid(InStream,SeekChar(0)+18,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("beamtechlevel"))
						.BeamTech = valint(mid(InStream,SeekChar(0)+16,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("torptechlevel"))
						.TorpTech = valint(mid(InStream,SeekChar(0)+16,3))

						'Ship yard						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("isbuilding"))
						if mid(InStream,SeekChar(0)+13,6) = ":false" then
							.UseHull = 0
							.UseEngine = 0
							.UseBeam = 0
							.UseTorp = 0
						else
							SeekChar(0) = instr(BlockChar(1),InStream,quote("buildhullid"))
							.UseHull = valint(mid(InStream,SeekChar(0)+14,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("buildengineid"))
							.UseEngine = valint(mid(InStream,SeekChar(0)+16,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("buildbeamid"))
							.UseBeam = valint(mid(InStream,SeekChar(0)+14,4))
							SeekChar(0) = instr(BlockChar(1),InStream,quote("buildtorpedoid"))
							.UseTorp = valint(mid(InStream,SeekChar(0)+17,4))
						end if
					end with
				
					SeekChar(0) = instr(BlockChar(1),InStream,quote("planetid"))
					ObjIDa = valint(mid(InStream,SeekChar(0)+11,3))
					SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
					ObjIDb = valint(mid(InStream,SeekChar(0)+5,3))
						
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
						SeekChar(0) = instr(BlockChar(1),InStream,quote("stocktype"))
						.ItemType = valint(mid(InStream,SeekChar(0)+12,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("stockid"))
						.ItemId = valint(mid(InStream,SeekChar(0)+10,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("amount"))
						.ItemAmt = valint(mid(InStream,SeekChar(0)+9,5))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("starbaseid"))
						.StarbaseId = valint(mid(InStream,SeekChar(0)+13,4))
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
						SeekChar(0) = instr(BlockChar(1),InStream,quote("ownerid"))
						.MineOwner = valint(mid(InStream,SeekChar(0)+10,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("isweb"))
						.Webfield = abs(sgn(mid(InStream,SeekChar(0)+7,5) = ":true"))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("x"))
						.XLoc = valint(mid(InStream,SeekChar(0)+4,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("y"))
						.YLoc = valint(mid(InStream,SeekChar(0)+4,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("units"))
						.Units = valint(mid(InStream,SeekChar(0)+8,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("radius"))
						.Radius = valint(mid(InStream,SeekChar(0)+9,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("friendlycode"))
						SeekChar(1) = instr(SeekChar(0)+16,InStream,chr(34))
						.FCode = mid(InStream, SeekChar(0)+16, SeekChar(1)-SeekChar(0)-16)
					end with
					
					SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
					ObjIDa = valint(mid(InStream,SeekChar(0)+5,3))
					
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
						SeekChar(0) = instr(BlockChar(1),InStream,quote("playerid"))
						.FromPlr = valint(mid(InStream,SeekChar(0)+11,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("playertoid"))
						.ToPlr = valint(mid(InStream,SeekChar(0)+13,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("relationto"))
						.RelationA = valint(mid(InStream,SeekChar(0)+13,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("relationfrom"))
						.RelationB = valint(mid(InStream,SeekChar(0)+15,3))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("conflictlevel"))
						.ConflictLev = valint(mid(InStream,SeekChar(0)+16,3))
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
						SeekChar(0) = instr(BlockChar(1),InStream,quote("seed"))
						.Seed = valint(mid(InStream,SeekChar(0)+7,6))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("x"))
						.XLoc = valint(mid(InStream,SeekChar(0)+4,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("y"))
						.YLoc = valint(mid(InStream,SeekChar(0)+4,4))
						
						SeekChar(0) = instr(BlockChar(1),InStream,quote("battletype"))
						.Battletype = valint(mid(InStream,SeekChar(0)+13,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("leftownerid"))
						.LeftOwner = valint(mid(InStream,SeekChar(0)+14,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("rightownerid"))
						.RightOwner = valint(mid(InStream,SeekChar(0)+15,2))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("turn"))
						.Turn = valint(mid(InStream,SeekChar(0)+7,4))
						SeekChar(0) = instr(BlockChar(1),InStream,quote("id"))
						.InternalID = valint(mid(InStream,SeekChar(0)+5,7))
						
						for VCRSide as byte = 1 to 2
							with .Combatants(VCRSide)
								'Ship/planet piece
								SeekChar(0) = instr(BlockChar(1),InStream,quote("objectid"))
								.PieceID = valint(mid(InStream,SeekChar(0)+11,4))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("name"))
								SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
								.Namee = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)
								
								'Functional weapons
								SeekChar(0) = instr(BlockChar(1),InStream,quote("launchercount"))
								.BeamCt = valint(mid(InStream,SeekChar(0)+12,3))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("beamcount"))
								.TubeCt = valint(mid(InStream,SeekChar(0)+16,3))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("baycount"))
								.BayCt = valint(mid(InStream,SeekChar(0)+11,3))
								
								'Ship equipment
								SeekChar(0) = instr(BlockChar(1),InStream,quote("hullid"))
								.HullID = valint(mid(InStream,SeekChar(0)+9,4))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("beamid"))
								.BeamID = valint(mid(InStream,SeekChar(0)+9,4))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("torpedoid"))
								.TorpID = valint(mid(InStream,SeekChar(0)+12,4))
								
								'Ship integrity
								SeekChar(0) = instr(BlockChar(1),InStream,quote("shield"))
								.Shield = valint(mid(InStream,SeekChar(0)+9,4))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("damage"))
								.Damage = valint(mid(InStream,SeekChar(0)+9,4))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("crew"))
								.Crew = valint(mid(InStream,SeekChar(0)+7,5))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("mass"))
								.Mass = valint(mid(InStream,SeekChar(0)+7,5))
								
								'Combat odds
								SeekChar(0) = instr(BlockChar(1),InStream,quote("beamkillbonus"))
								.BeamKillX = valint(mid(InStream,SeekChar(0)+16,2))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("beamchargerate"))
								.BeamChargeX = valint(mid(InStream,SeekChar(0)+17,2))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("torpchargerate"))
								.TorpChargeX = valint(mid(InStream,SeekChar(0)+17,2))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("torpmisspercent"))
								.TorpMissChance = valint(mid(InStream,SeekChar(0)+18,2))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("crewdefensepercent"))
								.CrewDefense = valint(mid(InStream,SeekChar(0)+21,2))
								
								'Miscellaneous
								SeekChar(0) = instr(BlockChar(1),InStream,quote("raceid"))
								.RaceID = valint(mid(InStream,SeekChar(0)+9,2))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("torpedos"))
								.TorpAmmo = valint(mid(InStream,SeekChar(0)+11,5))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("fighters"))
								.Fighters = valint(mid(InStream,SeekChar(0)+11,5))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("temperature"))
								.Temperature = valint(mid(InStream,SeekChar(0)+17,5))
								SeekChar(0) = instr(BlockChar(1),InStream,quote("hasstarbase"))
								.Starbase = abs(sgn(mid(InStream,SeekChar(0)+17,5) = ":true"))
								
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
	print #9, "[";Time;", ";Date;"] Export all done! Parsing required ";
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
