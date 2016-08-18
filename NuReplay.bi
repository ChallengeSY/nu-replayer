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
const CtrlJ = chr(10)
const CtrlR = chr(18)

const MaxPlayers = 35

const ClimateDeathRate = 10
const PopDividor = 500

const CooldownList = 20/24
const CooldownTurn = 6/24

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
	
	TerritoryValue as short
	Asteroid as byte
	
	'Starbase data
	OrbDefense as short
	Fighters as short
	Damage as short
	TechH as byte
	TechE as byte
	TechB as byte
	TechT as byte
	UseH as byte
	UseE as byte
	UseB as byte
	UseT as byte
end type

type StorageObj
	HullCount(100) as short
	HullReference(100) as short
	EngineCount(9) as short
	BeamCount(10) as short
	TubeCount(10) as short
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
	TotalMass as short
	Experience as short
	Cloaked as byte

	Neu as short
	Dur as short
	Trit as short
	Moly as short
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

type ShipSpecs
	TechLevel as byte
	HullName as string
	Mass as short
	Neu as short
	Cargo as short
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

type ColorSpecs
	Red as ubyte
	Green as ubyte
	Blue as ubyte
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
	TotalSupplies as integer
	TotalTerritory as integer
	
	Relationship(35) as byte
end type

type PartSpecs
	PartName as string
end type
type ListSpecs
	ID as uinteger
	Namee as string
	GameDesc as string
	LastTurn as ushort
	GameState as byte
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

enum ModalView
	'Main menu
	MODE_MENU
	MODE_QUICK
	MODE_DOWNLOAD
	MODE_SETTINGS
	
	MODE_HUB_VIEW
	MODE_HUB_DL

	'While inside client
	MODE_CLIENT_NORMAL
	MODE_CLIENT_ISLAND

	MODE_EXIT
end enum

#DEFINE MetaLimit 2.5e5

dim shared as ListSpecs GameObj(1e6)
dim shared as ShipSpecs ShiplistObj(5000)
dim shared as StorageObj BaseStorage(MetaLimit)
dim shared as string PreferType, Username, APIKey, GameName, InType, ErrorMsg, WindowStr, Commentary(LimitObjs), LastProgress, NullStr
dim shared as ubyte SimpleView, OfflineMode, FirstRun, CanNavigate(1), TurnWIP, QueueNextSong, OldTurnFormat, ShipsFound
dim shared as ModalView ReplayerMode = MODE_MENU
dim shared as ushort ParticipatingPlayers, TurnNum, RecordID, Territory(767,767)
dim shared as uinteger GameID, SWidth, SHeight, TotalGamesLoaded, SelectedIndex
dim shared as integer MouseX, MouseY, MouseError, ButtonCombo, ActualX, ActualY
dim shared as short FadingSelect, NearestPlan, SelectedShip, BoxGlow
dim shared as double LastPlanetUpdate, SerialRecord
dim shared as PlanObj Planets(LimitObjs)
dim shared as ShipObj Starships(LimitObjs), ShipListIndex(LimitObjs)
dim shared as SlotSpecs PlayerSlot(MaxPlayers), GrandTotal
dim shared as ColorSpecs Coloring(MaxPlayers), GameTitle
dim shared as PartSpecs Engines(9), Beams(10), Tubes(10), TorpAmmo(10)
dim shared as GameSpecs ViewGame
dim shared as any ptr TerritoryMap, IslandMap, Indeterminate
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

for PartID as byte = 1 to 9
	with Engines(PartID)
		input #4, NullStr, NullStr, NullStr
		input #4, .PartName
		line input #4, NullStr
	end with
next PartID

for PartID as byte = 1 to 10
	with Beams(PartID)
		input #4, NullStr, NullStr, NullStr
		input #4, .PartName
		line input #4, NullStr
	end with
next PartID

for PartID as byte = 1 to 10
	with Tubes(PartID)
		input #4, NullStr, NullStr, NullStr
		input #4, .PartName
		line input #4, NullStr
	end with
next PartID

for PartID as byte = 1 to 10
	with TorpAmmo(PartID)
		input #4, NullStr, NullStr, NullStr
		input #4, .PartName
		line input #4, NullStr
	end with
next PartID
close #4


GameTitle.Red = 255
declare sub updateGameList(DownloadList as byte = 0)
#IFDEF __DOWNLOAD_TURNS__
declare sub downloadGame(GameName as string, GameID as integer)
#ENDIF

'Randomize seed
randomize timer

sub drawBox(StartX as short,StartY as short,EndX as short,EndY as short)
	BoxGlow -= 3
	if BoxGlow <= -255 then
		BoxGlow += 510
	end if

	dim as uinteger DrawColor
	dim as short PaintStr
	
	for BID as short = 0 to 4
		PaintStr = BoxGlow - (BID*24)
		while PaintStr <= -255
			PaintStr += 510
		wend
		DrawColor = rgba(128,128,255,abs(PaintStr))
		
		line(StartX+BID,StartY+BID)-(EndX-BID,StartY+BID),DrawColor
		line(StartX+BID,StartY+BID+1)-(StartX+BID,EndY-BID),DrawColor
		line(EndX-BID,StartY+BID+1)-(EndX-BID,EndY-BID),DrawColor
		line(StartX+BID+1,EndY-BID)-(EndX-BID-1,EndY-BID),DrawColor
	next BID
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
	if SWidth <= 1024 OR SHeight <= 768 then
		screen 20,24,2,GFX_FULLSCREEN OR GFX_NO_SWITCH OR GFX_ALPHA_PRIMITIVES
	elseif SimpleView then
		screen 20,24,2,GFX_ALPHA_PRIMITIVES
	else
		screenres SWidth,SHeight,24,2,GFX_FULLSCREEN OR GFX_NO_SWITCH OR GFX_ALPHA_PRIMITIVES
	end if
	screenset 0,1
	
	if SWidth <= 1024 OR SHeight <= 768 OR SimpleView then
		width 128,96
	end if
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

'Loads the game list using the filter provided (if any)
sub loadGameList(ApplyFilter as string = "", OnlyFeatured as byte = 0)
	dim as integer Index, ChampionCount
	dim as string WorkingFile, ScoreFile, AuxFile, RawFile
	'Load the game list
	if FileExists("games/List.csv") = 0 then
		TotalGamesLoaded = 0
		exit sub
	end if
	
	open "games/List.csv" for input as #7
	do
		with GameObj(Index)
			input #7, .ID, .Namee, .GameDesc, .LastTurn
			.Namee = findReplace(.Namee,"&",",")
			if (ApplyFilter = "" OR Index = 0 OR left(lcase(.Namee),len(ApplyFilter)) = ApplyFilter) AND _
				((PreferType = "Academy" AND .GameDesc = "Academy Test") OR (PreferType = "Championship" AND .GameDesc = "Championship Match") OR OnlyFeatured = 0) then
				Index += 1
			end if
			
			WorkingFile = "games/"+str(.ID)+"/"+str(.LastTurn)+"/Working"
			ScoreFile = "games/"+str(.ID)+"/"+str(.LastTurn)+"/Score.csv"
			AuxFile = "games/"+str(.ID)+"/"+str(.LastTurn)+"/Starbases.csv"
			RawFile = "raw/"+str(.ID)+"/player1-turn"+str(.LastTurn)+".trn"
		
			if FileExists(WorkingFile) then
				if Now - FileDateTime(WorkingFile) > 1/24 then
					'Assume conversions that take more than an hour have failed, and delete the working flag
					kill(WorkingFile)
				end if
				.GameState = 9
			elseif FileExists(ScoreFile) then
				if FileExists(AuxFile) = 0 OR FileDateTime(AuxFile) < DataFormat then
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
		end with
		
		if eof(7) OR Index >= 1e6 then
			TotalGamesLoaded = Index - 1
			exit do
		end if
	loop 
	close #7
	SelectedIndex = 1
end sub

#IFDEF __API_LOGIN__
declare function apiLogin as byte
#ENDIF

sub menu
	dim as integer EventActive
	dim as string NetworkStr, Greeting
	windowtitle WindowStr
	
	cls
	MouseError = getmouse(MouseX,MouseY,0,ButtonCombo)
	gfxstring("Nu Replayer",10,10,10,9,5,rgb(128,255,255),rgb(0,255,255))

	gfxstring("Copyright (C) 2012 - 2016 Paul Ruediger",0,585,3,3,2,rgb(255,255,255))
	if OfflineMode = 0 then
		NetworkStr = "Network okay"
		Greeting = "Welcome, "+Username
	else
		NetworkStr = "Network off"
		Greeting = "Welcome, guest"
	end if
	gfxstring(NetworkStr,800-gfxlength(NetworkStr,3,3,2),585,3,3,2,rgb(255,255,0))
	#IFDEF __API_LOGIN__
	gfxstring(Greeting,800-gfxlength(Greeting,4,3,2),0,4,3,2,rgb(255,255,255))
	#ENDIF
	

	EventActive = screenevent(@e)

	if ReplayerMode = MODE_QUICK then
		gfxstring("Quick Watch",10,100,5,4,3,rgb(255,255,0))
		for FeaturedGame as byte = 0 to min(TotalGamesLoaded,7)
			with GameObj(FeaturedGame)
				if .ID > 0 then
					if .GameState = 2 then
						gfxstring(.Namee,410,50*(FeaturedGame+2)-5,3,3,2,rgb(255,255,255))
						gfxstring("Turn "+str(.LastTurn),430,50*(FeaturedGame+2)+15,3,3,2,rgb(255,255,255))

						if MouseY > = 90 + 50*FeaturedGame AND MouseY < 135 + 50*FeaturedGame AND MouseX >= 400 then
							drawBox(400,90 + 50*FeaturedGame,799,134 + 50*FeaturedGame)
							if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
								SelectedIndex = FeaturedGame
								GameID = .ID
							end if
						end if
					else
						gfxstring(.Namee,410,50*(FeaturedGame+2)-5,3,3,2,rgb(128,128,128))
						gfxstring("Turn "+str(.LastTurn),430,50*(FeaturedGame+2)+15,3,3,2,rgb(128,128,128))
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
			gfxstring("Log in to Planets Nu",410,100,5,4,3,rgb(255,255,255))
	
			if MouseY > = 90 AND MouseY < 135 AND MouseX >= 400 then
				drawBox(400,90,799,134)
				if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
					while inkey < > "":wend
					if apiLogin = 0 OR APIKey = "" then
						Username = "guest"
						APIKey = ""
					end if
				end if
			end if
		else
			gfxstring("Log out of Planets Nu",410,100,5,4,3,rgb(255,255,255))
	
			if MouseY > = 90 AND MouseY < 135 AND MouseX >= 400 then
				drawBox(400,90,799,134)
				if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
					Username = "guest"
					APIKey = ""
				end if
			end if
		end if
		#ELSE
		gfxstring("Log in to Planets Nu",410,100,5,4,3,rgb(128,128,128))
		#ENDIF
		
		#IFDEF __DOWNLOAD_LIST__
		if GameListAge > CooldownList then
			gfxstring("Download a list",410,150,5,4,3,rgb(255,255,255))
	
			if MouseY > = 140 AND MouseY < 185 AND MouseX >= 400 then
				drawBox(400,140,799,184)
				if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
					updateGameList(1) 
					while inkey < > "":wend
				end if
			end if
		else
			dim as double DaysRem = CooldownList - GameListAge
			dim as double HoursRem = DaysRem * 24
			dim as integer MinutesRem = remainder(ceil(HoursRem * 60),60)
			
			dim as string MinutesStr = str(MinutesRem)
			if MinutesRem < 10 then MinutesStr = "0" + MinutesStr
			gfxstring("Download a list ("+str(int(HoursRem+1/60))+":"+MinutesStr+")",410,150,5,4,3,rgb(128,128,128))
		end if
		#ELSE
		gfxstring("Download a list",410,150,5,4,3,rgb(128,128,128))
		#ENDIF
		
		#IFDEF __DOWNLOAD_TURNS__
		if TurnDLAge > CooldownTurn then
			gfxstring("Download turns",410,200,5,4,3,rgb(255,255,255))
	
			if MouseY > = 190 AND MouseY < 235 AND MouseX >= 400 then
				drawBox(400,190,799,234)
				if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
					ReplayerMode = MODE_HUB_DL
				end if
			end if
		else
			dim as double DaysRem = CooldownTurn - TurnDLAge
			dim as double HoursRem = DaysRem * 24
			dim as integer MinutesRem = remainder(ceil(HoursRem * 60),60)
			
			dim as string MinutesStr = str(MinutesRem)
			if MinutesRem < 10 then MinutesStr = "0" + MinutesStr
			gfxstring("Download turns ("+str(int(HoursRem+1/60))+":"+MinutesStr+")",410,200,5,4,3,rgb(128,128,128))
		end if

		#ELSE
		gfxstring("Download turns",410,200,5,4,3,rgb(128,128,128))
		#ENDIF
	elseif OfflineMode = 0 then 
		gfxstring("Network Mode",10,200,5,4,3,rgb(255,255,255))
	end if
	#ENDIF
	
	if ReplayerMode = MODE_SETTINGS then
		gfxstring("Engine Options",10,450,5,4,3,rgb(255,255,0))

		gfxstring("Preferred game type:",410,95,3,3,2,rgb(255,255,255))
		gfxstring(PreferType,430,115,3,3,2,rgb(255,255,255))

		if MouseY > = 90 AND MouseY < 135 AND MouseX >= 400 then
			drawBox(400,90,799,134)
			if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
				if PreferType = "Academy" then
					PreferType = "Championship"
				else
					PreferType = "Academy"
				end if
				while inkey < > "":wend
			end if
		end if

		if SWidth > 1024 AND SHeight > 768 then
			gfxstring("Condensed View:",410,145,3,3,2,rgb(255,255,255))
			if SimpleView then
				gfxstring("Active",430,165,3,3,2,rgb(255,255,255))
			else
				gfxstring("Disabled",430,165,3,3,2,rgb(255,255,255))
			end if
	
			if MouseY > = 140 AND MouseY < 185 AND MouseX >= 400 then
				drawBox(400,140,799,184)
				if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
					SimpleView = 1 - SimpleView
					while inkey < > "":wend
				end if
			end if
		else
			gfxstring("Condensed View:",410,145,3,3,2,rgb(128,128,128))
			gfxstring("(Overridden)",430,165,3,3,2,rgb(128,128,128))
		end if
	else
		gfxstring("Engine Options",10,450,5,4,3,rgb(255,255,255))
	end if
	gfxstring("Exit",10,500,5,4,3,rgb(255,255,255))
	
	if MouseY > = 90 AND MouseY < 135 AND MouseX < 400 then
		drawBox(0,90,399,134)
		if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
			if ReplayerMode = MODE_QUICK then
				ReplayerMode = MODE_MENU
			else
				loadGameList("",1)
				ReplayerMode = MODE_QUICK
			end if 
			while inkey < > "":wend
		end if
	elseif MouseY > = 140 AND MouseY < 185 AND MouseX < 400 then
		drawBox(0,140,399,184)
		if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
			ReplayerMode = MODE_HUB_VIEW
			while inkey < > "":wend
		end if
	#IFNDEF __FORCE_OFFLINE__
	elseif MouseY > = 190 AND MouseY < 235 AND MouseX < 400 AND OfflineMode = 0 then
		drawBox(0,190,399,234)
		if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
			if ReplayerMode = MODE_DOWNLOAD then
				ReplayerMode = MODE_MENU
			else
				ReplayerMode = MODE_DOWNLOAD
			end if 
			while inkey < > "":wend
		end if
	#ENDIF
	elseif MouseY > = 440 AND MouseY < 485 AND MouseX < 400 then
		drawBox(0,440,399,484)
		if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
			if ReplayerMode = MODE_SETTINGS then
				ReplayerMode = MODE_MENU
			else
				ReplayerMode = MODE_SETTINGS
			end if 
			while inkey < > "":wend
		end if
	end if
	
	if MouseY > = 490 AND MouseY < 535 then
		drawBox(0,490,799,534)
		if EventActive AND e.type = EVENT_MOUSE_BUTTON_PRESS then
			ReplayerMode = MODE_EXIT
		end if
	end if
	screencopy
	sleep 5
	InType = inkey
	
	if InType = chr(27) OR InType = chr(255,107) then ReplayerMode = MODE_EXIT
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
	dim as ubyte Legal, CurrentTip
	dim as integer TotalTurnCount = 0, LongestGame = 0, _
		ShortestGame = 9999, FastGames = 0

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
			print word_wrap("WARNING: "+ErrorMsg,100)
		else
			if DownloadMode = 0 then
				print word_wrap("Instructions: The Nu Replayer is a specialist client "+_
					"that may be used to review various completed games by rendering "+_
					"the starmap and updating it turn by turn.\n\nThe game room allows "+_
					"to review games already downloaded.",100)
			else
				print word_wrap("Instructions: The download room is used to download "+_
					"new turns and add them to the local storage.\n\nA limited subset of "+_
					"features is available in this build, but it will be completed... eventually",100)
			end if
		end if
		locate 7,1
		color rgb(0,255,255)
		print "Available games ("+GameFilter+"*)"
		print "ID        Game Name                                              Turn   Status"
		for Index as uinteger = 1 to TotalGamesLoaded
			with GameObj(Index)
				if .ID = 0 then
					exit for
				elseif abs(Index-SelectedIndex) < 13 OR _
					((Index < = 25 AND SelectedIndex < 13) OR _
					(abs(Index-TotalGamesLoaded) < 25 AND _
					SelectedIndex > TotalGamesLoaded - 13)) then
					if SelectedIndex = Index then
						if SWidth < 1024 OR SHeight < 768 then
							Legal = 0
							RMessage = "Nu Replayer requires a 1024x768 in order to render the starmap."
						elseif .GameState = 0 then
							#IFDEF __DOWNLOAD_TURNS__
							if ErrorMsg <> "" then 
								Legal = 0
								RMessage = "Without an operational network, games cannot be downloaded."
							else
								Legal = DownloadMode
								if DownloadMode = 0 then
									RMessage = "You cannot download turns from here. Visit the Download room to acquire this game."
								else
									RMessage = "Game has never been downloaded. Press ENTER to begin download."
								end if
							end if
							#ELSE
							Legal = 0
							RMessage = "Downloading turns have not yet been implemented into Nu Replayer."
							#ENDIF
						elseif DownloadMode > 0 then
							Legal = 0
							RMessage = "You already have this game's data."
						elseif .GameState = 1 then
							Legal = 1
							RMessage = "Press ENTER to convert the last turn and view the game."
						elseif .GameState = 7 then
							Legal = 0
							RMessage = "Last turn's data format is outdated, and raw files are not available."
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
						else
							color rgb(128,128,128)
						end if
					end if
					'            ID        Game Name                                              Turn   Status
					print using "#######   \                                                  \   ####   ";_
						.ID;.Namee;.LastTurn;
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
					elseif .GameState = 0 then
						print "Ready for download"
					else
						print "Already downloaded"
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
		locate 39,1
		color rgb(0,255,255),rgb(0,0,0)
		if TotalGamesLoaded > 0 then
			print TotalGamesLoaded;" games found spanning "& TotalTurnCount;" turns";
			print using " (average ###.### turns)";TotalTurnCount/TotalGamesLoaded
		elseif TotalGamesLoaded = 1 then
			print "1 game found"
		end if
		locate 40,1
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
		loop until InType < > ""
		
		if InType = UpArrow AND SelectedIndex > 1 then
			SelectedIndex -= 1
		elseif InType = DownArrow AND SelectedIndex < TotalGamesLoaded then
			SelectedIndex += 1
		elseif InType = PageUp then
			if SelectedIndex > 24 then SelectedIndex -= 24 else SelectedIndex = 1
		elseif InType = PageDown then
			if TotalGamesLoaded < 24 then
				SelectedIndex = TotalGamesLoaded
			elseif SelectedIndex < TotalGamesLoaded - 24 then
				SelectedIndex += 24
			else
				SelectedIndex = TotalGamesLoaded
			end if
		elseif (InType >= "a" AND InType <= "z") OR (InType >= "A" AND InType <= "Z") OR InType = chr(32) then
			GameFilter += lcase(InType)
			loadGameList(GameFilter)
		elseif InType = chr(8) then
			GameFilter = left(GameFilter,len(GameFilter)-1)
			loadGameList(GameFilter)
		elseif InType = chr(13) AND Legal = 1 then
			if DownloadMode = 0 then
				dim as byte Results
				with GameObj(SelectedIndex)
					GameID = .ID
					TurnNum = .LastTurn
					if .GameState = 1 OR .GameState = 8 then
						prepClientScreen
						LastProgress = ""
						TurnWIP = 1
						cls
						color rgb(255,255,255)
						print word_wrap("Now converting turn "+str(.LastTurn)+" for "+.Namee+_
							". This may take several minutes depending on game specifications...",128)
						print
						print word_wrap("Once conversion is complete, Nu Replayer will "+_
							"automatically jump to the newly created turn.",128) 
						
						line(0,748)-(1023,767),rgb(255,255,255),b
						screencopy
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
		elseif InType = chr(27) then
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
