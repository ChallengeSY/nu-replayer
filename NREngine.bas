#IF NOT defined(__FORCE_OFFLINE__) AND NOT defined(__FB_DOS__)
	/'
	 ' When Nu Replayer has online support, then it will includes the libraries
	 ' necessary to interact with Planets Nu.
	 '
	 ' SDL is needed to connect to Planets Nu. Likewise, zlib is needed to
	 ' decompress data
	 '/
	
	#include "SDL/SDL_net.bi"
	#IFDEF __USE_ZLIB__
	#include "zlib.bi"
	#ENDIF
#ENDIF

#include "NREngine.bi"
#IFNDEF __FORCE_OFFLINE__
#include "NRturnDL.bi"
#ENDIF
#include "NRprivate.bi"

declare function listGames as integer

sub updateGameList(DownloadList as byte = 0)
	#IFNDEF __FORCE_OFFLINE__
	dim as longint BytesDownloaded = 0	
	
	if DownloadList then
		createMeter(0,"Downloading raw game list... (finalizing prep)")
		screencopy

		dim SendBuffer as string
		dim RecvBuffer as zstring * RECVBUFFLEN+1
		dim Bytes as integer
		dim FirstRead as integer
		dim TotalBytes as integer

		#IFDEF __USE_ZLIB__
		#ELSE
		SendBuffer = loadAddress("games/list?compress=false&scope=0&status=3&type=2,3,4,6,7")
		NuSocket = SDLNet_TCP_Open( @NuIP )
		if( NuSocket = 0 ) then
			ErrorMsg = "Nu Replayer did not successfully open a socket to Planets Nu's servers."
		else
			if SDLNet_TCP_Send(NuSocket, strptr(SendBuffer), len(SendBuffer)) < len(SendBuffer) then
				ErrorMsg = "Nu Replayer did not successfully send its request to Planets Nu's servers."
			else
				mkdir "raw"
				open "raw/listgames.txt" for output as #7

				do
					Bytes = SDLNet_TCP_Recv( NuSocket, strptr( RecvBuffer ), RECVBUFFLEN )
					if Bytes <= 0 then
						exit do
					end if
					
					'' add the null-terminator
					RecvBuffer[Bytes] = 0
					
					if FirstRead = 0 then
						FirstRead = instr(RecvBuffer,"Content-Length:")
						if FirstRead > 0 then
							TotalBytes = valint(mid(RecvBuffer,FirstRead+16,10))
						end if
						
						FirstRead = -1
					end if
					
					'' print it as string
					print #7, RecvBuffer;
					BytesDownloaded += Bytes
					
					if TotalBytes > 0 then
						createMeter(min(BytesDownloaded/TotalBytes, 1.0),"Downloading raw game list... ("+commaSep(BytesDownloaded/1e3)+" / "+commaSep(TotalBytes/1e3)+" KB downloaded)")
					else
						createMeter(0,"Downloading raw game list... ("+commaSep(BytesDownloaded/1e3)+" KB downloaded)")
					end if
					screencopy
				loop
				close #7
			end if
		end if
		SDLNet_TCP_Close( NuSocket )
		#ENDIF
	end if
	#ENDIF

	if FileDateTime("raw/listgames.txt") > FileDateTime("games/List.csv") then
		createMeter(1,"Converting game list...")
		screencopy
		if listGames then
			print " Failure! Could not load game list.";
			dim as integer ErrorNum = kill("raw/listgames.txt")
			if ErrorNum then
				print " Could not delete damaged raw file (" & ErrorNum;").";
			end if
			screencopy
			sleep
		end if
	end if
end sub

sub loadGame(ByRef LoadID as uinteger)
 	'Loads an existing game into Nu Replayer.

	dim as byte Result
	if LoadID > 0 then
		dim as string SettingsFile, MapFile, ShiplistFile

		dim as ubyte LineStr(1 to 3) => {162, 81, 49}
		dim as short AdjustX, AdjustY, LoadObjID, MapSize, AbsMin

		dim as double NearestDist, CalcDist
		if Dir("games/"+str(GameID), fbDirectory) <> "" then
			with GameObj(SelectedIndex)
				GameName = .Namee
				ViewGame.LastTurn = .LastTurn
			end with
			SettingsFile = "games/"+str(GameID)+"/Settings.csv"

			with ViewGame
				.MapWidth = 0
				.MapHeight = 0
				.PlayerCount = 0
				.Sphere = 0
				.Academy = 0
				.AccelStart = 0
				.TorpSet = 0
				if FileExists(SettingsFile) then
					open SettingsFile for input as #2
					do
						input #2, NullStr
						select case NullStr
							case "Players"
								input #2, .PlayerCount
							case "Width"
								input #2, .MapWidth
							case "Height"
								input #2, .MapHeight
							case "Dynamic"
								input #2, .DynamicMap
							case "Wraparound"
								input #2, .Sphere
							case "Academy"
								input #2, .Academy
							case "AccelStart"
								input #2, .AccelStart
							case "TorpSet"
								input #2, .TorpSet
						end select
					loop until eof(2)
					close #2
					
					MapSize = max(.MapWidth,.MapHeight)
					AbsMin = 2000 - MapSize/2
				end if
			end with

			with ViewGame
				for TurnID as short = .LastTurn to 1 step -1
					if Dir("games/"+str(GameID)+"/"+str(TurnID), fbDirectory) <> "" then
						TurnNum = TurnID
						exit for
					end if
				next TurnID

				if .DynamicMap then
					MapFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Map.csv"
				else
					MapFile = "games/"+str(GameID)+"/Map.csv"
				end if
				ShiplistFile = "games/"+str(GameID)+"/Shiplist.csv"
				
				if .Academy then
					with ViewPort
						.Zoom = 16
						DistQuota = 2.9
					end with
				end if
			end with

			open "debugout.txt" for output as #19
			if FileExists(ShiplistFile) then
				open ShiplistFile for input as #3
				do
					if eof(3) then
						exit do
					else
						input #3, LoadObjID
						with ShiplistObj(LoadObjID)
							input #3, .TechLevel
							input #3, .HullName
							input #3, .Mass
							input #3, .Neu
							input #3, .Cargo
							input #3, .Crew
							input #3, .Engines
							input #3, .Beams
							input #3, .Tubes
							input #3, .FtrBays
							input #3, .CostMC
							input #3, .CostDur
							input #3, .CostTrit
							input #3, .CostMoly
							input #3, .CostAdv
						end with
					end if
				loop
				close #3
			else
				open "games/Default Shiplist.csv" for input as #3
				do
					if eof(3) then
						exit do
					else
						input #3, LoadObjID
						with ShiplistObj(LoadObjID)
							input #3, .TechLevel
							input #3, .HullName
							input #3, .Mass
							input #3, .Neu
							input #3, .Cargo
							input #3, .Crew
							input #3, .Engines
							input #3, .Beams
							input #3, .Tubes
							input #3, .FtrBays
							input #3, .CostMC
							input #3, .CostDur
							input #3, .CostTrit
							input #3, .CostMoly
							input #3, .CostAdv
						end with
					end if
				loop
				close #3
			end if

			if FileExists(MapFile) then
				with ViewGame
					if .MapWidth > 0 AND .MapHeight > 0 then
						MinXPos = 2000 - .MapWidth/2
						MaxXPos = MinXPos + .MapWidth
						MinYPos = 2000 - .MapHeight/2
						MaxYPos = MinYPos + .MapHeight
					else
						MinXPos = 1950
						MaxXPos = 2050
						MapSize = 100
						AbsMin = 1950
					end if

					open MapFile for input as #3
					for PID as short = 0 to LimitObjs
						if eof(3) then
							exit for
						else
							input #3, LoadObjID
							with Planets(LoadObjID)
								input #3, .X
								input #3, .Y
								input #3, .ObjName
								input #3, .Asteroid

								if PID > 0 AND .ObjName <> "" AND (ViewGame.MapWidth = 0 OR ViewGame.MapHeight = 0) then
									while .X < MinXPos OR .Y < MinXPos OR .X >= MaxXPos OR .Y >= MaxXPos
										MinXPos -= 50
										MaxXPos += 50
										
										MapSize += 100
										AbsMin -= 50
									wend
								end if

								.ObjName = findReplace(.ObjName,"&",",")
							end with
						end if
					next PID
					close #3

					if .MapWidth = 0 OR .MapHeight = 0 then
						MinYPos = MinXPos
						MaxYPos = MaxXPos
					end if
				end with
			else
				MinXPos = 1000
				MaxXPos = 3000
				MinYPos = MinXPos
				MaxYPos = MaxXPos
				MapSize = 2000
				AbsMin = 1000

				open "games/Default Map.csv" for input as #3
				for PID as short = 0 to 500
					if eof(3) then
						exit for
					else
						input #3, LoadObjID
						with Planets(LoadObjID)
							input #3, .X
							input #3, .Y
							input #3, .ObjName
							input #3, .Asteroid

							.ObjName = findReplace(.ObjName,"&",",")
						end with
					end if
				next PID
				close #3
			end if

			loadTurnExtras
		end if

		close #19
	end if

	ReplayerMode = MODE_CLIENT
end sub

sub recordPersonalGames
	dim SendBuffer as string
	dim RecvBuffer as zstring * RECVBUFFLEN+1
	dim Bytes as integer
	dim LinesReceived as ushort
	
	dim as string URLName, InStream
	dim as integer GamesRegistered
	color rgb(255,255,255),rgb(0,0,0)
	cls
	print "Loading personal games..."
	screencopy

	for Char as short = 1 to len(Username)
		if mid(Username,Char,1) = space(1) then
			URLName += "%20"
		else
			URLName += mid(Username,Char,1)
		end if
	next Char
	
	for PersonalSlot as byte = 1 to 12
		PersonalIDs(PersonalSlot) = 0
	next PersonalSlot

	#IFDEF __USE_ZLIB__
	#ELSE
	SendBuffer = loadAddress("games/list?compress=false&scope=0&status=3&type=2,3,4,6,7&username="+URLName)
	NuSocket = SDLNet_TCP_Open( @NuIP )
	if( NuSocket = 0 ) then
		ErrorMsg = "Nu Replayer did not successfully open a socket to Planets Nu's servers."
	else
		if SDLNet_TCP_Send(NuSocket, strptr(SendBuffer), len(SendBuffer)) < len(SendBuffer) then
			ErrorMsg = "Nu Replayer did not successfully send its request to Planets Nu's servers."
		else
			mkdir "raw"
			open "raw/PersonalGames.txt" for output as #7

			do
				Bytes = SDLNet_TCP_Recv( NuSocket, strptr( RecvBuffer ), RECVBUFFLEN )
				if( Bytes <= 0 ) then
					exit do
				end if

				'' add the null-terminator
				RecvBuffer[Bytes] = 0

				'' print it as string
				print #7, RecvBuffer;
				LinesReceived += 1
			loop
			close #7
		end if
	end if
	SDLNet_TCP_Close( NuSocket )
	#ENDIF
	
	open "raw/PersonalGames.txt" for input as #8
	do
		if eof(8) then
			close #8
			exit sub
		end if
		line input #8, InStream
	loop until left(InStream,2) = "[{" OR left(InStream,2) = "{"
	close #8
	
	for DID as integer = 1 to len(InStream)
		if mid(InStream,DID,15) = quote("success")+":false" then
			exit sub
		end if
		if mid(InStream,DID,4) = quote("id") then
			GamesRegistered += 1
			if GamesRegistered <= 12 then
				PersonalIDs(GamesRegistered) = valint(mid(InStream,DID+5,7))
			else
				rotatePersonalGames(valint(mid(InStream,DID+5,7)))
			end if
		end if
	next DID
end sub
