declare sub cleaning
declare sub loadTurnUI(Players as ubyte)

#IFDEF __FB_WIN32__
#include "Windows.bi"
#ENDIF

#include "vbcompat.bi"
#include "ABCgfx.bi"
#include "fbgfx.bi"
#include "WordWrap.bi"
#include "NRCommon.bi"

'#DEFINE __FORCE_OFFLINE__
#IFNDEF __FORCE_OFFLINE__
	'#DEFINE __USE_ZLIB__
	#DEFINE __API_LOGIN__
	#DEFINE __DOWNLOAD_LIST__
	#DEFINE __DOWNLOAD_TURNS__
#ENDIF

#IFNDEF __FB_DOS__
#DEFINE __NR_AUDIO__
#ENDIF

using FB

/'
 ' Declares a wide variety of variables in this scope. Many are global,
 ' or even constants. Some UDTs are also in there for consolidation
 '/
const FunctionOne = chr(255,59)
const FunctionTwo = chr(255,60)
const FunctionThree = chr(255,61)
const FunctionFour = chr(255,62)
const FunctionFive = chr(255,63)
const FunctionSix = chr(255,64)
const FunctionSeven = chr(255,65)
const FunctionEight = chr(255,66)
const FunctionNine = chr(255,67)
const FunctionTen = chr(255,68)
const FunctionEleven = chr(255,133)
const FunctionTwelve = chr(255,134)
const CTRLFunctionTwelve = chr(255,138)
const UpArrow = chr(255,72)
const DownArrow = chr(255,80)
const HomeKey = chr(255,71)
const EndKey = chr(255,79)
const InsertKey = chr(255,82)
const DeleteKey = chr(255,83)
const PageUp = chr(255,73)
const PageDown = chr(255,81)
const EnterKey = chr(13)
const EscKey = chr(27)
const CtrlJ = chr(10)
const CtrlR = chr(18)

const CooldownList = 8/24
const MaxPlayers = 35
#DEFINE MetaLimit 2.5e5

type ShipSpecs
	TechLevel as byte
	HullName as string
	Mass as short
	Neu as integer
	Cargo as integer
	Crew as short
	Engines as short
	Beams as short
	Tubes as short
	FtrBays as short
	CostMC as short
	CostDur as short
	CostTrit as short
	CostMoly as short
	CostAdv as short
end type

type SlotSpecs
	Race as string
	PlayerName as string
	PlanetCount as short
	Starbases as short
	Ships as short
	Freighters as short
	MilitaryScore as integer
	EconomicScore as integer
	
	TotalNeu as integer
	TotalDur as integer
	TotalTrit as integer
	TotalMoly as integer
	TotalMoney as integer
	TotalClans as integer
	TotalSupplies as integer
	
	Relationship(35) as byte
end type

type PlanObj
	ObjName as string
	Ownership as byte
	BasePresent as short
	X as short
	Y as short
	FCode as string
	LastScan as short
	
	Colonists as integer
	ColTaxRate as short
	ColHappy as short
	Natives as integer
	NatTaxRate as short
	NatHappy as short
	NativeType as byte
	NativeGov as byte
	
	Temp as byte
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
	
	Asteroid as byte
	
	'Starbase data
	OrbDefense as short
	Fighters as short
	Damage as short
	BaseOrders(2) as short
	BaseTarget(2) as short
	TechH as byte
	TechE as byte
	TechB as byte
	TechT as byte
	UseH as byte
	UseE as byte
	UseB as byte
	UseT as byte
	
	'Horwasp data
	WorkMine as short
	WorkHarvest as short
	WorkBurrow as short
	WorkTerraform as short
	Larva as integer
	BurrowSize as integer
	PodHull as short
	PodX as short
	PodY as short
	PodWarp as byte
	PodCargo as short
end type

type StorageObj
	HullCount(100) as short
	HullReference(100) as short
	EngineCount(110) as short
	BeamCount(110) as short
	TubeCount(310) as short
	TorpCount(10) as short
end type

type ShipObj
	Ownership as ubyte
	XLoc as short
	YLoc as short
	TargetX as short
	TargetY as short
	ShipName as wstring * 255
	ShipType as short
	FCode as string
	Mission as short
	MisnTarget(2) as integer
	PrimEnemy as short
	TotalMass as short
	Experience as short
	Cloaked as byte

	Neu as integer
	Dur as integer
	Trit as integer
	Moly as integer
	Megacredits as integer
	Supplies as integer
	Colonists as short

	Ammo as short
	HullDmg as short
	Crew as short
	WarpSpeed as byte
	EnginePos as byte
	BeamNum as byte
	BeamPos as byte
	TubeNum as byte
	TubePos as byte
	BayNum as byte
	
	'Metadata not provided by turn file
	ClassName as string
	MaxCargo as short
	OrbitingPlan as short
	HullMass as short
	MaxFuel as short
	LinkId as short
end type

type MineObj
	X as short
	Y as short
	
	Ownership as ubyte
	Webbed as byte
	MineUnits as integer
	Radius as short
	FCode as string
end type

type IonObj
	ParentID as short
	X as short
	Y as short
	
	Radius as short
	Voltage as short
	Warp as byte
	Heading as short
	Growing as byte
end type

type StarObj
	Namee as string
	X as short
	Y as short
	
	Temperature as integer
	Radius as short
	Mass as integer 
	Planets as short 
end type

type NebObj
	Namee as string
	X as short
	Y as short
	
	Radius as short
	Intensity as integer
	Gas as short 
end type

type WormObj
	Namee as string
	X as short
	Y as short
	
	DestX as short
	DestY as short
	
	Stability as short
	LastScan as short
end type

type ArtiObj
	Namee as string
	X as short
	Y as short
	
	LocationType as byte
	LocationID as short
end type

type AuxObj
	Namee as string
	Coloring as uinteger
	
	ObjType as short
	ObjID as short
end type

type PartSpecs
	TechLv as short
	PartName as string
	Mass as short
	CostMc as integer
	CostDu as integer
	CostTr as integer
	CostMo as integer
	
	EngineEfficiency(9) as integer
	
	'Weapon specs
	CrewKill as short
	Blast as short
end type
type ListSpecs
	ID as uinteger
	Namee as string
	GameDesc as string
	LastTurn as ushort
	GameState as byte
end type

type ColorSpecs
	Red as ubyte
	Green as ubyte
	Blue as ubyte
end type

type ScreenSpecs
	Wideth as integer
	Height as integer
end type

type GameSpecs
	MapWidth as short
	MapHeight as short
	DynamicMap as byte
	PlayerCount as byte
	Sphere as byte
	Academy as byte
	AccelStart as short
	LastTurn as short
end type

type ViewSpecs
	X as integer
	Y as integer
	Zoom as double
end type


enum ModalView
	'Main menu
	MODE_MENU
	MODE_QUICK
	MODE_DOWNLOAD
	MODE_SETTINGS
	
	MODE_HUB_VIEW
	MODE_HUB_DL

	'Other modes
	MODE_CLIENT
	MODE_EXIT
end enum

dim shared as ListSpecs GameObj(1e6)
dim shared as ShipSpecs ShiplistObj(5000)
dim shared as StorageObj BaseStorage(MetaLimit)
dim shared as ScreenSpecs BaseScreen, CanvasScreen
dim shared as GameSpecs ViewGame
dim shared as ViewSpecs ViewPort
dim shared as SlotSpecs PlayerSlot(MaxPlayers), GrandTotal
dim shared as ColorSpecs Coloring(MaxPlayers), Rainbow
dim shared as PlanObj Planets(LimitObjs)
dim shared as ShipObj Starships(LimitObjs), ShipListIndex(LimitObjs), ResetShip
dim shared as MineObj Minefields(MetaLimit), ResetMinef
dim shared as IonObj IonStorms(LimitObjs), ResetStorm
dim shared as StarObj StarClusters(LimitObjs), ResetStar
dim shared as NebObj Nebulae(LimitObjs), ResetNeb
dim shared as WormObj Wormholes(LimitObjs), ResetWorm
dim shared as ArtiObj Artifacts(LimitObjs), ResetArti
dim shared as string PreferType, Username, APIKey, GameName, InType, ErrorMsg, WindowStr, Commentary(LimitObjs), LastProgress, NullStr
dim shared as ubyte SimpleView, BorderlessFS, ExcludeBlitzes, ExcludeMvM, ExcludeNodata, LegacyRaceNames, OfflineMode, FirstRun, CanNavigate(1), _
	TurnWIP, QueueNextSong, OldTurnFormat, ShipsFound, RedrawIslands, DevMode
dim shared as ModalView ReplayerMode = MODE_MENU
dim shared as ushort ParticipatingPlayers, RecordID, GamesPerPage, NormalObjsPerPage, BasesPerPage
dim shared as uinteger GameID, TotalGamesLoaded, SelectedIndex
dim shared as integer MouseX, MouseY, MouseError, ButtonCombo, ActualX, ActualY, DestPattern
dim shared as short FadingSelect, TurnNum, BoxGlow
dim shared as double LastPlanetUpdate, SerialRecord, Midpoint
dim shared as PartSpecs Engines(109), Beams(110), Tubes(310), TorpAmmo(310)
dim shared as any ptr IslandMap, Indeterminate
dim shared as event e

'Register the player colors
open "Nu Colorset.csv" for input as #3
for RID as short = 0 to MaxPlayers
	if eof(3) then
		exit for
	else
		with Coloring(RID)
			input #3, .Red
			input #3, .Red
			input #3, .Green
			input #3, .Blue
		end with
	end if
next RID
close #3

'Register the default ship parts
open "games/Default Partlist.csv" for input as #4
line input #4, NullStr

do
	input #4, PreferType, RecordID
	if eof(4) then
		exit do
	end if
	select case PreferType
		case "Engine"
			with Engines(RecordID)
				input #4, .TechLv
				input #4, .PartName
				input #4, .Mass
				input #4, .CostMc
				input #4, .CostDu
				input #4, .CostTr
				input #4, .CostMo
				input #4, .CrewKill
				input #4, .Blast
				for WID as byte = 1 to 9
					input #4, .EngineEfficiency(WID)
				next WID
			end with
		case "Beam"
			with Beams(RecordID)
				input #4, .TechLv
				input #4, .PartName
				input #4, .Mass
				input #4, .CostMc
				input #4, .CostDu
				input #4, .CostTr
				input #4, .CostMo
				input #4, .CrewKill
				input #4, .Blast
			end with
		case "Tube"
			with Tubes(RecordID)
				input #4, .TechLv
				input #4, .PartName
				input #4, .Mass
				input #4, .CostMc
				input #4, .CostDu
				input #4, .CostTr
				input #4, .CostMo
				input #4, .CrewKill
				input #4, .Blast
			end with
		case "Torp"
			with TorpAmmo(RecordID)
				input #4, .TechLv
				input #4, .PartName
				input #4, .Mass
				input #4, .CostMc
				input #4, .CostDu
				input #4, .CostTr
				input #4, .CostMo
				input #4, .CrewKill
				input #4, .Blast
			end with
	end select
loop
close #4

Rainbow.Red = 255
declare sub updateGameList(DownloadList as byte = 0)
declare sub recordPersonalGames
declare function isPersonalGame(SearchID as integer) as integer
#IFDEF __DOWNLOAD_TURNS__
declare sub downloadGame(GameName as string, GameID as integer)
#ENDIF
#IFNDEF __FORCE_OFFLINE__
declare sub importPrivateGame
#ENDIF

'Randomize seed
randomize timer

sub drawBox(StartX as short,StartY as short,EndX as short,EndY as short)
	BoxGlow -= 3
	if BoxGlow <= -128 then
		BoxGlow += 255
	end if

	dim as uinteger DrawColor
	dim as short PaintStr
	
	for BID as short = 0 to 4
		PaintStr = BoxGlow - (BID*24)
		while PaintStr <= -128
			PaintStr += 255
		wend
		DrawColor = rgba(128,128,255,128+abs(PaintStr))
		
		line(StartX+BID,StartY+BID)-(EndX-BID,StartY+BID),DrawColor
		line(StartX+BID,StartY+BID+1)-(StartX+BID,EndY-BID),DrawColor
		line(EndX-BID,StartY+BID+1)-(EndX-BID,EndY-BID),DrawColor
		line(StartX+BID+1,EndY-BID)-(EndX-BID-1,EndY-BID),DrawColor
	next BID
end sub

sub prepCanvas(NewWidth as short, NewHeight as short, ExtraFlags as integer = 0)
	dim as short CalcRows = int(NewHeight/16)
	screenres NewWidth, NewHeight,24,2,GFX_NO_SWITCH OR GFX_ALPHA_PRIMITIVES OR ExtraFlags
	
	'Sets a fixed character width
	width int(NewWidth/8), int(NewHeight/16)
	
	'Sets up pagination for lists
	NormalObjsPerPage = CalcRows - 5
	GamesPerPage = NormalObjsPerPage - 7
	BasesPerPage = NormalObjsPerPage - 30
	
	'Utilizes double-buffering to prevent sheering
	screenset 0,1
	
	'Use this as the basis for related operations
	with CanvasScreen
		.Wideth = NewWidth
		.Height = NewHeight
	end with
end sub

sub debugout(NewString as string)
	#IF __FB_DEBUG__
	open "stdout.txt" for append as #25
	print #25, "["+Time+"]"+NewString
	close #25
	#ENDIF
end sub

#DEFINE __CMD_LINE__
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

sub prepClientScreen
	with BaseScreen
		if .Wideth > 1024 AND .Height > 768 AND SimpleView = 0 then
			prepCanvas(.Wideth,.Height,GFX_FULLSCREEN OR (GFX_NO_FRAME AND sgn(BorderlessFS)))
		end if
	end with
end sub

sub clearData
	'Clears all data
	for RID as short = 0 to MaxPlayers
		with PlayerSlot(RID)
			.Race = ""
			.PlayerName = ""
			.PlanetCount = 0
			.Starbases = 0
			.Ships = 0
			.Freighters = 0
			.MilitaryScore = 0
			
			.TotalNeu = 0
			.TotalDur = 0
			.TotalTrit = 0
			.TotalMoly = 0
			.TotalClans = 0
			.TotalMoney = 0
			.TotalSupplies = 0
		end with
	next RID

	for Obj as short = 0 to LimitObjs
		with Planets(Obj)
			.ObjName = ""
			.Ownership = 0
			.BasePresent = 0
			.X = 0
			.Y = 0

		end with

		with Starships(Obj)
			.ShipName = ""
			.Ownership = 0
			.ShipType = 0
			.XLoc = 0
			.YLoc = 0
		end with
	next Obj
end sub

sub cycleQuickList
	for GameSlot as byte = 1 to 12
		with GameObj(GameSlot+1)
			GameObj(GameSlot).ID = .ID
			GameObj(GameSlot).Namee = .Namee
			GameObj(GameSlot).GameDesc = .GameDesc
			GameObj(GameSlot).LastTurn = .LastTurn
			GameObj(GameSlot).GameState = .GameState
		end with
	next GameSlot
end sub

sub readListFile(ApplyFilter as string, OnlyFeatured as byte, ByRef Internal as integer, Filename as string = "List.csv")
	dim as integer IgnoreLine
	dim as byte MatchSucessful
	dim as string WorkingFile, ScoreFile, AuxFile, RawFile
	
	IgnoreLine = 1
	if FileExists("games/"+Filename) AND Internal < 1e6 then
		open "games/"+Filename for input as #7
		do
			with GameObj(0)
				input #7, .ID, .Namee, .GameDesc, .LastTurn
			end with
			if IgnoreLine then
				IgnoreLine = 0
			else
				with GameObj(0)
					WorkingFile = "games/"+str(.ID)+"/"+str(.LastTurn)+"/Working"
					ScoreFile = "games/"+str(.ID)+"/"+str(.LastTurn)+"/Score.csv"
					'AuxFile = "games/"+str(.ID)+"/Nebulae.csv"
					RawFile = "raw/"+str(.ID)+"/player1-turn"+str(.LastTurn)+".trn"
				
					if FileExists(WorkingFile) then
						if Now - FileDateTime(WorkingFile) > 1/24 then
							'Assume conversions that take more than an hour have failed, and delete the working flag
							kill(WorkingFile)
						end if
						.GameState = 9
					elseif FileExists(ScoreFile) then
						if FileDateTime(ScoreFile) < DataFormat then
							if FileExists(RawFile) then
								.GameState = 8
							else
								.GameState = 7
							end if
						else
							.GameState = 2
						end if
					elseif FileExists(RawFile) then
						.GameState = 1
					else
						.GameState = 0
					end if
					
					if (ApplyFilter = "" OR left(lcase(.Namee),len(ApplyFilter)) = ApplyFilter OR left(lcase(.GameDesc),len(ApplyFilter)) = ApplyFilter) AND _
						((right(.GameDesc,5) <> "Blitz" AND .GameDesc <> "League Dogfight") OR ExcludeBlitzes = 0) AND _
						(.GameDesc <> "Mentor vs Midshipmen" OR ExcludeMvM = 0) AND _
						(.GameState <> 0 OR ReplayerMode = MODE_HUB_DL OR ExcludeNodata = 0) AND _
						((PreferType = "Zodiac Wars" AND .GameDesc = "Championship Match") OR _
						(PreferType = "Seasonal Championship" AND (.GameDesc = "Emperor Match" OR .GameDesc = "Grand Marshall Match")) OR _
						(PreferType = "Personal" AND isPersonalGame(.ID)) OR _
						PreferType = "Recent" OR OnlyFeatured = 0) then
						MatchSucessful = 1
						
						GameObj(Internal).ID = .ID
						GameObj(Internal).Namee = .Namee
						GameObj(Internal).GameDesc = .GameDesc
						GameObj(Internal).LastTurn = .LastTurn
						GameObj(Internal).GameState = .GameState
					else
						MatchSucessful = 0
					end if
				end with
				
				if MatchSucessful then
					if Internal < 13 OR OnlyFeatured = 0 then
						Internal += 1
					else
						cycleQuickList
					end if
				end if
			end if
			
			if eof(7) OR Internal >= 1e6 then
				exit do
			end if
		loop
		close #7
	end if
end sub

'Loads the game list using the filter provided (if any)
sub loadGameList(ApplyFilter as string = "", OnlyFeatured as byte = 0)
	dim as integer Index = 1
	'Verifies that the official game list exists
	if FileExists("games/List.csv") = 0 then
		TotalGamesLoaded = 0
		exit sub
	end if
	
	'Loads the official game list first
	readListFile(ApplyFilter,OnlyFeatured,Index)
	
	if OnlyFeatured = 0 OR PreferType <> "Recent" then
		'Custom games are loaded next, if there is room in the internal memory for them
		readListFile(ApplyFilter,OnlyFeatured,Index,"Custom List.csv")
	end if
	
	TotalGamesLoaded = Index - 1
	SelectedIndex = 1
end sub

#IFDEF __API_LOGIN__
declare function apiLogin as byte
#ENDIF
#IFDEF __DOWNLOAD_TURNS__
declare sub fetchStaticData
#ENDIF

sub menu
	dim as integer EventActive, MaxMenuEntries
	dim as string NetworkStr, Greeting
	windowtitle WindowStr
	
	cls
	MouseError = getmouse(MouseX,MouseY,0,ButtonCombo)
	gfxstring("Nu Replayer",10,10,10,9,5,rgb(128,255,255),rgb(0,255,255))

	gfxstring("Copyright (C) 2012 - 2024 Paul Ruediger",0,CanvasScreen.Height-15,3,3,2,rgb(255,255,255))
	if OfflineMode = 0 then
		NetworkStr = "Network okay"
		Greeting = "Welcome, "+Username
	else
		NetworkStr = "Network off"
		Greeting = "Welcome, guest"
	end if
	gfxstring(NetworkStr,CanvasScreen.Wideth-gfxlength(NetworkStr,3,3,2),CanvasScreen.Height-15,3,3,2,rgb(255,255,0))
	#IFDEF __API_LOGIN__
	gfxstring(Greeting,CanvasScreen.Wideth-gfxlength(Greeting,4,3,2),0,4,3,2,rgb(255,255,255))
	#ENDIF
	
	MaxMenuEntries = 8
	if CanvasScreen.Height >= 768 then
		MaxMenuEntries = 12
	end if
	
	EventActive = screenevent(@e)

	if ReplayerMode = MODE_QUICK then
		gfxstring("Quick Watch",10,100,5,4,3,rgb(255,255,0))
		for FeaturedGame as byte = 1 to min(TotalGamesLoaded,MaxMenuEntries)
			with GameObj(FeaturedGame)
				if .ID > 0 then
					if .GameState = 2 then
						gfxstring(.Namee,CanvasScreen.Wideth/2+10,50*(FeaturedGame+(13-MaxMenuEntries))-5,3,3,2,rgb(255,255,255))
						gfxstring(.GameDesc+" / Turn "+str(.LastTurn),CanvasScreen.Wideth/2+30,50*(FeaturedGame+(13-MaxMenuEntries))+15,3,3,2,rgb(255,255,255))

						if MouseY >= 40 + 50*(FeaturedGame+(12-MaxMenuEntries)) AND MouseY < 85 + 50*(FeaturedGame+(12-MaxMenuEntries)) AND MouseX >= CanvasScreen.Wideth/2 then
							drawBox(CanvasScreen.Wideth/2,40 + 50*(FeaturedGame+(12-MaxMenuEntries)),CanvasScreen.Wideth-1,85 + 50*(FeaturedGame+(12-MaxMenuEntries)))
							if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
								SelectedIndex = FeaturedGame
								GameID = .ID
							end if
						end if
					else
						gfxstring(.Namee,CanvasScreen.Wideth/2+10,50*(FeaturedGame+(13-MaxMenuEntries))-5,3,3,2,rgb(128,128,128))
						gfxstring(.GameDesc+" / Turn "+str(.LastTurn),CanvasScreen.Wideth/2+30,50*(FeaturedGame+(13-MaxMenuEntries))+15,3,3,2,rgb(128,128,128))
					end if
				end if
				
			end with
		next FeaturedGame
	else
		gfxstring("Quick Watch",10,100,5,4,3,rgb(255,255,255))
	end if
	
	gfxstring("Game Room",10,150,5,4,3,rgb(255,255,255))
	
	#IFDEF __FORCE_OFFLINE__
	gfxstring("Network Mode",10,200,5,4,3,rgb(128,128,128))
	#ELSE
	if OfflineMode > 0 then
		gfxstring("Network Mode",10,200,5,4,3,rgb(128,128,128))
	elseif ReplayerMode = MODE_DOWNLOAD then
		dim as double GameListAge = Now - FileDateTime("raw/listgames.txt")
		dim as double TurnDLAge = Now - FileDateTime("raw/DLturn.txt")
		if FileExists("raw/listgames.txt") = 0 then GameListAge = 1e6
		if FileExists("raw/DLturn.txt") = 0 then TurnDLAge = 1e6
		gfxstring("Network Mode",10,200,5,4,3,rgb(255,255,0))
		
		#IFDEF __API_LOGIN__
		if APIKey = "" then
			gfxstring("Log in to Planets Nu",CanvasScreen.Wideth/2+10,100,5,4,3,rgb(255,255,255))
	
			if MouseY >= 90 AND MouseY < 135 AND MouseX >= CanvasScreen.Wideth/2 then
				drawBox(CanvasScreen.Wideth/2,90,CanvasScreen.Wideth-1,134)
				if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
					while inkey <> "":wend
					if apiLogin = 0 OR APIKey = "" then
						Username = "guest"
						APIKey = ""
					else
						recordPersonalGames
					end if
				end if
			end if
		else
			gfxstring("Log out of Planets Nu",CanvasScreen.Wideth/2+10,100,5,4,3,rgb(255,255,255))
	
			if MouseY >= 90 AND MouseY < 135 AND MouseX >= CanvasScreen.Wideth/2 then
				drawBox(CanvasScreen.Wideth/2,90,CanvasScreen.Wideth-1,134)
				if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
					Username = "guest"
					APIKey = ""
					if PreferType = "Personal" then
						PreferType = "Seasonal Championship"
					end if
				end if
			end if
		end if
		#ELSE
		gfxstring("Log in to Planets Nu",CanvasScreen.Wideth/2+10,100,5,4,3,rgb(128,128,128))
		#ENDIF
		
		#IFDEF __DOWNLOAD_TURNS__
		gfxstring("Download turns",CanvasScreen.Wideth/2+10,200,5,4,3,rgb(255,255,255))
		if MouseY >= 190 AND MouseY < 235 AND MouseX >= CanvasScreen.Wideth/2 then
			drawBox(CanvasScreen.Wideth/2,190,CanvasScreen.Wideth-1,234)
			if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
				ReplayerMode = MODE_HUB_DL
			end if
		end if
		
		if DevMode then
			gfxstring("Fetch static specs data",CanvasScreen.Wideth/2+10,300,5,4,3,rgb(255,255,255))
			if MouseY >= 290 AND MouseY < 335 AND MouseX >= CanvasScreen.Wideth/2 then
				drawBox(CanvasScreen.Wideth/2,290,CanvasScreen.Wideth-1,334)
				if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
					fetchStaticData
				end if
			end if
			
			gfxstring("Present Date: "+commaSep(int(Now)),CanvasScreen.Wideth/2+10,350,5,4,3,rgb(128,128,128))
		end if

		#ELSE
		gfxstring("Download turns",CanvasScreen.Wideth/2+10,200,5,4,3,rgb(128,128,128))
		#ENDIF
		
		gfxstring("Import private game",CanvasScreen.Wideth/2+10,250,5,4,3,rgb(255,255,255))
		
		#IFDEF __DOWNLOAD_LIST__
		if GameListAge > CooldownList then
			gfxstring("Download a list",CanvasScreen.Wideth/2+10,150,5,4,3,rgb(255,255,255))
	
			if MouseY >= 140 AND MouseY < 185 AND MouseX >= CanvasScreen.Wideth/2 then
				drawBox(CanvasScreen.Wideth/2,140,CanvasScreen.Wideth-1,184)
				if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
					updateGameList(1) 
					while inkey <> "":wend
					while screenevent(@e):wend
				end if
			end if
		else
			dim as double DaysRem = CooldownList - GameListAge
			dim as double HoursRem = DaysRem * 24
			dim as integer MinutesRem = remainder(ceil(HoursRem * 60),60)
			
			dim as string MinutesStr = str(MinutesRem)
			if MinutesRem < 10 then MinutesStr = "0" + MinutesStr
			gfxstring("Download a list ("+str(int(HoursRem+1/60))+":"+MinutesStr+")",CanvasScreen.Wideth/2+10,150,5,4,3,rgb(128,128,128))
		end if
		#ELSE
		gfxstring("Download a list",CanvasScreen.Wideth/2+10,150,5,4,3,rgb(128,128,128))
		#ENDIF
	
		if MouseY >= 240 AND MouseY < 285 AND MouseX >= CanvasScreen.Wideth/2 then
			drawBox(CanvasScreen.Wideth/2,240,CanvasScreen.Wideth-1,284)
			if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
				importPrivateGame
			end if
		end if
	elseif OfflineMode = 0 then 
		gfxstring("Network Mode",10,200,5,4,3,rgb(255,255,255))
	end if
	#ENDIF
	
	if ReplayerMode = MODE_SETTINGS then
		gfxstring("Engine Options",10,(MaxMenuEntries+1)*50,5,4,3,rgb(255,255,0))

		gfxstring("Preferred quick list:",CanvasScreen.Wideth/2+10,95,3,3,2,rgb(255,255,255))
		gfxstring(PreferType,CanvasScreen.Wideth/2+30,115,3,3,2,rgb(255,255,255))

		if MouseY >= 90 AND MouseY < 135 AND MouseX >= CanvasScreen.Wideth/2 then
			drawBox(CanvasScreen.Wideth/2,90,CanvasScreen.Wideth-1,134)
			if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
				if PreferType = "Seasonal Championship" then
					PreferType = "Zodiac Wars"
				elseif PreferType = "Zodiac Wars" AND APIKey <> "" then
					PreferType = "Personal"
				elseif PreferType = "Personal" OR PreferType = "Zodiac Wars" then 
					PreferType = "Recent"
				else
					PreferType = "Seasonal Championship"
				end if
			end if
		end if

		if BaseScreen.Wideth > 1024 AND BaseScreen.Height > 768 then
			gfxstring("Condensed View:",CanvasScreen.Wideth/2+10,145,3,3,2,rgb(255,255,255))
			if SimpleView then
				gfxstring("Active",CanvasScreen.Wideth/2+30,165,3,3,2,rgb(255,255,255))
			else
				gfxstring("Disabled",CanvasScreen.Wideth/2+30,165,3,3,2,rgb(255,255,255))
			end if
	
			if MouseY >= 140 AND MouseY < 185 AND MouseX >= CanvasScreen.Wideth/2 then
				drawBox(CanvasScreen.Wideth/2,140,CanvasScreen.Wideth-1,184)
				if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
					SimpleView = 1 - SimpleView
				end if
			end if
		else
			gfxstring("Condensed View:",CanvasScreen.Wideth/2+10,145,3,3,2,rgb(128,128,128))
			gfxstring("(Overridden)",CanvasScreen.Wideth/2+30,165,3,3,2,rgb(128,128,128))
		end if

		gfxstring("Exclude short format games:",CanvasScreen.Wideth/2+10,195,3,3,2,rgb(255,255,255))
		if ExcludeBlitzes then
			gfxstring("Active",CanvasScreen.Wideth/2+30,215,3,3,2,rgb(255,255,255))
		else
			gfxstring("Disabled",CanvasScreen.Wideth/2+30,215,3,3,2,rgb(255,255,255))
		end if

		if MouseY >= 190 AND MouseY < 235 AND MouseX >= CanvasScreen.Wideth/2 then
			drawBox(CanvasScreen.Wideth/2,190,CanvasScreen.Wideth-1,234)
			if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
				ExcludeBlitzes = 1 - ExcludeBlitzes
			end if
		end if

		gfxstring("Exclude Mentor vs. Midshipmen games:",CanvasScreen.Wideth/2+10,245,3,3,2,rgb(255,255,255))
		if ExcludeMvM then
			gfxstring("Active",CanvasScreen.Wideth/2+30,265,3,3,2,rgb(255,255,255))
		else
			gfxstring("Disabled",CanvasScreen.Wideth/2+30,265,3,3,2,rgb(255,255,255))
		end if

		if MouseY >= 240 AND MouseY < 285 AND MouseX >= CanvasScreen.Wideth/2 then
			drawBox(CanvasScreen.Wideth/2,240,CanvasScreen.Wideth-1,284)
			if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
				ExcludeMvM = 1 - ExcludeMvM
			end if
		end if

		gfxstring("Exclude games with no local data:",CanvasScreen.Wideth/2+10,295,3,3,2,rgb(255,255,255))
		if ExcludeNodata then
			gfxstring("Active",CanvasScreen.Wideth/2+30,315,3,3,2,rgb(255,255,255))
		else
			gfxstring("Disabled",CanvasScreen.Wideth/2+30,315,3,3,2,rgb(255,255,255))
		end if

		if MouseY >= 290 AND MouseY < 335 AND MouseX >= CanvasScreen.Wideth/2 then
			drawBox(CanvasScreen.Wideth/2,290,CanvasScreen.Wideth-1,334)
			if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
				ExcludeNodata = 1 - ExcludeNodata
			end if
		end if

		gfxstring("Display race names:",CanvasScreen.Wideth/2+10,345,3,3,2,rgb(255,255,255))
		if LegacyRaceNames then
			gfxstring("Legacy names",CanvasScreen.Wideth/2+30,365,3,3,2,rgb(255,255,255))
		else
			gfxstring("Current names",CanvasScreen.Wideth/2+30,365,3,3,2,rgb(255,255,255))
		end if

		if MouseY >= 340 AND MouseY < 385 AND MouseX >= CanvasScreen.Wideth/2 then
			drawBox(CanvasScreen.Wideth/2,340,CanvasScreen.Wideth-1,384)
			if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
				LegacyRaceNames = 1 - LegacyRaceNames
			end if
		end if
	else
		gfxstring("Engine Options",10,(MaxMenuEntries+1)*50,5,4,3,rgb(255,255,255))
	end if
	gfxstring("Exit",10,(MaxMenuEntries+2)*50,5,4,3,rgb(255,255,255))
	
	if MouseY >= 90 AND MouseY < 135 AND MouseX < CanvasScreen.Wideth/2 then
		drawBox(0,90,CanvasScreen.Wideth/2-1,134)
		if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
			if ReplayerMode = MODE_QUICK then
				ReplayerMode = MODE_MENU
			else
				loadGameList("",1)
				ReplayerMode = MODE_QUICK
			end if 
		end if
	elseif MouseY >= 140 AND MouseY < 185 AND MouseX < CanvasScreen.Wideth/2 then
		drawBox(0,140,CanvasScreen.Wideth/2-1,184)
		if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
			ReplayerMode = MODE_HUB_VIEW
		end if
	#IFNDEF __FORCE_OFFLINE__
	elseif MouseY >= 190 AND MouseY < 235 AND MouseX < CanvasScreen.Wideth/2 AND OfflineMode = 0 then
		drawBox(0,190,CanvasScreen.Wideth/2-1,234)
		if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
			if ReplayerMode = MODE_DOWNLOAD then
				ReplayerMode = MODE_MENU
			else
				ReplayerMode = MODE_DOWNLOAD
			end if 
		end if
	#ENDIF
	elseif MouseY >= MaxMenuEntries*50 + 40 AND MouseY < (MaxMenuEntries+1)*50 + 35 AND MouseX < CanvasScreen.Wideth/2 then
		drawBox(0,MaxMenuEntries*50 + 40,CanvasScreen.Wideth/2-1,(MaxMenuEntries+1)*50 + 34)
		if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
			if ReplayerMode = MODE_SETTINGS then
				ReplayerMode = MODE_MENU
			else
				ReplayerMode = MODE_SETTINGS
			end if 
		end if
	end if
	
	if MouseY >= (MaxMenuEntries+1)*50 + 40 AND MouseY < (MaxMenuEntries+2)*50 + 35 then
		drawBox(0,(MaxMenuEntries+1)*50 + 40,CanvasScreen.Wideth-1,(MaxMenuEntries+2)*50 + 34)
		if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
			ReplayerMode = MODE_EXIT
		end if
	end if
	screencopy
	sleep 5
	InType = inkey
	
	if InType = EscKey OR InType = chr(255,107) then ReplayerMode = MODE_EXIT
end sub

declare function loadTurn(GameNum as integer, TurnNum as short, PrintTxt as byte = 1) as byte

sub replayHub(DownloadMode as byte = 0)
	loadGameList

	/'
	 ' The hub serves as a center of operations. You can view the
	 ' game list from this screen, and it is also how you open the
	 ' client. Tips and tricks will also appear when you're not in
	 ' a game
	 '/
	dim as string RMessage, GameFilter, ReplayerTips(5)
	dim as ubyte Legal, CurrentTip, TotalRows = hiWord(width)
	dim as integer TotalTurnCount = 0, LongestGame = 0, _
		ShortestGame = 9999, FastGames = 0
		
	MidPoint = GamesPerPage / 2

	do
		TotalTurnCount = 0
		FastGames = 0
		color rgb(255,255,255),rgb(0,0,0)
		windowtitle WindowStr
		cls
		color rgb(0,255,255)
		if DownloadMode = 0 then
			print "Nu Replayer Game Room"
		else
			print "Nu Replayer Download Room"
		end if
		color rgb(255,255,255)
		if OfflineMode = 1 then
			print word_wrap("WARNING: "+ErrorMsg)
		else
			if DownloadMode = 0 then
				print word_wrap("Instructions: The Nu Replayer is a specialist client "+_
					"that may be used to review various completed games by rendering "+_
					"the starmap and updating it turn by turn.\n\nThe game room allows "+_
					"to review games already downloaded.")
			else
				print word_wrap("Instructions: The download room is used to download "+_
					"new turns and add them to the local storage. The entirety of a "+_
					"game's raw files will be downloaded this way.")
			end if
		end if
		locate 7,1
		color rgb(0,255,255)
		print "Available games ("+GameFilter+"*)"
		if CanvasScreen.Wideth < 1024 then
			print "ID        Game Name                                              Turn   Status"
		else
			print "ID        Game Name                                              Game Type                   Turn   Status"
		end if
		for Index as uinteger = 1 to TotalGamesLoaded
			with GameObj(Index)
				if .ID = 0 then
					exit for
				elseif Index-SelectedIndex < ceil(MidPoint) OR _
					-1*(Index-SelectedIndex) < int(MidPoint + 1) OR _
					((Index <= GamesPerPage AND SelectedIndex < ceil(MidPoint + 0.5)) OR _
					(abs(Index-TotalGamesLoaded) < GamesPerPage AND SelectedIndex > TotalGamesLoaded - ceil(MidPoint))) then
					if SelectedIndex = Index then
						if BaseScreen.Wideth < 1024 OR BaseScreen.Height < 768 then
							Legal = 0
							RMessage = "Nu Replayer requires a 1024x768 in order to render the starmap."
						elseif .GameState = 0 OR .GameState = 7 then
							#IFDEF __DOWNLOAD_TURNS__
							if ErrorMsg <> "" then 
								Legal = 0
								RMessage = "Without an operational network, games cannot be downloaded."
							else
								Legal = DownloadMode
								if .GameState = 0 then
									if DownloadMode = 0 then
										RMessage = "You cannot download turns from here. Visit the Download room to acquire this game."
									else
										RMessage = "Game has never been downloaded. Press ENTER to begin download."
									end if
								else
									if DownloadMode = 0 then
										RMessage = "Last turn's data format is outdated, and raw files are not available."
									else
										RMessage = "Last turn's data format is outdated. Press ENTER to re-download, allowing for re-conversion."
									end if
								end if
							end if
							#ELSE
							Legal = 0
							if .GameState = 0 then
								RMessage = "Downloading turns have not yet been implemented into Nu Replayer."
							else
								RMessage = "Last turn's data format is outdated, and raw files are not available."
							end if
							#ENDIF
						elseif DownloadMode > 0 then
							Legal = 0
							RMessage = "You already have this game's data."
						elseif .GameState = 1 then
							Legal = 1
							RMessage = "Press ENTER to convert the last turn and view the game."
						elseif .GameState = 8 then
							Legal = 1
							RMessage = "Last turn's data format is outdated. Press ENTER to re-convert and view the game."
						elseif .GameState = 9 then
							Legal = 0
							RMessage = "Turn conversion is being handled elsewhere."
						else
							Legal = 1
							RMessage = "Press ENTER to view the game."
						end if
						color ,rgb(0,0,128)
					else
						color ,rgb(0,0,0)
					end if
					if DownloadMode = 0 then
						if .GameState = 0 then
							color rgb(128,128,128)
						elseif .GameState = 7 OR .GameState = 8 then
							color rgb(255,128,128)
						elseif .GameState = 1 OR .GameState = 9 then
							color rgb(128,128,255)
						else
							color rgb(255,255,0)
						end if
					else
						if .GameState = 0 then
							color rgb(0,255,0)
						elseif .GameState = 7 then
							color rgb(255,128,128)
						else
							color rgb(128,128,128)
						end if
					end if
					if CanvasScreen.Wideth < 1024 then
						'            ID        Game Name                                              Turn   Status
						print using "#######   \                                                  \   ####   ";_
							.ID;.Namee;.LastTurn;
					else
						'            ID        Game Name                                              Game Type                   Turn   Status
						print using "#######   \                                                  \   \                       \   ####   ";_
							.ID;.Namee;.GameDesc;.LastTurn;
					end if
					if DownloadMode = 0 then
						select case .GameState
							case 0
								print "No data available"
							case 1
								print "Ready for conversion"
							case 2
								print "Available for viewing"
							case 7,8
								print "Data format outdated"
							case 9
								print "Being converted externally"
						end select
					else
						select case .GameState
							case 0
								print "Ready for download"
							case 7
								print "Data format outdated"
							case else
								print "Already downloaded"
						end select
					end if
				end if
				TotalTurnCount += .LastTurn
				if .LastTurn < ShortestGame then
					ShortestGame = .LastTurn
				end if
				if .LastTurn > LongestGame then
					LongestGame = .LastTurn
				end if
				if .LastTurn < 50 then
					FastGames += 1
				end if
			end with
		next Index
		if TotalGamesLoaded = 0 then
			RMessage = "No games exist. Please broaden the filter."
		end if
		locate TotalRows-3,1
		color rgb(0,255,255),rgb(0,0,0)
		if TotalGamesLoaded > 1 then
			print TotalGamesLoaded;" games found spanning "& TotalTurnCount;" turns";
			print using " (average ###.### turns)";TotalTurnCount/TotalGamesLoaded
		elseif TotalGamesLoaded = 1 then
			print "1 game found"
		end if
		locate TotalRows-2,1
		color rgb(255,0,255)
		print RMessage
		color rgb(255,255,255)
		print "<ESC> Leave Replayer Hub"
		
		screencopy
		do
			sleep 5
			InType = inkey
			
			if (multikey(SC_ALT) AND multikey(SC_F4)) then
				exit do
			end if
		loop until InType <> ""
		
		if InType = UpArrow AND SelectedIndex > 1 then
			SelectedIndex -= 1
		elseif InType = DownArrow AND SelectedIndex < TotalGamesLoaded then
			SelectedIndex += 1
		elseif InType = PageUp then
			if SelectedIndex > (GamesPerPage - 1) then SelectedIndex -= (GamesPerPage - 1) else SelectedIndex = 1
		elseif InType = PageDown then
			if TotalGamesLoaded < (GamesPerPage - 1) then
				SelectedIndex = TotalGamesLoaded
			elseif SelectedIndex < TotalGamesLoaded - (GamesPerPage - 1) then
				SelectedIndex += (GamesPerPage - 1)
			else
				SelectedIndex = TotalGamesLoaded
			end if
		elseif (InType >= "a" AND InType <= "z") OR (InType >= "A" AND InType <= "Z") OR InType = chr(32) then
			GameFilter += lcase(InType)
			loadGameList(GameFilter)
		elseif InType = chr(8) then
			GameFilter = left(GameFilter,len(GameFilter)-1)
			loadGameList(GameFilter)
		elseif InType = EnterKey AND Legal = 1 then
			if DownloadMode = 0 then
				dim as byte Results
				with GameObj(SelectedIndex)
					GameID = .ID
					TurnNum = .LastTurn
					if .GameState = 1 OR .GameState = 8 then
						prepClientScreen
						LastProgress = ""
						TurnWIP = 1
						line(0,CanvasScreen.Height-32)-(CanvasScreen.Wideth-1,CanvasScreen.Height-1),rgb(0,0,0),bf
						Results = loadTurn(.ID,.LastTurn,0)
					end if
					if Results = 0 then
						.GameState = 2
					else
						GameID = 0
						InType = chr(255)
					end if
				end with
				exit do
			else
				with GameObj(SelectedIndex)
					downloadGame(.Namee,.ID)
				end with
				ReplayerMode = MODE_DOWNLOAD
				exit do
			end if
		elseif InType = chr(255,107) then
			'Ensures program is closed by hitting the X button
			ReplayerMode = MODE_EXIT
			exit do
		elseif InType = EscKey then
			GameID = 0
			if DownloadMode then
				ReplayerMode = MODE_DOWNLOAD
			else
				ReplayerMode = MODE_MENU
			end if
			exit do
		end if
	loop
end sub


