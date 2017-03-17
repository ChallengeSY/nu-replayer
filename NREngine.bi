const BROWSER_LONG = "Nu Replayer 0.28 (Alpha 19)"

#IFNDEF __FORCE_OFFLINE__
/'
 ' When Nu Replayer has online support, then it utilizes parameters 
 ' similar to web browsing
 '/

const RECVBUFFLEN = 8192
const NEWLINE = !"\r\n"
const DEFAULT_HOST = "api.planets.nu"
const BROWSER_SHORT = "NuReplayer Alpha"
dim shared as IPAddress NuIP
dim shared as TCPSocket NuSocket
#ENDIF

dim shared as string SendBuffer
dim shared as double LastFill
dim shared as integer PersonalIDs(8)

sub updateStatistics
	dim as string ScoreFile, ResourceFile, RelationsFile
	dim as byte PlrA, PlrB
	' Loads game statistics
	ParticipatingPlayers = 35
	
	ScoreFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Score.csv"
	ResourceFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Resources.csv"
	RelationsFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Relations.csv"
	
	debugout("Loaded score file")
	if FileExists(ScoreFile) then
		open ScoreFile for input as #2
		for RID as short = 0 to MaxPlayers
			if eof(2) then
				ParticipatingPlayers = RID - 1
				exit for
			else
				with PlayerSlot(RID)
					input #2, .Race
					input #2, .PlayerName
					input #2, .PlanetCount
					input #2, .Starbases
					input #2, .Ships
					input #2, .Freighters
					input #2, .MilitaryScore
	
					if .PlayerName = "dead" OR .PlayerName = "open" then
						.PlayerName = ucase(left(.PlayerName,1)) + right(.PlayerName,len(.PlayerName) - 1) + str(RID)
					elseif .PlayerName = "Grand Total" OR (.PlayerName = "" AND .Race = "" AND .PlanetCount < 0) then
						ParticipatingPlayers = RID - 1
						.PlayerName = ""
						exit for
					else
						.PlayerName = ucase(left(.PlayerName,1)) + right(.PlayerName,len(.PlayerName) - 1)
					end if
				end with
			end if
		next RID
		close #2
	end if
	
	debugout("Loaded resource file")
	if FileExists(ResourceFile) then
		open ResourceFile for input as #3
		for RID as short = 0 to ParticipatingPlayers
			if eof(3) then
				exit for
			else
				with PlayerSlot(RID)
					input #3, NullStr
					input #3, .TotalDur
					input #3, .TotalTrit
					input #3, .TotalMoly
					input #3, .TotalMoney
				end with
			end if
		next RID
		close #3
	end if
	
	debugout("Loaded relationship file")
	if FileExists(RelationsFile) then
		open RelationsFile for input as #6
		do
			input #6, PlrA, PlrB
			input #6, PlayerSlot(PlrA).Relationship(PlrB)
			input #6, NullStr
			input #6, NullStr
		loop while eof(6) = 0
		close #6
	end if
end sub

sub updateStarmap
	dim as string SettingsFile, PlanetsFile, ShipsFile, MapFile, TerritoryFile, BasesFile, StorageFile
	dim as short LoadObjID
	' Loads the starmap, starships, and territory
	
	PlanetsFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Planetary.csv"
	ShipsFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Starships.csv"
	MapFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Map.csv"
	TerritoryFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Territory.csv"
	BasesFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Starbases.csv"
	StorageFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Base Stock.csv"
	
	for PID as short = 0 to LimitObjs
		with Planets(PID)
			if ViewGame.DynamicMap then
				.X = 0
				.Y = 0
				.ObjName = ""
			end if
			.Ownership = 0
			.BasePresent = 0
			.LastScan = 0
			.Neu = -1
			.Dur = -1
			.Trit = -1
			.Moly = -1
			.GNeu = -1
			.GDur = -1
			.GTrit = -1
			.GMoly = -1
			.DNeu = -1
			.DDur = -1
			.DTrit = -1
			.DMoly = -1
			.Megacredits = -1
			.Supplies = -1
			.MineralMines = -1
			.Factories = -1
		end with
		
		with Starships(PID)
			.Ownership = 0
			.ShipType = 0
			.ShipName = ""
			.ShipType = 0
			.FCode = ""
			.ClassName = ""
		end with
	next PID

	for BID as integer = 0 to MetaLimit
		with BaseStorage(BID)
			erase .HullCount, .HullReference, .EngineCount, .BeamCount, .TubeCount, .TorpCount
			/'
			for ShipSlot as byte = 0 to 100
				.HullCount(ShipSlot) = 0
				.HullReference(ShipSlot) = 0
			next ShipSlot

			for PartSlot as byte = 1 to 10
				if PartSlot < 10 then
					.EngineCount(PartSlot) = 0
				end if
				.BeamCount(PartSlot) = 0
				.TubeCount(PartSlot) = 0
				.TorpCount(PartSlot) = 0
			next PartSlot
			'/
		end with
	next
	
	if FileExists(SettingsFile) then
		open SettingsFile for input as #2
		close #2
	end if

	debugout("Opened planets file")
	open PlanetsFile for input as #4
	for PID as short = 0 to LimitObjs
		if eof(4) then
			exit for
		else
			input #4, LoadObjID
			if LoadObjID < 0 OR LoadObjID > LimitObjs then
				LoadObjID = 999
			end if

			with Planets(LoadObjID)
				input #4, .Ownership
				input #4, .BasePresent
				if FileExists(ShipsFile) then
					input #4, .FCode
					.FCode = findReplace(.FCode,"&",",")
				else
					.FCode = "---"
				end if
				input #4, .LastScan
				
				input #4, .Colonists
				input #4, .ColTaxRate
				input #4, .ColHappy
				input #4, .Temp
				input #4, .Natives
				input #4, .NatTaxRate
				input #4, .NatHappy
				input #4, .NativeType
				input #4, .NativeGov
				
				input #4, .Neu
				input #4, .Dur
				input #4, .Trit
				input #4, .Moly
				
				input #4, .GNeu
				input #4, .GDur
				input #4, .GTrit
				input #4, .GMoly
				
				input #4, .DNeu
				input #4, .DDur
				input #4, .DTrit
				input #4, .DMoly
				
				input #4, .Megacredits
				input #4, .Supplies
				input #4, .MineralMines
				input #4, .Factories
				
				.TerritoryValue = 0
			end with
		end if
	next PID
	close #4
	
	debugout("Opened ships file")
	if FileExists(ShipsFile) then
		dim as short ReadID
		
		open ShipsFile for input as #5
		for PID as short = 0 to LimitObjs
			if eof(5) then
				exit for
			else
				input #5, ReadID
				
				with Starships(ReadID)
					input #5, .Ownership
					input #5, .FCode
					.FCode = findReplace(.FCode,"&",",")

					input #5, .XLoc
					input #5, .YLoc
					input #5, .TargetX
					input #5, .TargetY
					input #5, .ShipName
					.ShipName = findReplace(.ShipName,"&",",")
					
					input #5, .ShipType
					input #5, .EnginePos
					input #5, .BeamPos
					input #5, .BeamNum
					input #5, .BayNum
					input #5, .TubePos
					input #5, .TubeNum
					
					input #5, .TotalMass
					input #5, .Ammo
					input #5, .WarpSpeed
					input #5, .Colonists
					input #5, .Neu
					input #5, .Dur
					input #5, .Trit
					input #5, .Moly
					
					input #5, .Megacredits
					input #5, .Supplies
					input #5, .Crew
					input #5, .HullDmg
					input #5, .Experience
					input #5, .Cloaked
					
					for STID as short = 1 to 5000
						if .ShipType = STID then
							.ClassName = ShiplistObj(STID).HullName
							.MaxCargo = ShiplistObj(STID).Cargo
							.BayNum = ShiplistObj(STID).FtrBays 'Safety feature
							.HullMass = ShiplistObj(STID).Mass
							.MaxFuel = ShiplistObj(STID).Neu
						end if
					next STID
					.OrbitingPlan = 0
					for PID as short = 1 to LimitObjs
						if .XLoc = Planets(PID).X AND .YLoc = Planets(PID).Y AND Planets(PID).ObjName <> "" then
							.OrbitingPlan = PID
							exit for
						end if
					next PID
				end with
			end if
		next PID
		close #5
	end if
	
	with ViewGame
		if .DynamicMap AND FileExists(MapFile) then
			if .MapWidth = 0 OR .MapHeight = 0 then
				MinXPos = 1950
				MaxXPos = 2050
			end if
	
			debugout("Opened map file")
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
						
						if LoadObjID > 0 AND .ObjName <> "" AND (ViewGame.MapWidth = 0 OR ViewGame.MapHeight = 0) then
							while .X < MinXPos OR .Y < MinXPos OR .X >= MaxXPos OR .Y >= MaxXPos
								MinXPos -= 50
								MaxXPos += 50
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
	
			if .Academy = 0 then
				open TerritoryFile for input as #3
				for TerrY as short = 0 to 767		
					for TerrX as short = 0 to 767
						input #3, Territory(TerrX,TerrY)
					next TerrX
				next TerrY
				close #3
			end if
		end if
	end with
	
	debugout("Opened bases file")
	if FileExists(BasesFile) then
		open BasesFile for input as #7
		for PID as short = 0 to LimitObjs
			if eof(7) then
				exit for
			else
				input #7, LoadObjID
				if LoadObjID < 0 OR LoadObjID > LimitObjs then
					LoadObjID = 999
				end if
	
				with Planets(LoadObjID)
					input #7, .OrbDefense
					input #7, .Fighters
					input #7, .Damage
					input #7, .TechH, .TechE, .TechB, .TechT
					input #7, .UseH, .UseE, .UseB, .UseT  
				end with
			end if
		next PID
		close #7
	end if
	
	debugout("Opened base storage file")
	if FileExists(StorageFile) then
		dim as byte PartType, PartRef
		dim as short CountFound
		
		open StorageFile for input as #8
		line input #8, NullStr
		for BID as integer = 0 to MetaLimit
			if eof(8) then
				exit for
			else
				input #8, LoadObjID
				input #8, PartType
				input #8, PartRef
				input #8, CountFound
				
				with BaseStorage(LoadObjID)
					select case PartType
						case 1 'Hulls
							for HullID as byte = 1 to 100
								if .HullReference(HullID) = 0 OR _
									.HullReference(HullID) = PartRef then
									.HullReference(HullID) = PartRef
									
									if CountFound > 0 then
										.HullCount(HullID) = CountFound
									end if
									exit for
								end if
							next HullID
						case 2 'Engines
							if PartRef < 10 AND CountFound > 0 then .EngineCount(PartRef) = CountFound
						case 3 'Beams
							if PartRef <= 10 AND CountFound > 0 then .BeamCount(PartRef) = CountFound
						case 4 'Tubes
							if PartRef <= 10 AND CountFound > 0 then .TubeCount(PartRef) = CountFound
						case 5 'Torp ammo
							if PartRef <= 10 AND CountFound > 0 then .TorpCount(PartRef) = CountFound
					end select
				end with
			end if
		next BID
		close #8
	end if
	
	if ViewGame.Academy = 0 then
		debugout("Applied territory")
		line TerritoryMap,(0,0)-(767,767),rgb(0,0,0),bf
		for TerrY as short = 0 to 767
			for TerrX as short = 0 to 767
				if Territory(TerrX,TerrY) > 0 then
					with Coloring(Planets(Territory(TerrX,TerrY)).Ownership)
						pset TerritoryMap,(TerrX,TerrY),rgba(.Red,.Green,.Blue,32)
					end with
	
					Planets(Territory(TerrX,TerrY)).TerritoryValue += 1
				end if
			next TerrX
		next TerrY
	end if
end sub

sub updateCommentary
	'Clears all old commentary first
	for PID as integer = 0 to LimitObjs
		if Commentary(PID) <> "" then
			Commentary(PID) = ""
		else
			exit for
		end if
	next PID
	
	'Loads new commentary files for the turn
	dim as string LoadCmFile, GamePath, Commentator
	GamePath = "games/"+str(GameID)+"/"+str(TurnNum)+"/"
	LoadCmFile = dir(GamePath+"*.txt",fbNormal)
	dim as integer han, Comments = 0
	while len(LoadCmFile) > 0
		Commentator = left(LoadCmFile,len(LoadCmFile)-4)
		
		han = FreeFile
		open LoadCmFile for input as #han
		while eof(han) = 0
			input #han, Commentary(Comments)
			Commentary(Comments) = "[" + Commentator + "] " + Commentary(Comments)
			Comments += 1
		wend
		close #han 
		
		LoadCmFile = dir()
	wend
end sub

sub loadTurnExtras
	OldTurnFormat = 0
	debugout("Loading game #"+str(GameID)+" turn "+str(TurnNum))
	updateStarmap
	updateStatistics
	updateCommentary
end sub

#IFNDEF __FORCE_OFFLINE__
' Converts an address to HTTP request 
function loadAddress(SubAddress as string, HostServer as string = DEFAULT_HOST) as string
	return "GET /" + SubAddress + " HTTP/1.0" + NEWLINE + _
		"Host: " + HostServer + NEWLINE + _
		"Connection: close" + NEWLINE + _
		"User-Agent: " + BROWSER_SHORT + NEWLINE + NEWLINE
end function

	#IFDEF __API_LOGIN__
	function apiLogin as byte
		dim as string Password
		screenset 1,1
		cls
		ErrorMsg = ""
		print word_wrap("Privacy: Your credidentials are used to allow NU REPLAYER to interact with the PLANETS NU server, and they will also be saved to the disk. "+_
			"Supplying NU REPLAYER your information will allow it to download turns bound to open slots in completed games, and allow easier access to your most recent finihsed games.",100)
		print
		line input "Enter your Planets Nu username: ",Username
		print "Enter your password: ";
		color rgb(0,0,0)
		line input "",Password
		color rgb(255,255,255)
		
		dim as string SendBuffer, MemoryBuffer
		dim RecvBuffer as zstring * RECVBUFFLEN+1
		dim Bytes as integer
		dim as byte LoginSuccess = 0
	
		SendBuffer = loadAddress("login?username="+str(Username)+"&password="+str(Password))
		NuSocket = SDLNet_TCP_Open( @NuIP )
		if( NuSocket = 0 ) then
			ErrorMsg = "Nu Replayer did not successfully open a socket to Planets Nu's servers."
			return 0
		else
			if SDLNet_TCP_Send(NuSocket, strptr(SendBuffer), len(SendBuffer)) < len(SendBuffer) then
				ErrorMsg = "Nu Replayer did not successfully sent its request to Planets Nu's servers."
				return 0
			else
				MemoryBuffer = ""

				open "login.tmp" for output as #9
				do
					Bytes = SDLNet_TCP_Recv( NuSocket, strptr( RecvBuffer ), RECVBUFFLEN )
					if( Bytes <= 0 ) then
						exit do
					end if
	
					'' add the null-terminator
					RecvBuffer[Bytes] = 0
	
					'' add to memory
					print #9, RecvBuffer
				loop
				close #9
			end if
		end if
		
		SDLNet_TCP_Close( NuSocket )
		
		open "login.tmp" for input as #9
		do
			line input #9, MemoryBuffer
		loop until left(MemoryBuffer,1) = "{"
		close #9
		
		if left(MemoryBuffer,15) = "{"+quote("success")+":true" then
			APIKey = mid(MemoryBuffer,27,36)
			LoginSuccess = 1
		else
			ErrorMsg = "Log in attempt did not succeed"
		end if
		
		kill("login.tmp")
		
		if ErrorMsg <> "" then
			print ErrorMsg
			sleep
		end if
		screenset 0,1
		return LoginSuccess
	end function
	#ENDIF

	#IFDEF __DOWNLOAD_TURNS__
	function retrieveData as byte
		'Retrives turn data from Nu's servers
		
		dim SendBuffer as string
		dim RecvBuffer as zstring * RECVBUFFLEN+1
		dim Bytes as integer
		dim LinesReceived as ushort
	
		SendBuffer = loadAddress("game/loadinfo?gameid="+str(GameID))
		NuSocket = SDLNet_TCP_Open( @NuIP )
		if( NuSocket = 0 ) then
			ErrorMsg = "Nu Replayer did not successfully open a socket to Planets Nu's servers."
			return 1
		else
			if SDLNet_TCP_Send(NuSocket, strptr(SendBuffer), len(SendBuffer)) < len(SendBuffer) then
				ErrorMsg = "Nu Replayer did not successfully sent its request to Planets Nu's servers."
				return 1
			else
				mkdir "games/"+str(GameID)
				mkdir "games/"+str(GameID)+"/raw"
				open "games/"+str(GameID)+"/raw/response" for output as #8
				open "games/"+str(GameID)+"/raw/loadinfo" for output as #7
	
				do
					Bytes = SDLNet_TCP_Recv( NuSocket, strptr( RecvBuffer ), RECVBUFFLEN )
					if( Bytes <= 0 ) then
						exit do
					end if
	
					'' add the null-terminator
					RecvBuffer[Bytes] = 0
	
					'' print it as string
					if LinesReceived = 0 then
						print #8, RecvBuffer;
						close #8
					else
						print #7, RecvBuffer;
					end if
					LinesReceived += 1
				loop
				close #7
				close #8
				return 1
			end if
		end if
		SDLNet_TCP_Close( NuSocket )
	end function
	#ENDIF
#ENDIF

sub loadTurnTerritory(AmtDone as short)
	dim as string ProgressMeter
	line(1,749)-(1022,766),rgb(0,0,0),bf
	line(1,749)-(1+AmtDone/767*1021,766),rgb(255-AmtDone/767*255,AmtDone/767*255,0),bf

	ProgressMeter = str(int(AmtDone/767*100))+"% territory done"
	gfxstring(ProgressMeter,513-gfxlength(ProgressMeter,3,3,2)/2,750,3,3,2,rgb(255,255,255))
	screencopy
	sleep 15
end sub

sub createMeter(Filling as double = LastFill, ProgressStr as string = LastProgress, PreserveEmpty as byte = 1, Condensed as byte = 0)
	if Condensed then
		if PreserveEmpty then
			line(800,580)-(1174,599),rgb(0,0,0),bf
		else
			line(0,580)-(1174,599),rgb(0,0,0),bf
		end if
		line(0,580)-(799,599),rgb(255,255,255),b
		if Filling > 0 then
			line(1,581)-(1+Filling*797,598),rgb(255-Filling*255,Filling*255,0),bf
		end if

		gfxstring(ProgressStr,401-gfxlength(ProgressStr,3,2,2)/2,582,3,2,2,rgb(255,255,255))
	else
		line(0,730)-(1024,747),rgb(0,0,0),bf
		if PreserveEmpty then
			line(1024,748)-(1174,767),rgb(0,0,0),bf
		else
			line(0,748)-(1174,767),rgb(0,0,0),bf
		end if
		line(0,748)-(1023,767),rgb(255,255,255),b
		if Filling > 0 then
			line(1,749)-(1+Filling*1021,766),rgb(255-Filling*255,Filling*255,0),bf
		end if

		gfxstring(ProgressStr,513-gfxlength(ProgressStr,3,2,2)/2,750,3,2,2,rgb(255,255,255))
	end if
	
	LastFill = Filling
	LastProgress = ProgressStr
end sub

sub loadTurnUI(Players as ubyte)
	dim as byte Detected
	dim as string ProgressMeter
	
	if ViewGame.PlayerCount > 0 then
		Detected = ViewGame.PlayerCount
	else
		Detected = GameParser.PlayerCount
	end if
	
	ProgressMeter = str(Players)+" / "+str(Detected)+" players done"
	createMeter(Players/Detected,ProgressMeter,0)
	screencopy
	sleep 15
end sub

sub loadTurnKB(KBCount as integer, Players as ubyte)
	dim as integer FileSize, XPos
	dim as string FileProgress
	if timer > KBUpdate + 0.125 then
		for PlotIndeter as short = 0 to 22
			XPos = (PlotIndeter-1)*50 + remainder(int(KBCount/2),50)
			put(XPos,748),Indeterminate,pset
		next PlotIndeter
		createMeter

		KBUpdate = timer
		FileSize = int(FileLen("raw/"+str(GameID)+"/player"+str(Players)+"-turn"+str(TurnNum)+".trn")/1e3)
		if FileSize > 0 then
			FileProgress = str(KBCount)+"/"+str(FileSize)+" KB done for player "+str(Players)
		else
			FileProgress = str(KBCount)+"/??? KB done for player "+str(Players)
		end if
		gfxstring(FileProgress,1024-gfxlength(FileProgress,3,3,2),730,3,3,2,rgb(255,255,255))
		screencopy
	end if
end sub

sub rotatePersonalGames(NewID as integer)
	for PersonalSlot as byte = 1 to 7
		PersonalIDs(PersonalSlot) = PersonalIDs(PersonalSlot+1)
	next PersonalSlot
	
	PersonalIDs(8) = NewID
end sub

function isPersonalGame(SearchID as integer) as integer
	dim as integer GameFound = 0
	
	for PersonalSlot as byte = 1 to 8
		if PersonalIDs(PersonalSlot) = SearchID then
			GameFound = 1
		end if
	next PersonalSlot
	
	return GameFound
end function
