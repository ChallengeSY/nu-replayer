#IFNDEF MetaLimit
#DEFINE MetaLimit 2.5e5
#ENDIF

type ParsePlan
	'Core elements
	PlanetOwner as ubyte
	LockOwner as ubyte
	BasePresent as short
	XLoc as short
	YLoc as short
	PlanName as string
	FriendlyCode as string
	Asteroid as byte

	'Scanning aspects
	LastScan as short
	NativesUpdated as short
	MineralsUpdated as short
	MoneyUpdated as short
	BuildingsUpdated as short

	'Colonists
	Colonists as integer
	ColTaxes as short
	ColHappy as short
	Temp as byte

	'Natives
	Natives as integer
	NativeType as byte
	NativeGov as byte
	NatTaxes as short
	NatHappy as short

	'Resources
	Neu as short
	Dur as short
	Trit as short
	Moly as short
	GNeu as short
	GDur as short
	GTrit as short
	GMoly as short
	DNeu as short
	DDur as short
	DTrit as short
	DMoly as short
	Megacredits as integer
	Supplies as integer
	MineralMines as short
	Factories as short
end type

type ParseShip
	ShipOwner as ubyte
	LockOwner as ubyte
	XLoc as short
	YLoc as short
	TargetX as short
	TargetY as short
	ShipName as wstring * 255
	ShipType as short
	FriendlyCode as string
	TotalMass as short
	Cloaked as byte
	Experience as short

	Neu as short
	Dur as short
	Trit as short
	Moly as short
	Megacredits as integer
	Supplies as integer
	Colonists as short

	Ordnance as short
	Damage as short
	Crewmen as short
	WarpFactor as byte
	EngineID as byte
	BeamCount as byte
	BeamID as byte
	TubeCount as byte
	TubeID as byte
	BayCount as byte
end type

type ParseBase
	OrbitalDef as short
	DamageLev as short
	Fighters as short

	HullTech as byte
	EngineTech as byte
	BeamTech as byte
	TorpTech as byte

	UseHull as byte
	UseEngine as byte
	UseBeam as byte
	UseTorp as byte
end type

type ParseStock
	StarbaseId as short
	ItemType as byte
	ItemId as byte
	ItemAmt as short
end type

type ParseMinef
	MineOwner as ubyte
	Webfield as ubyte
	Units as short
	XLoc as short
	YLoc as short
	Radius as short
	FCode as string
end type

type ParseStar
	ClustName as string
	XLoc as short
	YLoc as short
	Temp as integer
	Radius as short
	Mass as short
	Planets as short
end type

type ParseNebulae
	NebName as string
	XLoc as short
	YLoc as short
	Radius as short
	Intense as short
	Gas as short
end type

type ParseRelation
	FromPlr as byte
	ToPlr as byte
	RelationA as byte
	RelationB as byte
	ConflictLev as byte
end type

type ParseScore
	RaceType as string
	Namee as string
	TotalShips as short
	Freighters as short
	Planets as short
	Bases as short
	Military as longint
	
	StockDu as integer
	StockTr as integer
	StockMo as integer
	StockCr as integer
end type

type ParseCombatPiece
	PieceID as short
	Namee as string
	
	BeamCt as byte
	TubeCt as byte
	BayCt as byte
	HullID as byte
	BeamID as byte
	TorpID as byte
	
	Shield as short
	Damage as short
	Crew as short
	Mass as short
	RaceID as byte
	
	BeamKillX as byte
	BeamChargeX as byte
	TorpChargeX as byte
	TorpMissChance as byte
	CrewDefense as short
	
	TorpAmmo as short
	Fighters as short
	Temperature as short
	Starbase as byte
end type

type ParseVCR
	Seed as short
	XLoc as short
	YLoc as short
	Battletype as byte
	LeftOwner as byte
	RightOwner as byte
	Turn as byte
	InternalID as integer
	Combatants(2) as ParseCombatPiece
end type

type ParseGame
	MapWidth as short
	MapHeight as short
	DynamicMap as byte
	PlayerCount as byte
	Sphere as byte
	Academy as byte
	AccelStart as short
	LastTurn as short
end type

dim shared as ParseScore ProcessSlot(35)
dim shared as ParsePlan PlanetParser(LimitObjs), InterPlan
dim shared as ParseShip ShipParser(LimitObjs), InterShip
dim shared as ParseBase BaseParser(LimitObjs), InterBase
dim shared as ParseStar StarParser(LimitObjs), InterStar
dim shared as ParseNebulae NebParser(LimitObjs), InterNeb
dim shared as ParseStock StockParser(MetaLimit)
dim shared as ParseMinef MinefParser(MetaLimit), InterMinef
dim shared as ParseRelation RelateParser(LimitObjs)
dim shared as ParseVCR VCRParser(LimitObjs)
dim shared as ParseGame GameParser
dim shared as double KBUpdate
enum ParserModes
	PARSER_NONE
	PARSER_PLAYER
	PARSER_SCORES
	PARSER_PLANET
	PARSER_SHIP
	PARSER_STARBASE
	PARSER_BASE_STORAGE
	PARSER_MINEFIELDS
	PARSER_STAR_CLUSTER
	PARSER_NEBULAE
	PARSER_DIPLOMACY
	PARSER_VCR
	PARSER_MAX
	PARSER_SETTINGS
end enum

dim shared as short TerrMapping(768,768), MinXPos, MaxXPos, MinYPos, MaxYPos, ParsingDone(PARSER_MAX)

#IFNDEF __CMD_LINE__
function cmdLine(SearchStr as string) as byte
	dim as byte FoundStr = 0 
	for BID as short = 1 to 31
		if Command(BID) = SearchStr then
			FoundStr = 1
			exit for
		end if
	next BID
	return FoundStr
end function
#ENDIF

sub exportScores(GameID as integer, CurTurn as short)
	open "games/"+str(GameID)+"/"+str(CurTurn)+"/Score.csv" for output as #12
	print #12, quote("Race")+","+quote("Player")+","+quote("Planets")+","+quote("Starbases")+","+quote("Total Ships")+","+quote("Freighters")+","+quote("Military")
	if GameParser.Academy then
		open "games/"+str(GameID)+"/"+str(CurTurn)+"/Resources.csv" for output as #13
		print #13, quote("Player")+","+quote("Duranium")+","+quote("Tritanium")+","+quote("Molybdenum")+","+quote("Megacredits")
	end if

	for PID as byte = 1 to 35
		with ProcessSlot(PID)
			if .Namee <> "" then
				print #12, quote(.RaceType);",";.Namee;","& .Planets;","& .Bases;","& .TotalShips;","& .Freighters;","& .Military
				if GameParser.Academy then
					print #13, .Namee;","& .StockDu;","& .StockTr;","& .StockMo;","& .StockCr
				end if
			end if
		end with
	next PID
	close #12,#13
end sub

sub exportPlanetList(GameID as integer, CurTurn as short)
	dim as integer ObjID

	open "games/"+str(GameID)+"/"+str(CurTurn)+"/Planetary.csv" for output as #14
	print #14, quote("ID")+","+quote("Ownership")+","+quote("Starbase")+","+quote("FCode")+","+_
		quote("Scanned")+","+quote("Colonists")+","+quote("TaxRate")+","+quote("Happy")+","+_
		quote("Temp")+","+quote("Natives")+","+quote("TaxRate")+","+quote("Happy")+","+_
		quote("NRace")+","+quote("Gov")+","+quote("Ne")+","+quote("Du")+","+quote("Tr")+","+_
		quote("Mo")+","+quote("GNe")+","+quote("GDu")+","+quote("GTr")+","+quote("GMo")+","+_
		quote("DNe")+","+quote("DDu")+","+quote("DTr")+","+quote("DMo")+","+_
		quote("Mc")+","+quote("Sp")+","+quote("Mine")+","+quote("Fact")

	for ObjID = 1 to LimitObjs
		with PlanetParser(ObjID)
			if .PlanName <> "" then
				print #14, ""& ObjID;","& .PlanetOwner;","& .BasePresent;","& .FriendlyCode; _
					","& .LastScan;","& .Colonists;","& .ColTaxes;","& .ColHappy;","& .Temp;_
					","& .Natives;","& .NatTaxes;","& .NatHappy;","& .NativeType;","& .NativeGov; _
					","& .Neu;","& .Dur;","& .Trit;","& .Moly; _
					","& .GNeu;","& .GDur;","& .GTrit;","& .GMoly; _
					","& .DNeu;","& .DDur;","& .DTrit;","& .DMoly; _
					","& .Megacredits;","& .Supplies;","& .MineralMines;","& .Factories
			end if
		end with
	next
	close #14
end sub

sub exportShipList(GameID as integer, CurTurn as short)
	dim as integer ObjID

	open "games/"+str(GameID)+"/"+str(CurTurn)+"/Starships.csv" for output as #15
	print #15, quote("ID")+","+quote("Ownership")+","+quote("FCode")+","+quote("X")+","+_
		quote("Y")+","+quote("DestX")+","+quote("DestY")+","+quote("Name")+","+_
		quote("HullID")+","+quote("EngID")+","+quote("BmCt")+","+quote("BmID")+","+quote("BayCt")+","+_
		quote("TorpCt")+","+quote("TorpID")+","+quote("Mass")+","+quote("Ammo")+","+quote("Warp")+","+_
		quote("Colonists")+","+quote("Ne")+","+quote("Du")+","+quote("Tr")+","+quote("Mo")+","+_
		quote("Mc")+","+quote("Sp")+","+quote("Crew")+","+quote("Dmg")+","+quote("XP")+","+quote("Cl")

	for ObjID = 1 to LimitObjs
		with ShipParser(ObjID)
			if .ShipType > 0 then
				print #15, ""& ObjID;","& .ShipOwner;","& .FriendlyCode; ","& .XLoc;","& .YLoc; _
					","& .TargetX;","& .TargetY;","& .ShipName; _
					","& .ShipType;","& .EngineID;","& .BeamCount;","& .BeamID;","& .BayCount; _
					","& .TubeCount;","& .TubeID;","& .TotalMass;","& .Ordnance;","& .WarpFactor; _
					","& .Colonists;","& .Neu;","& .Dur;","& .Trit;","& .Moly; _
					","& .Megacredits;","& .Supplies;","& .Crewmen;","& .Damage;","& .Experience;","& .Cloaked
			end if
		end with
	next
	close #15
end sub

sub exportBaseList(GameID as integer, CurTurn as short)
	dim as integer ObjID

	open "games/"+str(GameID)+"/"+str(CurTurn)+"/Starbases.csv" for output as #16
	print #16, quote("ID")+","+quote("Defense")+","+quote("Fighters")+","+quote("Damage")+","+_
		quote("TechHu")+","+quote("TechEn")+","+quote("TechBm")+","+quote("TechTp")+","+_
		quote("UseHu")+","+quote("UseEn")+","+quote("UseBm")+","+quote("UseTp")

	open "games/"+str(GameID)+"/"+str(CurTurn)+"/Base Stock.csv" for output as #17
	print #17, quote("Base ID")+","+quote("Item Type")+","+quote("Item ID")+","+quote("Amount")

	for ObjID = 1 to MetaLimit
		if ObjID <= LimitObjs then
			with BaseParser(ObjID)
				if .EngineTech + .HullTech + .BeamTech + .TorpTech > 0 then
					print #16, ""& ObjID;","& .OrbitalDef;","& .Fighters;","& .DamageLev;_
					","& .HullTech;","& .EngineTech;","& .BeamTech;","& .TorpTech;_
					","& .UseHull;","& .UseEngine;","& .UseBeam;","& .UseTorp
				end if
			end with
		end if

		with StockParser(ObjID)
			if .StarbaseId > 0 then
				print #17, ""& .StarbaseId;","& .ItemType;","& .ItemId;","& .ItemAmt
			end if
		end with 
	next
	close #16, #17
end sub

sub exportMinefields(GameID as integer, CurTurn as short)
	dim as integer ObjID
	
	open "games/"+str(GameID)+"/"+str(CurTurn)+"/Minefields.csv" for output as #18
	print #18, quote("Owner")+","+quote("Webbed")+","+quote("Units")+","+quote("X")+","+_
		quote("Y")+","+quote("Radius")+","+quote("FCode")
	for ObjID = 1 to MetaLimit
		with MinefParser(ObjID)
			if .MineOwner > 0 then
				print #18, ""& .MineOwner;","& .Webfield;","& .Units;","& .XLoc;","& .YLoc;","& .Radius;","& .FCode
			end if
		end with 
	next ObjID
	close #18
end sub

sub exportStarList(GameID as integer)
	dim as integer ObjID
	dim as string FileName
	FileName = "games/"+str(GameID)+"/StarClusters.csv"

	if FileExists(FileName) = 0 then
		open FileName for output as #21
		print #21, quote("ID")+","+quote("Name")+","+quote("X")+","+quote("Y")+","+_
			quote("Temp")+","+quote("Radius")+","+quote("Mass")+","+_
			quote("Planets")
	
		for ObjID = 1 to LimitObjs
			with StarParser(ObjID)
				if len(.ClustName) > 0 then
					print #21, ""& ObjID;","& .ClustName;","& .XLoc;","& .YLoc; _
						","& .Temp;","& .Radius;","& .Mass;","& .Planets
				end if
			end with
		next
		close #21
	end if
end sub

sub exportNebList(GameID as integer)
	dim as integer ObjID
	dim as string FileName
	FileName = "games/"+str(GameID)+"/Nebulae.csv"

	if FileExists(FileName) = 0 then
		open FileName for output as #22
		print #22, quote("ID")+","+quote("Name")+","+quote("X")+","+quote("Y")+","+_
			quote("Temp")+","+quote("Radius")+","+quote("Mass")+","+_
			quote("Planets")
	
		for ObjID = 1 to LimitObjs
			with NebParser(ObjID)
				if len(.NebName) > 0 then
					print #15, ""& ObjID;","& .NebName;","& .XLoc;","& .YLoc; _
						","& .Radius;","& .Intense;","& .Gas
				end if
			end with
		next
		close #22
	end if
end sub

sub exportSettings(GameID as integer, AlwaysWrite as byte = 0)
	dim as integer ObjID
	
	if FileExists("games/"+str(GameID)+"/Settings.csv") = 0 OR AlwaysWrite > 0 then
		with GameParser
			open "games/"+str(GameID)+"/Settings.csv" for output as #23
			print #23, quote("Players");","& .PlayerCount
			print #23, quote("Width");","& .MapWidth
			print #23, quote("Height");","& .MapHeight
			print #23, quote("Dynamic");","& .DynamicMap
			print #23, quote("Wraparound");","& .Sphere
			print #23, quote("Academy");","& .Academy
			print #23, quote("AccelStart");","& .AccelStart
			close #23
		end with
	end if
end sub

sub exportRelationships(GameID as integer, CurTurn as short)
	dim as integer ObjID

	open "games/"+str(GameID)+"/"+str(CurTurn)+"/Relations.csv" for output as #19
	print #19,quote("Player A")+","+quote("Player B")+","+quote("Relation A")+","+_
		quote("Relation B")+","+quote("Conflict")
		
	for ObjID = 1 to LimitObjs
		with RelateParser(ObjID)
			if .FromPlr <> .ToPlr then
				print #19, ""& .FromPlr;","& .ToPlr;","& .RelationA;","& .RelationB;","& .ConflictLev
			end if
		end with 
	next ObjID
	close #19
end sub

sub exportVCRs(GameID as integer, CurTurn as short)
	dim as integer ObjID

	open "games/"+str(GameID)+"/"+str(CurTurn)+"/VCRs.csv" for output as #20
	print #20,quote("Seed")+","+quote("X")+","+quote("Y")+","+quote("BattleType")+","+_
		quote("OwnerA")+","+quote("OwnerB")+","+quote("Turn")+","+quote("Internal")+","+_
		quote("PieceA")+","+quote("Name")+","+quote("Beams")+","+quote("Tubes")+","+quote("Bays")+","+quote("HullType")+","+quote("BeamType")+","+quote("TorpType")+","+_
		quote("Shields")+","+quote("Damage")+","+quote("Crew")+","+quote("Mass")+","+quote("Race")+","+quote("BeamKillX")+","+quote("BeamChargeX")+","+quote("TorpChargeX")+","+_
		quote("TorpEvasion")+","+quote("CrewDefense")+","+quote("TorpAmmo")+","+quote("Fighters")+","+quote("Temp")+","+quote("Starbase")+","+_
		quote("PieceB")+","+quote("Name")+","+quote("Beams")+","+quote("Tubes")+","+quote("Bays")+","+quote("HullType")+","+quote("BeamType")+","+quote("TorpType")+","+_
		quote("Shields")+","+quote("Damage")+","+quote("Crew")+","+quote("Mass")+","+quote("Race")+","+quote("BeamKillX")+","+quote("BeamChargeX")+","+quote("TorpChargeX")+","+_
		quote("TorpEvasion")+","+quote("CrewDefense")+","+quote("TorpAmmo")+","+quote("Fighters")+","+quote("Temp")+","+quote("Starbase")
		
	for ObjID = 1 to LimitObjs
		with VCRParser(ObjID)
			if .Seed > 0 AND .InternalID <> VCRParser(ObjID-1).InternalID then
				print #20, ""& .Seed;","& .XLoc;","& .YLoc;","& .Battletype;","& .LeftOwner;","& .RightOwner;","& .Turn;","& .InternalID;",";
				
				for Plr as byte = 1 to 2
					with .Combatants(Plr)
						print #20, ""& .PieceID;",";.Namee;","& .BeamCt;","& .TubeCt;","& .BayCt;","& .HullID;","& .BeamID;","& .TorpID;","& _
							.Shield;","& .Damage;","& .Crew;","& .Mass;","& .RaceID;","& .BeamKillX;","& .BeamChargeX;","& .TorpChargeX;","& _
							.TorpMissChance;","& .CrewDefense;","& .TorpAmmo;","& .Fighters;","& .Temperature;","& .Starbase;
					end with
					
					if Plr = 1 then
						print #20, ",";
					else
						print #20, ""
					end if
				next Plr
			end if
		end with 
	next ObjID
	close #20
end sub

sub createMap(GameID as integer, CurTurn as short)
	if GameID >= 2972 AND (FileExists("games/"+str(GameID)+"/Map.csv") = 0 OR GameParser.DynamicMap > 0) then
		print #9, "[";Time;", ";Date;"] Creating map... ";
		if GameParser.DynamicMap then
			open "games/"+str(GameID)+"/"+str(CurTurn)+"/Map.csv" for output as #4
		else
			open "games/"+str(GameID)+"/Map.csv" for output as #4
		end if
		print #4, quote("ID")+","+quote("X")+","+quote("Y")+","+quote("Planet")+","+quote("Asteroid")
		for ObjID as short = 1 to LimitObjs
			with PlanetParser(ObjID)
				if len(.PlanName) > 0 then
					print #4, ""& ObjID;","& .XLoc;","& .YLoc;","& .PlanName;","& .Asteroid
				end if
			end with
		next
		
		if GameParser.MapWidth = 0 OR GameParser.MapHeight = 0 then 
			MinXPos = 1950
			MaxXPos = 2050
			MinYPos = 1950
			MaxYPos = 2050

			for ObjID as short = 1 to LimitObjs
				with PlanetParser(ObjID)
					if len(.PlanName) > 0 then
						while .XLoc < MinXPos OR .YLoc < MinYPos OR .XLoc >= MaxXPos OR .YLoc >= MaxYPos
							MinXPos -= 50
							MaxXPos += 50
							MinYPos -= 50
							MaxYPos += 50
						wend
					end if
				end with
			next
		end if
		close #4
		print #9, " Done"
	end if
end sub

sub createTerritory(GameID as integer, CurTurn as short, PrintTxt as byte)
	dim as single LeastDist, CalcDist
	dim as short MapSize, CalcX, CalcY
	with GameParser
		MapSize = max(.MapWidth,.MapHeight)
	end with

	if GameID >= 2972 AND GameParser.Academy < 1 AND (FileExists("games/"+str(GameID)+"/Territory.csv") = 0 OR GameParser.DynamicMap > 0 OR _
		(FileExists("games/"+str(GameID)+"/Settings.csv") AND FileDateTime("games/"+str(GameID)+"/Settings.csv") > FileDateTime("games/"+str(GameID)+"/Territory.csv"))) then
		print #9, "[";Time;", ";Date;"] Generating territory...";
		print #9, "Generating territory...";
		if PrintTxt then
			print "Generating territory...";
		end if
		if GameParser.DynamicMap then
			open "games/"+str(GameID)+"/"+str(CurTurn)+"/Territory.csv" for output as #5
		else
			open "games/"+str(GameID)+"/Territory.csv" for output as #5
		end if
		for TerrY as short = 0 to 767
			loadTurnTerritory(TerrY)
			
			for TerrX as short = 0 to 767
				CalcX = 2000 - int(MapSize/2) + TerrX/767*MapSize
				CalcY = 2000 - int(MapSize/2) + (767-TerrY)/767*MapSize
				
				if CalcX >= MinXPos AND CalcX <= MaxXPos AND CalcY >= MinYPos AND CalcY <= MaxYPos then
					LeastDist = 1e6
					for PID as short = 1 to LimitObjs
						with PlanetParser(PID)
							if .XLoc >= MinXPos AND .XLoc < MaxXPos AND _
								.YLoc >= MinYPos AND .YLoc < MaxYPos then
	
								CalcDist = sqr((.XLoc - CalcX)^2 + (.YLoc - CalcY)^2)
								if CalcDist < LeastDist AND len(.PlanName) > 0 then
									LeastDist = CalcDist
									TerrMapping(TerrX,TerrY) = PID
								end if
							end if
						end with
					next PID
				else
					TerrMapping(TerrX,TerrY) = 0
				end if

				print #5, ""& TerrMapping(TerrX,TerrY);
				if TerrX < 767 then
					print #5, ",";
				else
					print #5, ""
				end if
			next TerrX
		next TerrY
		close #5
		print #9, " Done"
		print " Done"
	end if
end sub

sub exportCSVfiles(GameID as integer, CurTurn as short)
	exportScores(GameID,CurTurn)
	exportPlanetList(GameID,CurTurn)
	exportShipList(GameID,CurTurn)
	exportBaseList(GameID,CurTurn)
	exportMinefields(GameID,CurTurn)
	exportNebList(GameID)
	exportRelationships(GameID,CurTurn)
	exportSettings(GameID)
	exportStarList(GameID)
	exportVCRs(GameID,CurTurn)
end sub
