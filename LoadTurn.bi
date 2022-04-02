#IFNDEF __LOADTURN_BI__
#DEFINE __LOADTURN_BI__
#include "WordWrap.bi"
#include "vbcompat.bi"

#include "NRCommon.bi"
#include "ParseData.bas"

const ScanSpeed = 1

function strMatch(MasterStr as string, StartPos as integer, FindStr as string) as integer
	dim as byte StrFound = 0
	dim as integer CurrentPos
	for CurrentPos = StartPos to StartPos + (ScanSpeed - 1)
		StrFound = StrFound OR abs(mid(MasterStr,CurrentPos,len(FindStr)) = FindStr)
	next CurrentPos
	
	return iif(StrFound = 0,0,CurrentPos)
end function

#IFNDEF __DOWNLOAD_TURNS__
dim shared as string ErrorMsg
#ENDIF

function loadTurn(GameNum as integer, TurnNum as short, PrintTxt as byte = 1) as byte
	randomize timer
	
	dim as string InStream, ObjName, ObjCode, RawPath, LoadFile
	dim as integer ObjIDa, ObjIDb, RelateID, StorageID, CombatID, ErrorLog
	dim as byte ParseWhat, RaceType, AssignVCRSide, TempIgnore
	dim as double ParseStart, ParseEnd

	mkdir("games/"+str(GameNum))
	mkdir("games/"+str(GameNum)+"/"+str(TurnNum))
	RawPath = "raw/"+str(GameNum)

	for ObjIDa = 1 to LimitObjs
		with PlanetParser(ObjIDa)
			.PlanetOwner = 0
			.LockOwner = 0
			.BasePresent = -1
			.PlanName = ""
			.XLoc = 0
			.YLoc = 0
			.FriendlyCode = quote("---")
			.Asteroid = 0

			.LastScan = 0
			.NativesUpdated = 0
			.MineralsUpdated = 0
			.MoneyUpdated = 0
			.BuildingsUpdated = 0
		end with

		with ShipParser(ObjIDa)
			.ShipOwner = 0
			.LockOwner = 0
			.XLoc = 0
			.YLoc = 0
			.ShipName = ""
			.ShipType = 0
			.FriendlyCode = quote("---")
			.Cloaked = 0
			.Experience = 0
		end with
		
		with BaseParser(ObjIDa)
			.OrbitalDef = 0
			.DamageLev = 0
			.Fighters = 0
			.HullTech = 0
			.EngineTech = 0
			.BeamTech = 0
			.TorpTech = 0
			.UseHull = 0
			.UseEngine = 0
			.UseBeam = 0
			.UseTorp = 0
		end with
		
		with RelateParser(ObjIDa)
			.FromPlr = 0
			.ToPlr = 0
			.RelationA = 0
			.RelationB = 0
			.ConflictLev = 0
		end with
		
		with VCRParser(ObjIDa)
			.Seed = 0
			.XLoc = 0
			.YLoc = 0
			.Battletype = 0
			.LeftOwner = 0
			.RightOwner = 0
			.Turn = 0
			.InternalID = 0
			for Plr as byte = 1 to 2
				with .Combatants(Plr)
					.PieceID = 0
					.Namee = ""
					.BeamCt = 0
					.TubeCt = 0
					.BayCt = 0
					.HullID = 0
					.BeamID = 0
					.TorpID = 0
					.Shield = 0
					.Damage = 0
					.Crew = 0
					.Mass = 0
					.RaceID = 0
					.BeamKillX = 0
					.BeamChargeX = 0
					.TorpChargeX = 0
					.TorpMissChance = 0
					.CrewDefense = 0
					.TorpAmmo = 0
					.Fighters = 0
					.Temperature = 0
					.Starbase = 0
				end with
			next Plr
		end with
	next
	
	for MetaID as integer = 1 to MetaLimit
		with StockParser(MetaID)
			.StarbaseId = 0
			.ItemType = 0
			.ItemId = 0
			.ItemAmt = 0
		end with
		
		with MinefParser(MetaID)
			.MineOwner = 0
			.Webfield = 0
			.Units = 0
			.Radius = 0
			.FCode = quote("---")
		end with
	next MetaID
	
	InterShip.ShipOwner = 0
	
	for PlrID as ubyte = 1 to 35
		with ProcessSlot(PlrID)
			.RaceType = "Unassigned"
			.Namee = ""
			.TotalShips = -1
			.Freighters = 0
			.Planets = -1
			.Bases = 0
			.Military = -1
			
			.StockDu = 0
			.StockTr = 0
			.StockMo = 0
			.StockCr = 0
		end with
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
	
	with GameParser
		.MapWidth = 2000
		.MapHeight = 2000
		.DynamicMap = 0
		.PlayerCount = 0
		.Sphere = 0
		.Academy = 0
		.LastTurn = 0
	end with

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
		ParsingDone(PARSER_SETTINGS) = 1
	else
		ParsingDone(PARSER_SETTINGS) = 0
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
		for ParseThru as byte = 1 to PARSER_MAX
			ParsingDone(ParseThru) = 0
		next

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

		ParseWhat = PARSER_NONE

		open LoadFile for input as #1
		do
			line input #1, InStream
		loop until left(InStream,11) = "{"+quote("success")+":" OR eof(1)
		close #1

		if mid(InStream,12,5) = "false" then
			ProcessSlot(PID).Namee = quote("error")
			ProcessSlot(PID).RaceType = "Unknown"
		else
			for DID as integer = 1 to len(InStream) step ScanSpeed
				if remainder(DID,1e3) = 0 then
					loadTurnKB(int(DID/1e3),PID)
				end if
				
				if ParsingDone(PARSER_SETTINGS) = 0 then
					if strMatch(InStream,DID,quote("settings")+": {") OR _
						strMatch(InStream,DID,quote("game")+": {") then
						ParseWhat = PARSER_SETTINGS
						ParsingDone(ParseWhat) = 1
						DID = strMatch(InStream,DID,quote("game")+": {") - ScanSpeed
						continue for
					end if
				end if

				if ParsingDone(PARSER_PLAYER) = 0 then
					if strMatch(InStream,DID,quote("player")+": {") then
						ParseWhat = PARSER_PLAYER
						ParsingDone(ParseWhat) = 1
						DID = strMatch(InStream,DID,quote("player")+": {") - ScanSpeed
						continue for
					end if
				end if
				
				if ParsingDone(PARSER_SCORES) = 0 then
					if strMatch(InStream,DID,quote("players")+": [") then
						ParseWhat = PARSER_NONE
					end if

					if strMatch(InStream,DID,quote("scores")+": [") then
						ParseWhat = PARSER_SCORES
						ParsingDone(ParseWhat) = 1
						DID = strMatch(InStream,DID,quote("scores")+": [") - ScanSpeed
						continue for
					end if
				end if
				
				if ParsingDone(PARSER_PLANET) = 0 then
					if strMatch(InStream,DID,quote("maps")+": [") then
						ParseWhat = PARSER_NONE
					end if

					if strMatch(InStream,DID,quote("planets")+": [") then
						ParseWhat = PARSER_PLANET
						ParsingDone(ParseWhat) = 1
						DID = strMatch(InStream,DID,quote("planets")+": [") - ScanSpeed
						continue for
					end if
				end if
					
				if ParsingDone(PARSER_STARBASE) = 0 then
					if strMatch(InStream,DID,quote("ionstorms")+": [") then
						ParseWhat = PARSER_NONE
					end if
					
					if strMatch(InStream,DID,quote("starbases")+": [") then
						
						'Skip converting bases if none are present (but not on the first turn)
						if ProcessSlot(PID).Bases > 0 OR TurnNum = 1 OR TurnNum < GameParser.AccelStart then
							ParseWhat = PARSER_STARBASE
						else
							ParseWhat = PARSER_NONE
						end if

						ParsingDone(PARSER_STARBASE) = 1
						DID = strMatch(InStream,DID,quote("starbases")+": [") - ScanSpeed
						continue for
					end if
				end if
					
				if ParsingDone(PARSER_SHIP) = 0 then
					if strMatch(InStream,DID,quote("ships")+": [") then
						
						'Skip converting ships if none are present (but, again, not on the first turn)
						if ProcessSlot(PID).TotalShips > 0 OR TurnNum = 1 OR TurnNum < GameParser.AccelStart then
							ParseWhat = PARSER_SHIP
						else
							ParseWhat = PARSER_NONE
						end if
						
						ParsingDone(PARSER_SHIP) = 1
						DID = strMatch(InStream,DID,quote("ships")+": [") - ScanSpeed
						continue for
					end if
				end if
					
				if ParsingDone(PARSER_NEBULAE) = 0 then
					if strMatch(InStream,DID,quote("nebulas")+": [") then
						
						'Skip converting nebulae if they are already recorded
						if PID > 1 OR  FileExists("games/"+str(GameNum)+"/Nebulae.csv") then
							ParseWhat = PARSER_NONE
						else
							ParseWhat = PARSER_NEBULAE
						end if

						ParsingDone(PARSER_NEBULAE) = 1
						DID = strMatch(InStream,DID,quote("nebulas")+": [") - ScanSpeed
						continue for
					end if
				end if
					
				if ParsingDone(PARSER_STAR_CLUSTER) = 0 then
					if strMatch(InStream,DID,quote("stars")+": [") then
						
						'Skip converting star clusters if they are already recorded
						if PID > 1 OR FileExists("games/"+str(GameNum)+"/StarClusters.csv") then
							ParseWhat = PARSER_NONE
						else
							ParseWhat = PARSER_STAR_CLUSTER
						end if

						ParsingDone(PARSER_STAR_CLUSTER) = 1
						DID = strMatch(InStream,DID,quote("stars")+": [") - ScanSpeed
						continue for
					end if
				end if
					
				if ParsingDone(PARSER_BASE_STORAGE) = 0 then
					if strMatch(InStream,DID,quote("stock")+": [") then
						
						'Skip converting base storage if no bases are present (but, yet again, not on the first turn)
						if ProcessSlot(PID).Bases > 0 OR TurnNum = 1 OR TurnNum < GameParser.AccelStart then
							ParseWhat = PARSER_BASE_STORAGE
						else
							ParseWhat = PARSER_NONE
						end if

						ParsingDone(PARSER_BASE_STORAGE) = 1
						DID = strMatch(InStream,DID,quote("stock")+": [") + 1 - ScanSpeed
						continue for
					end if
				end if
					
				if ParsingDone(PARSER_MINEFIELDS) = 0 then
					if strMatch(InStream,DID,quote("minefields")+": [") then
						ParseWhat = PARSER_MINEFIELDS
						ParsingDone(ParseWhat) = 1
						DID = strMatch(InStream,DID,quote("minefields")+": [") + 1 - ScanSpeed
						continue for
					end if
				end if
					
				if ParsingDone(PARSER_DIPLOMACY) = 0 then
					if strMatch(InStream,DID,quote("relations")+": [") then
						ParseWhat = PARSER_DIPLOMACY
						ParsingDone(ParseWhat) = 1
						DID = strMatch(InStream,DID,quote("relations")+": [") + 1 - ScanSpeed
						continue for
					end if
				end if
				
				if ParsingDone(PARSER_VCR) = 0 then
					if strMatch(InStream,DID,quote("messages")+": [") then
						ParseWhat = PARSER_NONE
					end if

					if strMatch(InStream,DID,quote("vcrs")+": [") then
						ParseWhat = PARSER_VCR
						ParsingDone(ParseWhat) = 1
						DID = strMatch(InStream,DID,quote("vcrs")+": [") + 1 - ScanSpeed
						continue for
					end if
				end if

				if strMatch(InStream,DID,quote("races")+": [") then
					exit for
				end if
				
				select case ParseWhat
					case PARSER_SETTINGS
						with GameParser
							if strMatch(InStream,DID,quote("slots")+":") then
								.PlayerCount = valint(mid(InStream,DID+8,2))
							end if
					
							if strMatch(InStream,DID,quote("mapwidth")+":") then
								.MapWidth = valint(mid(InStream,DID+11,4))
							end if
					
							if strMatch(InStream,DID,quote("mapheight")+":") then
								.MapHeight = valint(mid(InStream,DID+12,4))
							end if
					
							if strMatch(InStream,DID,quote("sphere")+":true") then
								.Sphere = 1
							end if
					
							if strMatch(InStream,DID,quote("isacademy")+":true") then
								.Academy = 1
							end if
							
							if strMatch(InStream,DID,quote("acceleratedturns")) then
								.AccelStart = valint(mid(InStream,DID+19,3))
							end if
						end with
						
					case PARSER_PLAYER
						with ProcessSlot(PID)
							if strMatch(InStream,DID,quote("raceid")) then
								RaceType = valint(mid(InStream,DID+9,2))
							end if
		
							if strMatch(InStream,DID,quote("username")) then
								for StringLen as short = 2 to 500
									.Namee = mid(InStream,DID+11,StringLen)
									if right(.Namee,1) = chr(34) then
										exit for
									end if
								next StringLen
							end if
		
							if strMatch(InStream,DID,quote("duranium")) then
								.StockDu = valint(mid(InStream,DID+11,7))
							end if
		
							if strMatch(InStream,DID,quote("tritanium")) then
								.StockTr = valint(mid(InStream,DID+12,7))
							end if
		
							if strMatch(InStream,DID,quote("molybdenum")) then
								.StockMo = valint(mid(InStream,DID+13,7))
							end if
		
							if strMatch(InStream,DID,quote("megacredits")) then
								.StockCr = valint(mid(InStream,DID+14,7))
							end if
		
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
						
					case PARSER_SCORES
						if strMatch(InStream,DID,quote("ownerid")) then
							InterPlan.PlanetOwner = valint(mid(InStream,DID+10,2))
						end if
		
						if InterPlan.PlanetOwner = PID then
							with ProcessSlot(PID)
								if strMatch(InStream,DID,quote("capitalships")) then
									.TotalShips = valint(mid(InStream,DID+15,3))
								end if
								if strMatch(InStream,DID,quote("freighters")) then
									.Freighters = valint(mid(InStream,DID+13,3))
									.TotalShips += .Freighters
								end if
								if strMatch(InStream,DID,quote("planets")) then
									.Planets = valint(mid(InStream,DID+10,3))
								end if
								if strMatch(InStream,DID,quote("starbases")) then
									.Bases = valint(mid(InStream,DID+12,3))
								end if
								if strMatch(InStream,DID,quote("militaryscore")) then
									.Military = valint(mid(InStream,DID+16,10))
								end if
							end with
						end if
						
					case PARSER_PLANET
						if strMatch(InStream,DID,quote("name")) then
							for StringLen as short = 2 to 500
								ObjName = mid(InStream,DID+7,StringLen)
								if right(ObjName,1) = chr(34) then
									exit for
								end if
							next StringLen
						end if
						if strMatch(InStream,DID,quote("friendlycode")+":"+quote("")) then
							ObjCode = ""
						elseif strMatch(InStream,DID,quote("friendlycode")) then
							for StringLen as short = 2 to 5
								ObjCode = mid(InStream,DID+15,StringLen)
								if right(ObjCode,1) = chr(34) then
									exit for
								end if
							next StringLen
						end if
						
						if right(ObjCode,1) <> chr(34) AND len(ObjCode) > 0 then
							ObjCode += chr(34)
						end if
						
						with InterPlan
							if strMatch(InStream,DID,quote("x")) then
								.XLoc = valint(mid(InStream,DID+4,4))
							end if
							if strMatch(InStream,DID,quote("y")) then
								.YLoc = valint(mid(InStream,DID+4,4))
							end if
							
							if strMatch(InStream,DID,quote("ownerid")) then
								.PlanetOwner = valint(mid(InStream,DID+10,2))
							end if
							if strMatch(InStream,DID,quote("clans")) then
								.Colonists = valint(mid(InStream,DID+8,6))
							end if
							if strMatch(InStream,DID,quote("colonisttaxrate")) then
								.ColTaxes = valint(mid(InStream,DID+18,3))
							end if
							if strMatch(InStream,DID,quote("colonisthappypoints")) then
								.ColHappy = valint(mid(InStream,DID+22,3))
							end if
							if strMatch(InStream,DID,quote("temp")) then
								.Temp = valint(mid(InStream,DID+7,3))
							end if
							if strMatch(InStream,DID,quote("infoturn")) then
								.LastScan = valint(mid(InStream,DID+11,4))
							end if
							
							if strMatch(InStream,DID,quote("nativeclans")) then
								.Natives = valint(mid(InStream,DID+14,6))
							end if
							if strMatch(InStream,DID,quote("nativetaxrate")) then
								.NatTaxes = valint(mid(InStream,DID+16,3))
							end if
							if strMatch(InStream,DID,quote("nativehappypoints")) then
								.NatHappy = valint(mid(InStream,DID+20,3))
							end if
							if strMatch(InStream,DID,quote("nativetype")) then
								.NativeType = valint(mid(InStream,DID+13,2))
							end if
							if strMatch(InStream,DID,quote("nativegovernment")) then
								.NativeGov = valint(mid(InStream,DID+19,1))
							end if
		
							if strMatch(InStream,DID,quote("neutronium")) then
								.Neu = valint(mid(InStream,DID+13,5))
							end if
							if strMatch(InStream,DID,quote("molybdenum")) then
								.Moly = valint(mid(InStream,DID+13,5))
							end if
							if strMatch(InStream,DID,quote("duranium")) then
								.Dur = valint(mid(InStream,DID+11,5))
							end if
							if strMatch(InStream,DID,quote("tritanium")) then
								.Trit = valint(mid(InStream,DID+12,5))
							end if
	
							if strMatch(InStream,DID,quote("groundneutronium")) then
								.GNeu = valint(mid(InStream,DID+19,5))
							end if
							if strMatch(InStream,DID,quote("groundmolybdenum")) then
								.GMoly = valint(mid(InStream,DID+19,5))
							end if
							if strMatch(InStream,DID,quote("groundduranium")) then
								.GDur = valint(mid(InStream,DID+17,5))
							end if
							if strMatch(InStream,DID,quote("groundtritanium")) then
								.GTrit = valint(mid(InStream,DID+18,5))
							end if
		
							if strMatch(InStream,DID,quote("densityneutronium")) then
								.DNeu = valint(mid(InStream,DID+20,3))
							end if
							if strMatch(InStream,DID,quote("densitymolybdenum")) then
								.DMoly = valint(mid(InStream,DID+20,3))
							end if
							if strMatch(InStream,DID,quote("densityduranium")) then
								.DDur = valint(mid(InStream,DID+18,3))
							end if
							if strMatch(InStream,DID,quote("densitytritanium")) then
								.DTrit = valint(mid(InStream,DID+19,3))
							end if
		
							if strMatch(InStream,DID,quote("megacredits")) then
								.Megacredits = valint(mid(InStream,DID+14,7))
							end if
							if strMatch(InStream,DID,quote("supplies")) then
								.Supplies = valint(mid(InStream,DID+11,6))
							end if
							if strMatch(InStream,DID,quote("mines")) then
								.MineralMines = valint(mid(InStream,DID+8,7))
							end if
							if strMatch(InStream,DID,quote("factories")) then
								.Factories = valint(mid(InStream,DID+12,6))
							end if
	
							if strMatch(InStream,DID,quote("debrisdisk")) then
								.Asteroid = valint(mid(InStream,DID+13,1))
							end if
						end with
						if strMatch(InStream,DID,quote("id")) then
							ObjIDa = valint(mid(InStream,DID+5,3))
						end if
						if strMatch(InStream,DID,"}") then
							if (cmdLine("--verbose") OR cmdLine("-vp")) AND InterPlan.PlanetOwner > 0 then
								print "Identified planet #"& ObjIDa;" as belonging to player "& InterPlan.PlanetOwner
							end if
							
							if InterPlan.PlanetOwner = PID then
								with PlanetParser(ObjIDa)
									if .LockOwner = 0 OR (InterPlan.Colonists > .Colonists AND TurnNum < GameParser.AccelStart) then
										print #9, "[";Time;", ";Date;"]  Registered planet #"& ObjIDa;" (";ObjName;")"
										.PlanetOwner = InterPlan.PlanetOwner
										.LockOwner = 1
										.PlanName = findReplace(ObjName,",","&")
										.FriendlyCode = findReplace(ObjCode,",","&")
										.LastScan = TurnNum
			
										.XLoc = InterPlan.XLoc
										.YLoc = InterPlan.YLoc
										.Asteroid = InterPlan.Asteroid
		
										.Colonists = InterPlan.Colonists
										.ColTaxes = InterPlan.ColTaxes
										.ColHappy = InterPlan.ColHappy
										
										.Natives = InterPlan.Natives
										.NatTaxes = InterPlan.NatTaxes
										.NatHappy = InterPlan.NatHappy
										.NativeType = InterPlan.NativeType
										.NativeGov = InterPlan.NativeGov
										
										.Temp = InterPlan.Temp
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
										.Megacredits = InterPlan.Megacredits
										.Supplies = InterPlan.Supplies
										.MineralMines = InterPlan.MineralMines
										.Factories = InterPlan.Factories
									end if
								end with
							else
								with PlanetParser(ObjIDa)
									if .LockOwner = 0 then
										.PlanetOwner = 0
										.BasePresent = 0
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
										end if
									end if
								end with
							end if
						elseif PlanetParser(ObjIDa).BasePresent = -1 then
							with PlanetParser(ObjIDa)
								.PlanName = ObjName
								.XLoc = InterPlan.XLoc
								.YLoc = InterPlan.YLoc
								.Asteroid = InterPlan.Asteroid
								.BasePresent = 0
							end with
						end if
					
					case PARSER_SHIP
						if strMatch(InStream,DID,quote("name")) then
							for StringLen as short = 2 to 500
								ObjName = mid(InStream,DID+7,StringLen)
								if right(ObjName,1) = chr(34) then
									exit for
								end if
							next StringLen
						end if
						if strMatch(InStream,DID,quote("friendlycode")+":"+quote("")) then
							ObjCode = ""
						elseif strMatch(InStream,DID,quote("friendlycode")) then
							for StringLen as short = 2 to 5
								ObjCode = mid(InStream,DID+15,StringLen)
								if right(ObjCode,1) = chr(34) then
									exit for
								end if
							next StringLen
						end if
						
						if right(ObjCode,1) <> chr(34) AND len(ObjCode) > 0 then
							ObjCode += chr(34)
						end if
						
						with InterShip
							if TempIgnore then
								if strMatch(InStream,DID,"]") then
									TempIgnore = 0
								else
									continue for
								end if
							end if
							
							if (strMatch(InStream,DID,quote("waypoints")+":[") AND strMatch(InStream,DID,quote("waypoints")+":[]") = 0) OR _
								(strMatch(InStream,DID,quote("history")+":[") AND strMatch(InStream,DID,quote("history")+":[]") = 0) then
								TempIgnore = 1
							end if
	
							if strMatch(InStream,DID,quote("x")) then
								.XLoc = valint(mid(InStream,DID+4,4))
							end if
							if strMatch(InStream,DID,quote("y")) then
								.YLoc = valint(mid(InStream,DID+4,4))
							end if
							if strMatch(InStream,DID,quote("targetx")) then
								.TargetX = valint(mid(InStream,DID+10,4))
							end if
							if strMatch(InStream,DID,quote("targety")) then
								.TargetY = valint(mid(InStream,DID+10,4))
							end if
							if strMatch(InStream,DID,quote("ownerid")) then
								.ShipOwner = valint(mid(InStream,DID+10,2))
							end if
							if strMatch(InStream,DID,quote("warp")) then
								.WarpFactor = valint(mid(InStream,DID+7,6))
							end if
							if strMatch(InStream,DID,quote("mass")) then
								.TotalMass = valint(mid(InStream,DID+7,6))
							end if
	
							if strMatch(InStream,DID,quote("beams")) then
								.BeamCount = valint(mid(InStream,DID+8,6))
							end if
							if strMatch(InStream,DID,quote("bays")) then
								.BayCount = valint(mid(InStream,DID+7,6))
							end if
							if strMatch(InStream,DID,quote("torps")) then
								.TubeCount = valint(mid(InStream,DID+8,6))
							end if
		
							if strMatch(InStream,DID,quote("clans")) then
								.Colonists = valint(mid(InStream,DID+8,6))
							end if
							if strMatch(InStream,DID,quote("neutronium")) then
								.Neu = valint(mid(InStream,DID+13,5))
							end if
							if strMatch(InStream,DID,quote("molybdenum")) then
								.Moly = valint(mid(InStream,DID+13,5))
							end if
							if strMatch(InStream,DID,quote("duranium")) then
								.Dur = valint(mid(InStream,DID+11,5))
							end if
							if strMatch(InStream,DID,quote("tritanium")) then
								.Trit = valint(mid(InStream,DID+12,5))
							end if
							if strMatch(InStream,DID,quote("megacredits")) then
								.Megacredits = valint(mid(InStream,DID+14,7))
							end if
							if strMatch(InStream,DID,quote("supplies")) then
								.Supplies = valint(mid(InStream,DID+11,6))
							end if
	
							if strMatch(InStream,DID,quote("damage")) then
								.Damage = valint(mid(InStream,DID+9,6))
							end if
							if strMatch(InStream,DID,quote("crew")) then
								.Crewmen = valint(mid(InStream,DID+7,6))
							end if
							if strMatch(InStream,DID,quote("ammo")) then
								.Ordnance = valint(mid(InStream,DID+7,6))
							end if
							if strMatch(InStream,DID,quote("hullid")) then
								.ShipType = valint(mid(InStream,DID+9,4))
							end if
							if strMatch(InStream,DID,quote("engineid")) then
								.EngineID = valint(mid(InStream,DID+11,4))
							end if
							if strMatch(InStream,DID,quote("beamid")) then
								.BeamID = valint(mid(InStream,DID+9,4))
							end if
							if strMatch(InStream,DID,quote("torpedoid")) then
								.TubeID = valint(mid(InStream,DID+12,4))
							end if
							if strMatch(InStream,DID,quote("experience")) then
								.Experience = valint(mid(InStream,DID+13,4))
							end if
	
							if strMatch(InStream,DID,quote("iscloaked")+":true") then
								.Cloaked = 1
							end if
						end with
						if strMatch(InStream,DID,quote("id")) then
							ObjIDa = valint(mid(InStream,DID+5,3))
						end if
						if strMatch(InStream,DID,"}") then
							if (cmdLine("--verbose") OR cmdLine("-vs")) AND InterShip.ShipOwner > 0 then
								print "Identified ship #"& ObjIDa;" as belonging to player "& InterShip.ShipOwner
							end if
							
							if InterShip.ShipOwner = PID then
								with ShipParser(ObjIDa)
									if .LockOwner = 0 then
										print #9, "[";Time;", ";Date;"]  Registered ship #"& ObjIDa;" (";ObjName;")"
										.ShipOwner = InterShip.ShipOwner
										.LockOwner = 1
										if len(ObjName) < 3 then
											.ShipName = "(Ship "+str(ObjIDa)+")"
										else
											.ShipName = findReplace(ObjName,",","&")
										end if
										.ShipType = InterShip.ShipType
										.FriendlyCode = findReplace(ObjCode,",","&")
										.XLoc = InterShip.XLoc
										.YLoc = InterShip.YLoc
										.TargetX = InterShip.TargetX
										.TargetY = InterShip.TargetY
										.WarpFactor = InterShip.WarpFactor
										.TotalMass = InterShip.TotalMass
										
										.EngineID = InterShip.EngineID
										.BeamCount = InterShip.BeamCount
										.BeamID = InterShip.BeamID
										.TubeCount = InterShip.TubeCount
										.TubeID = InterShip.TubeID
										.BayCount = InterShip.BayCount
										
										.Colonists = InterShip.Colonists
										.Neu = InterShip.Neu
										.Dur = InterShip.Dur
										.Trit = InterShip.Trit
										.Moly = InterShip.Moly
										.Megacredits = InterShip.Megacredits
										.Supplies = InterShip.Supplies
										.Ordnance = InterShip.Ordnance
										
										.Damage = InterShip.Damage
										.Crewmen = InterShip.Crewmen
										.Cloaked = InterShip.Cloaked
										.Experience = InterShip.Experience
										InterShip.Cloaked = 0
									end if
								end with
							end if
						end if
						
					case PARSER_STARBASE
						with InterBase
							if strMatch(InStream,DID,quote("defense")) then
								.OrbitalDef = valint(mid(InStream,DID+10,6))
							end if
							if strMatch(InStream,DID,quote("damage")) then
								.DamageLev = valint(mid(InStream,DID+9,6))
							end if
							if strMatch(InStream,DID,quote("fighters")) then
								.Fighters = valint(mid(InStream,DID+11,6))
							end if
							
							if strMatch(InStream,DID,quote("enginetechlevel")) then
								.EngineTech = valint(mid(InStream,DID+18,3))
							end if
							if strMatch(InStream,DID,quote("hulltechlevel")) then
								.HullTech = valint(mid(InStream,DID+16,3))
							end if
							if strMatch(InStream,DID,quote("beamtechlevel")) then
								.BeamTech = valint(mid(InStream,DID+16,3))
							end if
							if strMatch(InStream,DID,quote("torptechlevel")) then
								.TorpTech = valint(mid(InStream,DID+16,3))
							end if
							
							if strMatch(InStream,DID,quote("buildengineid")) then
								.UseEngine = valint(mid(InStream,DID+16,3))
							end if
							if strMatch(InStream,DID,quote("buildhullid")) then
								.UseHull = valint(mid(InStream,DID+14,3))
							end if
							if strMatch(InStream,DID,quote("buildbeamid")) then
								.UseBeam = valint(mid(InStream,DID+14,3))
							end if
							if strMatch(InStream,DID,quote("buildtorpedoid")) then
								.UseTorp = valint(mid(InStream,DID+17,3))
							end if

							if strMatch(InStream,DID,quote("isbuilding")+":false") then
								.UseEngine = 0
								.UseHull = 0
								.UseBeam = 0
								.UseTorp = 0
							end if
						end with
					
						if strMatch(InStream,DID,quote("planetid")) then
							ObjIDa = valint(mid(InStream,DID+11,3))
						end if

						if strMatch(InStream,DID,quote("id")) then
							ObjIDb = valint(mid(InStream,DID+5,3))
						end if
							
						if strMatch(InStream,DID,"}") then
							if PlanetParser(ObjIDa).PlanetOwner = PID then
								print #9, "[";Time;", ";Date;"]  Registered starbase #"& ObjIDa
								with PlanetParser(ObjIDa)
									.BasePresent = ObjIDb
								end with
								
								with BaseParser(ObjIDa)
									.OrbitalDef = InterBase.OrbitalDef
									.DamageLev = InterBase.DamageLev
									.Fighters = InterBase.Fighters
									.EngineTech = InterBase.EngineTech
									.HullTech = InterBase.HullTech
									.BeamTech = InterBase.BeamTech
									.TorpTech = InterBase.TorpTech
									.UseEngine = InterBase.UseEngine
									.UseHull = InterBase.UseHull
									.UseBeam = InterBase.UseBeam
									.UseTorp = InterBase.UseTorp
								end with
							end if
						end if
						
					case PARSER_BASE_STORAGE
						with StockParser(StorageID)
							if strMatch(InStream,DID,quote("stocktype")) then
								.ItemType = valint(mid(InStream,DID+12,2))
							end if
							if strMatch(InStream,DID,quote("stockid")) then
								.ItemId = valint(mid(InStream,DID+10,4))
							end if
							if strMatch(InStream,DID,quote("amount")) then
								.ItemAmt = valint(mid(InStream,DID+9,5))
							end if
							if strMatch(InStream,DID,quote("starbaseid")) then
								.StarbaseId = valint(mid(InStream,DID+13,3))
							end if
						end with

						if strMatch(InStream,DID,"}") then
							StorageID += 1
						end if
						
					case PARSER_MINEFIELDS
						with InterMinef
							if strMatch(InStream,DID,quote("ownerid")) then
								.MineOwner = valint(mid(InStream,DID+10,2))
							end if
							if strMatch(InStream,DID,quote("isweb")+":true") then
								.Webfield = 1
							end if
							if strMatch(InStream,DID,quote("units")) then
								.Units = valint(mid(InStream,DID+8,6))
							end if
							if strMatch(InStream,DID,quote("x")) then
								.XLoc = valint(mid(InStream,DID+4,4))
							end if
							if strMatch(InStream,DID,quote("y")) then
								.YLoc = valint(mid(InStream,DID+4,4))
							end if
							if strMatch(InStream,DID,quote("radius")) then
								.Radius = valint(mid(InStream,DID+9,3))
							end if

							if strMatch(InStream,DID,quote("friendlycode")+":"+quote("")) then
								ObjCode = ""
							elseif strMatch(InStream,DID,quote("friendlycode")) then
								for StringLen as short = 2 to 5
									ObjCode = mid(InStream,DID+15,StringLen)
									if right(ObjCode,1) = chr(34) then
										exit for
									end if
								next StringLen
							end if
							
							if right(ObjCode,1) <> chr(34) AND len(ObjCode) > 0 then
								ObjCode += chr(34)
							end if
					
							if strMatch(InStream,DID,quote("id")) then
								ObjIDa = valint(mid(InStream,DID+5,3))
							end if
						end with

						if strMatch(InStream,DID,"}") then
							if (cmdLine("--verbose") OR cmdLine("-vm")) AND InterShip.ShipOwner > 0 then
								print "Identified minefield #"& ObjIDa;" as belonging to player "& InterMinef.MineOwner
							end if

							with MinefParser(ObjIDa)
								if InterMinef.MineOwner = PID then
									print #9, "[";Time;", ";Date;"]  Registered minefield #"& ObjIDa
									.MineOwner = InterMinef.MineOwner
									.Webfield = InterMinef.Webfield
									.Units = InterMinef.Units
									.XLoc = InterMinef.XLoc
									.YLoc = InterMinef.YLoc
									.Radius = InterMinef.Radius
									.FCode = ObjCode
								end if
							end with
						end if
						
					case PARSER_STAR_CLUSTER
						if strMatch(InStream,DID,quote("name")) then
							for StringLen as short = 2 to 500
								ObjName = mid(InStream,DID+7,StringLen)
								if right(ObjName,1) = chr(34) then
									exit for
								end if
							next StringLen
						end if
						with InterStar
							if strMatch(InStream,DID,quote("x")) then
								.XLoc = valint(mid(InStream,DID+4,4))
							end if
							if strMatch(InStream,DID,quote("y")) then
								.YLoc = valint(mid(InStream,DID+4,4))
							end if
							if strMatch(InStream,DID,quote("temp")) then
								.Temp = valint(mid(InStream,DID+7,5))
							end if
							if strMatch(InStream,DID,quote("radius")) then
								.Radius = valint(mid(InStream,DID+9,3))
							end if
							if strMatch(InStream,DID,quote("mass")) then
								.Mass = valint(mid(InStream,DID+7,5))
							end if
							if strMatch(InStream,DID,quote("planets")) then
								.Planets = valint(mid(InStream,DID+10,3))
							end if
						end with
						if strMatch(InStream,DID,quote("id")) then
							ObjIDa = valint(mid(InStream,DID+5,3))
						end if
	
						if strMatch(InStream,DID,"}") AND PID < 2 then
							if cmdLine("--verbose") OR cmdLine("-vc") then
								print "Identified star cluster #"& ObjIDa
							end if

							print #9, "[";Time;", ";Date;"]  Registered star cluster #"& ObjIDa
							with StarParser(ObjIDa)
								.ClustName = ObjName
								.XLoc = InterStar.XLoc
								.YLoc = InterStar.YLoc
								.Temp = InterStar.Temp
								.Radius = InterStar.Radius
								.Mass = InterStar.Mass
								.Planets = InterStar.Planets
							end with
						end if
						
					case PARSER_NEBULAE
						if strMatch(InStream,DID,quote("name")) then
							for StringLen as short = 2 to 500
								ObjName = mid(InStream,DID+7,StringLen)
								if right(ObjName,1) = chr(34) then
									exit for
								end if
							next StringLen
						end if
						with InterNeb
							if strMatch(InStream,DID,quote("x")) then
								.XLoc = valint(mid(InStream,DID+4,4))
							end if
							if strMatch(InStream,DID,quote("y")) then
								.YLoc = valint(mid(InStream,DID+4,4))
							end if
							if strMatch(InStream,DID,quote("radius")) then
								.Radius = valint(mid(InStream,DID+9,3))
							end if
							if strMatch(InStream,DID,quote("intensity")) then
								.Intense = valint(mid(InStream,DID+12,3))
							end if
							if strMatch(InStream,DID,quote("gas")) then
								.Gas = valint(mid(InStream,DID+6,3))
							end if
						end with
						if strMatch(InStream,DID,quote("id")) then
							ObjIDa = valint(mid(InStream,DID+5,3))
						end if
	
						if strMatch(InStream,DID,"}") AND PID < 2 then
							if cmdLine("--verbose") OR cmdLine("-vn") then
								print "Identified a part of nebulae #"& ObjIDa
							end if

							print #9, "[";Time;", ";Date;"] Registered a part of nebula #"& ObjIDa
							with NebParser(ObjIDa)
								.NebName = ObjName
								.XLoc = InterNeb.XLoc
								.YLoc = InterNeb.YLoc
								.Radius = InterNeb.Radius
								.Intense = InterNeb.Intense
								.Gas = InterNeb.Gas
							end with
						end if
						
					case PARSER_DIPLOMACY
						with RelateParser(RelateID)
							if strMatch(InStream,DID,quote("playerid")) then
								.FromPlr = valint(mid(InStream,DID+11,2))
							end if
							if strMatch(InStream,DID,quote("playertoid")) then
								.ToPlr = valint(mid(InStream,DID+13,3))
							end if
							if strMatch(InStream,DID,quote("relationto")) then
								.RelationA = valint(mid(InStream,DID+13,5))
							end if
							if strMatch(InStream,DID,quote("relationfrom")) then
								.RelationB = valint(mid(InStream,DID+15,3))
							end if
							if strMatch(InStream,DID,quote("conflictlevel")) then
								.ConflictLev = valint(mid(InStream,DID+16,3))
							end if
						end with

						if strMatch(InStream,DID,"}") then
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
						end if
						
					case PARSER_VCR
						with VCRParser(CombatID)
							if AssignVCRSide = 0 then
								if strMatch(InStream,DID,quote("seed")) then
									.Seed = valint(mid(InStream,DID+7,3))
								end if
								if strMatch(InStream,DID,quote("x")) then
									.XLoc = valint(mid(InStream,DID+4,4))
								end if
								if strMatch(InStream,DID,quote("y")) then
									.YLoc = valint(mid(InStream,DID+4,4))
								end if
								if strMatch(InStream,DID,quote("battletype")) then
									.Battletype = valint(mid(InStream,DID+13,2))
								end if
								if strMatch(InStream,DID,quote("leftownerid")) then
									.LeftOwner = valint(mid(InStream,DID+14,2))
								end if
								if strMatch(InStream,DID,quote("rightownerid")) then
									.RightOwner = valint(mid(InStream,DID+15,2))
								end if
								if strMatch(InStream,DID,quote("turn")) then
									.Turn = valint(mid(InStream,DID+7,3))
								end if
								if strMatch(InStream,DID,quote("id")) then
									.InternalID = valint(mid(InStream,DID+5,7))
								end if
							end if
							if strMatch(InStream,DID,quote("left")+": {") then
								AssignVCRSide = 1
							end if
							if strMatch(InStream,DID,quote("right")+": {") then
								AssignVCRSide = 2
							end if
							
							if AssignVCRSide > 0 then
								with .Combatants(AssignVCRSide)
									if strMatch(InStream,DID,quote("objectid")) then
										.PieceID = valint(mid(InStream,DID+11,3))
									end if
									if strMatch(InStream,DID,quote("name")) then
										for StringLen as short = 2 to 500
											ObjName = mid(InStream,DID+7,StringLen)
											if right(ObjName,1) = chr(34) then
												exit for
											end if
										next StringLen
										.Namee = ObjName
									end if
									if strMatch(InStream,DID,quote("beamcount")) then
										.BeamCt = valint(mid(InStream,DID+12,2))
									end if
									if strMatch(InStream,DID,quote("launchercount")) then
										.TubeCt = valint(mid(InStream,DID+16,2))
									end if
									if strMatch(InStream,DID,quote("baycount")) then
										.BayCt = valint(mid(InStream,DID+11,2))
									end if
									if strMatch(InStream,DID,quote("hullid")) then
										.HullID = valint(mid(InStream,DID+9,4))
									end if
									if strMatch(InStream,DID,quote("beamid")) then
										.BeamID = valint(mid(InStream,DID+9,4))
									end if
									if strMatch(InStream,DID,quote("torpedoid")) then
										.TorpID = valint(mid(InStream,DID+12,4))
									end if
									if strMatch(InStream,DID,quote("shield")) then
										.Shield = valint(mid(InStream,DID+9,4))
									end if
									if strMatch(InStream,DID,quote("damage")) then
										.Damage = valint(mid(InStream,DID+9,4))
									end if
									if strMatch(InStream,DID,quote("crew")) then
										.Crew = valint(mid(InStream,DID+7,4))
									end if
									if strMatch(InStream,DID,quote("mass")) then
										.Mass = valint(mid(InStream,DID+7,4))
									end if
									if strMatch(InStream,DID,quote("raceid")) then
										.RaceID = valint(mid(InStream,DID+7,2))
									end if
									if strMatch(InStream,DID,quote("beamkillbonus")) then
										.BeamKillX = valint(mid(InStream,DID+16,2))
									end if
									if strMatch(InStream,DID,quote("beamchargerate")) then
										.BeamChargeX = valint(mid(InStream,DID+17,2))
									end if
									if strMatch(InStream,DID,quote("torpchargerate")) then
										.TorpChargeX = valint(mid(InStream,DID+17,2))
									end if
									if strMatch(InStream,DID,quote("torpmisspercent")) then
										.TorpMissChance = valint(mid(InStream,DID+18,2))
									end if
									if strMatch(InStream,DID,quote("crewdefensepercent")) then
										.CrewDefense = valint(mid(InStream,DID+21,2))
									end if
									if strMatch(InStream,DID,quote("torpedos")) then
										.TorpAmmo = valint(mid(InStream,DID+11,2))
									end if
									if strMatch(InStream,DID,quote("fighters")) then
										.Fighters = valint(mid(InStream,DID+11,2))
									end if
									if strMatch(InStream,DID,quote("temperature")) then
										.Temperature = valint(mid(InStream,DID+17,2))
									end if
									if strMatch(InStream,DID,quote("hasstarbase")+":true") then
										.Starbase = 1
									elseif strMatch(InStream,DID,quote("hasstarbase")+":false") then
										.Starbase = 0
									end if
								end with
							end if
						end with

						if strMatch(InStream,DID,"}}") then
							if VCRParser(CombatID).LeftOwner = PID then
								/'
								if cmdLine("--verbose") OR cmdLine("-vc") then
									with RelateParser(RelateID)
										if .FromPlr < .ToPlr then
											print "Identified VCR"
										end if
									end with
								end if
								'/
								CombatID += 1
							end if
							AssignVCRSide = 0
						end if
				end select
			next
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
	createTerritory(GameNum,TurnNum,PrintTxt)

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
