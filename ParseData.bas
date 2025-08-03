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
	Asteroid as short

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
	Neu as integer
	Dur as integer
	Trit as integer
	Moly as integer
	GNeu as integer
	GDur as integer
	GTrit as integer
	GMoly as integer
	DNeu as short
	DDur as short
	DTrit as short
	DMoly as short
	Megacredits as integer
	Supplies as integer
	MineralMines as short
	Factories as short
	DefPosts as short
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
	Mission as short
	MisnTarget(2) as integer
	PrimEnemy as short
	TotalMass as short
	Cloaked as byte
	Experience as short

	Neu as integer
	Dur as integer
	Trit as integer
	Moly as integer
	Megacredits as integer
	Supplies as integer
	Colonists as short

	Ordnance as short
	Damage as short
	Crewmen as short
	Infection as short
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
	
	BaseOrders(1) as short
	BaseTarget(1) as short

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

type ParseHorwasp
	WorkMine as short
	WorkHarvest as short
	WorkBurrow as short
	WorkTerraform as short
	Larva as integer
	BurrowSize as integer
	PodHull as short
	PodCargo as short
	PodX as short
	PodY as short
	PodWarp as byte
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

type ParseIonStorm
	XLoc as short
	YLoc as short
	Radius as short
	Voltage as short
	WarpFactor as short
	StormHeading as short
	StormGrowing as byte
	ParentID as short
end type

type ParseStar
	ClustName as string
	XLoc as short
	YLoc as short
	Temp as integer
	Radius as short
	Mass as integer
	Planets as short
	Neutron as byte
end type

type ParseNebulae
	NebName as string
	XLoc as short
	YLoc as short
	Radius as short
	Intense as short
	Gas as short
end type

type ParseWormhole
	Namee as string
	XLoc as short
	YLoc as short
	TargetX as short
	TargetY as short
	Stability as short
	LastScan as short
end type

type ParseArtifact
	ArtType as byte
	Namee as string
	Discovered as byte
	LocationType as byte
	LocationId as short
	XLoc as short
	YLoc as short
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
	HullID as short
	BeamID as short
	TorpID as short
	
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
	Seed as integer
	XLoc as short
	YLoc as short
	Battletype as byte
	LeftOwner as byte
	RightOwner as byte
	Turn as short
	InternalID as integer
	Combatants(2) as ParseCombatPiece
end type

type ParseBlackHole
	Namee as string
	XLoc as short
	YLoc as short
	
	Core as short
	Band as short
end type

type ParseGame
	MapWidth as short
	MapHeight as short
	CampaignGame as byte
	DynamicMap as byte
	PlayerCount as byte
	CloudyIonStorms as byte
	Sphere as byte
	Academy as byte
	AccelStart as short
	TorpSet as byte
	LastTurn as short
end type

dim shared as ParseScore ProcessSlot(35), ResetSlotPar
dim shared as ParsePlan PlanetParser(LimitObjs), InterPlan, ResetPlanPar
dim shared as ParseShip ShipParser(LimitObjs), InterShip, ResetShipPar
dim shared as ParseBase BaseParser(LimitObjs), InterBase, ResetBasePar
dim shared as ParseHorwasp WaspParser(LimitObjs), InterWasp, ResetWaspPar
dim shared as ParseStar StarParser(LimitObjs), InterStar, ResetStarPar
dim shared as ParseIonStorm IonParser(LimitObjs), InterIon, ResetIonPar
dim shared as ParseNebulae NebParser(LimitObjs), InterNeb, ResetNebPar
dim shared as ParseStock StockParser(MetaLimit), ResetStockPar
dim shared as ParseMinef MinefParser(MetaLimit), InterMinef, ResetMinefPar
dim shared as ParseWormhole WormholeParser(LimitObjs), InterWormhole, ResetWormholePar
dim shared as ParseArtifact ArtifactParser(LimitObjs), InterArtifact, ResetArtifactPar
dim shared as ParseRelation RelateParser(LimitObjs), ResetRelationsPar
dim shared as ParseVCR VCRParser(LimitObjs), ResetVCRPar
dim shared as ParseBlackHole BlackParser(LimitObjs), InterBlack, ResetBlackPar
dim shared as ParseGame GameParser, ResetGamePar
dim shared as double KBUpdate

dim shared as short TerrMapping(768,768), MinXPos, MaxXPos, MinYPos, MaxYPos

ResetSlotPar.RaceType = "Unassigned"
ResetPlanPar.FriendlyCode = quote("???")
ResetShipPar.FriendlyCode = quote("???")
ResetMinefPar.FCode = quote("???")
ResetGamePar.MapWidth = 2000
ResetGamePar.MapHeight = 2000
for PID as byte = 1 to 2
	with ResetVCRPar.Combatants(PID)
		.BeamKillX = 1
		.BeamChargeX = 1
		.TorpChargeX = 1
		.TorpMissChance = 35
	end with
next pID

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

function getJsonVal(ReadStr as string, ReadParam as string, CharInit as integer = 1, CharEnd as integer = 0, DefVal as integer = -1) as integer
	dim as integer MatchFound = instr(CharInit,ReadStr,quote(ReadParam)+":")
	
	if MatchFound > 0 AND (MatchFound < CharEnd OR CharEnd = 0) then
		return valint(mid(ReadStr,MatchFound+len(ReadParam)+3,11))
	end if
	
	return DefVal
end function

function getJsonStr(ReadStr as string, ReadParam as string, CharInit as integer = 1, CharEnd as integer = 0) as string
	dim as integer MatchFound = instr(CharInit,ReadStr,quote(ReadParam)+":")
	dim as integer EndQuote = 0
	do
		EndQuote = instr(max(MatchFound+len(ReadParam)+4, EndQuote+1),ReadStr,chr(34))
	loop until mid(ReadStr, EndQuote-1 , 2) <> "\"+chr(34)
	
	return mid(ReadStr, MatchFound+len(ReadParam)+4, EndQuote-MatchFound-len(ReadParam)-4)
end function

function getJsonBool(ReadStr as string, ReadParam as string, CharInit as integer = 1, CharEnd as integer = 0) as integer
	dim as integer MatchFound = instr(CharInit,ReadStr,quote(ReadParam)+":")
	if MatchFound > 0 AND (MatchFound < CharEnd OR CharEnd = 0) then
		dim as string ReadVal = mid(ReadStr, MatchFound+len(quote(ReadParam))+1, 5)
		
		return abs(sgn(instr(1, ReadVal, "true") > 0))
	end if
	
	return 0
end function

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
				print #12, quote(.RaceType);",";quote(.Namee);","& .Planets;","& .Bases;","& .TotalShips;","& .Freighters;","& .Military
				if GameParser.Academy then
					print #13, quote(.Namee);","& .StockDu;","& .StockTr;","& .StockMo;","& .StockCr
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
		quote("Mc")+","+quote("Sp")+","+quote("Mine")+","+quote("Fact")+","+quote("Def")+","+_
		quote("WorkM")+","+quote("WorkH")+","+quote("WorkB")+","+quote("WorkT")+","+_
		quote("Larva")+","+quote("Burrows")+","+quote("PodHull")+","+quote("PodCargo")+","+_
		quote("PodX")+","+quote("PodY")+","+quote("PodWarp")

	for ObjID = 1 to LimitObjs
		with PlanetParser(ObjID)
			if .PlanName <> "" then
				print #14, ""& ObjID;","& .PlanetOwner;","& .BasePresent;","& quote(.FriendlyCode); _
					","& .LastScan;","& .Colonists;","& .ColTaxes;","& .ColHappy;","& .Temp;_
					","& .Natives;","& .NatTaxes;","& .NatHappy;","& .NativeType;","& .NativeGov; _
					","& .Neu;","& .Dur;","& .Trit;","& .Moly; _
					","& .GNeu;","& .GDur;","& .GTrit;","& .GMoly; _
					","& .DNeu;","& .DDur;","& .DTrit;","& .DMoly; _
					","& .Megacredits;","& .Supplies;","& .MineralMines;","& .Factories;","& .DefPosts;
					
				with WaspParser(ObjID)
					print #14, ","& .WorkMine;","& .WorkHarvest;","& .WorkBurrow;","& .WorkTerraform; _
						","& .Larva;","& .BurrowSize;","& .PodHull;","& .PodCargo; _
						","& .PodX;","& .PodY;","& .PodWarp
				end with
			end if
		end with
		
	next
	close #14
end sub

sub exportShipList(GameID as integer, CurTurn as short)
	dim as integer ObjID

	open "games/"+str(GameID)+"/"+str(CurTurn)+"/Starships.csv" for output as #15
	print #15, quote("ID")+","+quote("Ownership")+","+quote("FCode")+","+quote("Misn")+","+_
		quote("Msn1")+","+quote("Msn2")+","+quote("Enemy")+","+_
		quote("X")+","+quote("Y")+","+quote("DestX")+","+quote("DestY")+","+quote("Name")+","+_
		quote("HullID")+","+quote("EngID")+","+quote("BmCt")+","+quote("BmID")+","+quote("BayCt")+","+_
		quote("TorpCt")+","+quote("TorpID")+","+quote("Mass")+","+quote("Ammo")+","+quote("Warp")+","+_
		quote("Colonists")+","+quote("Ne")+","+quote("Du")+","+quote("Tr")+","+quote("Mo")+","+_
		quote("Mc")+","+quote("Sp")+","+quote("Crew")+","+quote("Dmg")+","+quote("XP")+","+quote("Cl")+_
		","+quote("Inf")

	for ObjID = 1 to LimitObjs
		with ShipParser(ObjID)
			if .ShipType > 0 then
				print #15, ""& ObjID;","& .ShipOwner;","& quote(.FriendlyCode); _
					","& .Mission;","& .MisnTarget(1);","& .MisnTarget(2);","& .PrimEnemy; _
					","& .XLoc;","& .YLoc;","& .TargetX;","& .TargetY;","& quote(.ShipName); _
					","& .ShipType;","& .EngineID;","& .BeamCount;","& .BeamID;","& .BayCount; _
					","& .TubeCount;","& .TubeID;","& .TotalMass;","& .Ordnance;","& .WarpFactor; _
					","& .Colonists;","& .Neu;","& .Dur;","& .Trit;","& .Moly; ","& .Megacredits;_
					","& .Supplies;","& .Crewmen;","& .Damage;","& .Experience;","& .Cloaked;","& .Infection
			end if
		end with
	next
	close #15
end sub

sub exportBaseList(GameID as integer, CurTurn as short)
	dim as integer ObjID

	open "games/"+str(GameID)+"/"+str(CurTurn)+"/Starbases.csv" for output as #16
	print #16, quote("ID")+","+quote("Defense")+","+quote("Fighters")+","+quote("Damage")+","+_
		quote("Misn1")+","+quote("Misn1Target")+","+quote("Misn2")+","+quote("Misn2Target")+","+_
		quote("TechHu")+","+quote("TechEn")+","+quote("TechBm")+","+quote("TechTp")+","+_
		quote("UseHu")+","+quote("UseEn")+","+quote("UseBm")+","+quote("UseTp")

	open "games/"+str(GameID)+"/"+str(CurTurn)+"/Base Stock.csv" for output as #17
	print #17, quote("Base ID")+","+quote("Item Type")+","+quote("Item ID")+","+quote("Amount")

	for ObjID = 1 to MetaLimit
		if ObjID <= LimitObjs then
			with BaseParser(ObjID)
				if .EngineTech + .HullTech + .BeamTech + .TorpTech > 0 then
					print #16, ""& ObjID;","& .OrbitalDef;","& .Fighters;","& .DamageLev;_
					","& .BaseOrders(1);","& .BaseTarget(1);","& .BaseOrders(2);","& .BaseTarget(2);_
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
	print #18, quote("ID")+","+quote("Owner")+","+quote("Webbed")+","+quote("Units")+","+_
		quote("X")+","+quote("Y")+","+quote("Radius")+","+quote("FCode")
	for ObjID = 1 to MetaLimit
		with MinefParser(ObjID)
			if .MineOwner > 0 then
				print #18, ""& ObjID;","& .MineOwner;","& .Webfield;","& .Units;","& .XLoc;","& .YLoc;","& .Radius;","& quote(.FCode)
			end if
		end with 
	next ObjID
	close #18
end sub

sub exportIonList(GameID as integer, CurTurn as short)
	dim as integer ObjID
	dim as string FileName
	FileName = "games/"+str(GameID)+"/"+str(CurTurn)+"/Ion Storms.csv"

	open FileName for output as #24
	print #24, quote("InternalID")+","+quote("ParentID")+","+quote("X")+","+quote("Y")+","+_
		quote("Radius")+","+quote("Voltage")+","+quote("Warp")+","+quote("Heading")+","+_
		quote("Growing")

	for ObjID = 1 to LimitObjs
		with IonParser(ObjID)
			if .Voltage > 0 then
				print #24, ""& ObjID;","& .ParentID;","& .XLoc;","& .YLoc; _
					","& .Radius;","& .Voltage;","& .WarpFactor;","& .StormHeading; _
					","& .StormGrowing
			end if
		end with
	next
	close #24
end sub

sub exportStarList(GameID as integer, AlwaysWrite as byte = 0)
	dim as integer ObjID
	dim as string FileName
	FileName = "games/"+str(GameID)+"/StarClusters.csv"

	if FileExists(FileName) = 0 OR AlwaysWrite then
		open FileName for output as #21
		print #21, quote("ID")+","+quote("Name")+","+quote("X")+","+quote("Y")+","+_
			quote("Temp")+","+quote("Radius")+","+quote("Mass")+","+_
			quote("Planets")+","+quote("Neutron")
	
		for ObjID = 1 to LimitObjs
			with StarParser(ObjID)
				if len(.ClustName) > 0 then
					print #21, ""& ObjID;","& quote(.ClustName);","& .XLoc;","& .YLoc; _
						","& .Temp;","& .Radius;","& .Mass;","& .Planets;","& .Neutron
				end if
			end with
		next
		close #21
	end if
end sub

sub exportNebList(GameID as integer, AlwaysWrite as byte = 0)
	dim as integer ObjID
	dim as string FileName
	FileName = "games/"+str(GameID)+"/Nebulae.csv"

	if FileExists(FileName) = 0 OR AlwaysWrite then
		open FileName for output as #22
		print #22, quote("ID")+","+quote("Name")+","+quote("X")+","+quote("Y")+","+_
			quote("Radius")+","+quote("Intensity")+","+quote("Gas")
	
		for ObjID = 1 to LimitObjs
			with NebParser(ObjID)
				if len(.NebName) > 0 then
					print #22, ""& ObjID;","& quote(.NebName);","& .XLoc;","& .YLoc; _
						","& .Radius;","& .Intense;","& .Gas
				end if
			end with
		next
		close #22
	end if
end sub

sub exportArtifactList(GameID as integer, CurTurn as short)
	dim as integer ObjID
	dim as string FileName
	FileName = "games/"+str(GameID)+"/"+str(CurTurn)+"/Artifacts.csv"

	open FileName for output as #24
	print #24, quote("ID")+","+quote("Name")+","+quote("X")+","+quote("Y")+","+_
		quote("LocationType")+","+quote("LocationID")

	for ObjID = 1 to LimitObjs
		with ArtifactParser(ObjID)
			if len(.Namee) > 0 then
				print #24, ""& ObjID;","& quote(.Namee);","& .XLoc;","& .YLoc; _
					","& .LocationType;","& .LocationId
			end if
		end with
	next
	close #24
end sub

sub exportWormholeList(GameID as integer, CurTurn as short)
	dim as integer ObjID
	dim as string FileName
	FileName = "games/"+str(GameID)+"/"+str(CurTurn)+"/Wormholes.csv"

	open FileName for output as #25
	print #25, quote("ID")+","+quote("Name")+","+quote("X")+","+quote("Y")+","+_
		quote("DestX")+","+quote("DestY")+","+quote("Stability")+","+_
		quote("LastInfo")

	for ObjID = 1 to LimitObjs
		with WormholeParser(ObjID)
			if len(.Namee) > 0 then
				print #25, ""& ObjID;","& quote(.Namee);","& .XLoc;","& .YLoc; _
					","& .TargetX;","& .TargetY;","& .Stability;","& .LastScan
			end if
		end with
	next
	close #25
end sub

sub exportSettings(GameID as integer, AlwaysWrite as byte = 0)
	dim as integer ObjID
	
	if FileExists("games/"+str(GameID)+"/Settings.csv") = 0 OR AlwaysWrite then
		with GameParser
			open "games/"+str(GameID)+"/Settings.csv" for output as #23
			print #23, quote("Players");","& .PlayerCount
			print #23, quote("Width");","& .MapWidth
			print #23, quote("Height");","& .MapHeight
			print #23, quote("Dynamic");","& .DynamicMap
			print #23, quote("CloudyStorms");","& .CloudyIonStorms
			print #23, quote("Wraparound");","& .Sphere
			print #23, quote("Academy");","& .Academy
			print #23, quote("AccelStart");","& .AccelStart
			print #23, quote("TorpSet");","& .TorpSet
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
	print #20,quote("Internal")+","+quote("Seed")+","+quote("X")+","+quote("Y")+","+_
		quote("BattleType")+","+quote("OwnerA")+","+quote("OwnerB")+","+quote("Turn")+",";
		
	for Plr as byte = 65 to 66
		print #20, quote("Piece"+chr(Plr))+","+quote("Name")+","+quote("Beams")+","+quote("Tubes")+","+quote("Bays")+","+quote("HullType")+","+_
			quote("BeamType")+","+quote("TorpType")+","+quote("Shields")+","+quote("Damage")+","+quote("Crew")+","+quote("Mass")+","+_
			quote("Race")+","+quote("BeamKillX")+","+quote("BeamChargeX")+","+quote("TorpChargeX")+","+quote("TorpEvasion")+","+quote("CrewDefense")+","+_
			quote("TorpAmmo")+","+quote("Fighters")+","+quote("Temp")+","+quote("Starbase");
		
		if Plr = 65 then
			print #20, ",";
		else
			print #20, ""
		end if
	next Plr

	for ObjID = 1 to LimitObjs
		with VCRParser(ObjID)
			if .LeftOwner > 0 AND .RightOwner > 0 then
				print #20, ""& .InternalID;","& .Seed;","& .XLoc;","& .YLoc;","& .Battletype;","& .LeftOwner;","& .RightOwner;","& .Turn;",";
				
				for Plr as byte = 1 to 2
					with .Combatants(Plr)
						print #20, ""& .PieceID;","; quote(.Namee);","& .BeamCt;","& .TubeCt;","& .BayCt;","& .HullID;","& .BeamID;","& .TorpID;","& _
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

sub exportBlackHoles(GameID as integer, AlwaysWrite as byte = 0)
	dim as integer ObjID
	
	if FileExists("games/"+str(GameID)+"/BlackHoles.csv") = 0 OR AlwaysWrite then
		open "games/"+str(GameID)+"/BlackHoles.csv" for output as #26
		print #26, quote("ID")+","+quote("Name")+","+quote("X")+","+quote("Y")+","+_
			quote("Core")+","+quote("Band")
	
		for ObjID = 1 to LimitObjs
			with BlackParser(ObjID)
				if len(.Namee) > 0 then
					print #26, ""& ObjID;","& quote(.Namee);","& .XLoc;","& .YLoc; _
						","& .Core;","& .Band
				end if
			end with
		next
		close #26
	end if
end sub

sub createMap(GameID as integer, CurTurn as short)
	if GameID >= 2972 AND (GameParser.DynamicMap > 0 OR _
		FileExists("games/"+str(GameID)+"/Map.csv") = 0 OR FileDateTime("games/"+str(GameID)+"/Map.csv") < DataFormat) then
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
					print #4, ""& ObjID;","& .XLoc;","& .YLoc;","& quote(.PlanName);","& .Asteroid
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

sub exportCSVfiles(GameID as integer, CurTurn as short)
	exportScores(GameID,CurTurn)
	exportPlanetList(GameID,CurTurn)
	exportShipList(GameID,CurTurn)
	exportBaseList(GameID,CurTurn)
	exportMinefields(GameID,CurTurn)
	exportNebList(GameID, FileDateTime("games/"+str(GameID)+"/Nebulae.csv") < DataFormat)
	exportIonList(GameID,CurTurn)
	exportRelationships(GameID,CurTurn)
	exportArtifactList(GameID,CurTurn)
	exportWormholeList(GameID,CurTurn)
	exportSettings(GameID, FileDateTime("games/"+str(GameID)+"/Settings.csv") < DataFormat)
	exportStarList(GameID, FileDateTime("games/"+str(GameID)+"/StarClusters.csv") < DataFormat)
	exportVCRs(GameID,CurTurn)
	exportBlackHoles(GameID, FileDateTime("games/"+str(GameID)+"/BlackHoles.csv") < DataFormat)
end sub
