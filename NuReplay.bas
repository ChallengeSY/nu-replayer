#include "NuReplay.bi"
declare sub loadTurnKB(KBCount as integer, Players as ubyte)
declare sub loadTurnTerritory(AmtDone as short)

#include "LoadTurn.bi"

#IFDEF __NR_AUDIO__
#include "NRAudio.bas"
#ENDIF

#include "NREngine.bas"
#include "NRClient.bas"

#include "ListGames.bi"

sub cleaning destructor
	open "Settings.csv" for output as #1
	print #1, quote("Login");",";Username
	print #1, quote("Key");",";APIKey
	print #1, quote("Preferred Type");",";PreferType
	print #1, quote("Simple View");",";SimpleView
	close #1
	
	ImageDestroy(TerritoryMap)
	ImageDestroy(IslandMap)
	ImageDestroy(Indeterminate)
	#IFNDEF __FORCE_OFFLINE__
	SDLNet_Quit
	#ENDIF
	#IFDEF __NR_AUDIO__
	Mix_CloseAudio
	SDL_Quit
	#ENDIF
end sub

WindowStr = BROWSER_LONG

'Checks desktop size and acts accordingly
Screencontrol GET_DESKTOP_SIZE, SWidth, SHeight

if SWidth < 800 OR SHeight < 600 then
	/'
	 'If desktop size does not meet program requirements, it reports an
	 'error and closes
	 '/
	open "stderr.txt" for output as #9
	print #9, "Nu Replayer requires 800x600 in order to run." 
	close #9
	
	cleaning
	end -2
elseif SWidth = 800 OR SHeight = 600 then
	/'
	 ' If the desktop size is equal to the hub requirements on
	 ' either side, then it forces fullscreen. Access to most
	 ' features are disabled
	 '/
	screen 19,24,2,GFX_FULLSCREEN OR GFX_NO_SWITCH OR GFX_ALPHA_PRIMITIVES
else
	/'
	 ' If the desktop size is greater than the hub requirements on
	 ' both sides, then it forces to a window to allow a graceful
	 ' switch in window size.
	 '/
	screen 19,24,2,GFX_NO_SWITCH OR GFX_ALPHA_PRIMITIVES
end if

if screenptr = 0 then
	'Error setting video mode
	open "stderr.txt" for output as #9
	print #9, "Video mode was not successfully established" 
	close #9
	
	cleaning
	end -2
end if

if FileExists("Login.csv") AND FileExists("Settings.csv") = 0 then name("Login.csv","Settings.csv")

Username = "guest"
APIKey = ""
PreferType = "Academy"
SimpleView = 0

if FileExists("Settings.csv") then
	open "Settings.csv" for input as #1
	do
		input #1, NullStr
		select case NullStr
			case "Login"
				input #1, Username
			case "Key"
				input #1, APIKey
			case "Preferred Type"
				input #1, PreferType
			case "Simple View"
				input #1, SimpleView
		end select
	loop until eof(1)
	close #1
	if APIKey = "" then Username = "guest"
end if

'Utilizes double-buffering to prevent sheering
screenset 0,1
'Creates the territory and island maps
TerritoryMap = ImageCreate(768,768)
IslandMap =  ImageCreate(768,768)

Indeterminate = ImageCreate(50,20)
line Indeterminate,(0,0)-(49,19),rgb(0,0,0),bf
for Plot as byte = 0 to 24
	line Indeterminate,(Plot,19)-(Plot+19,0),rgb(48,48,80)
next Plot

/'
 ' If Nu Replayer has online support, then it attempts to initialize
 ' SDL and connect to Planets Nu's servers
 '/
#IFDEF __FORCE_OFFLINE__
OfflineMode = 1
ErrorMsg = "Nu Replayer network connectivity is disabled in this build."
#ELSE
if SDLNet_Init <> 0 AND OfflineMode = 0 then
	OfflineMode = 1
	ErrorMsg = "Nu Replayer is unable to initialize SDL, which it needs to connect online."
end if

if SDLNet_ResolveHost( @NuIP, DEFAULT_HOST, 80 ) <> 0 AND OfflineMode = 0  then
	OfflineMode = 1
	ErrorMsg = "Nu Replayer is unable to successfully resolve a connection with Planets Nu's servers."
end if
#ENDIF

updateGameList

'In case some people don't like the music, a command option has been provided
#IFDEF __NR_AUDIO__
if cmdLine("-s") = 0 AND cmdLine("--silent") = 0 then
	loadMusic("Menu")
end if
#ENDIF

#IF __FB_DEBUG__
kill("stdout.txt")
#ENDIF

do
	select case ReplayerMode
		case MODE_MENU, MODE_QUICK, MODE_DOWNLOAD, MODE_SETTINGS
			menu
			if GameID > 0 then
				clearData
				loadGame(GameID)
				prepClientScreen
			end if
		case MODE_HUB_VIEW
			replayHub
			if GameID > 0 then
				clearData
				loadGame(GameID)
				if TurnWIP then
					TurnWIP = 0
				else
					prepClientScreen
				end if
				if QueueNextSong then
					QueueNextSong = 0
					#IFDEF __NR_AUDIO__
					cycleMusic
					#ENDIF
				end if
			end if
		case MODE_HUB_DL
			replayHub(1)
		case else
			renderClient
	end select

	if (multikey(SC_ALT) AND multikey(SC_F4)) then
		exit do
	end if
loop until ReplayerMode = MODE_EXIT
