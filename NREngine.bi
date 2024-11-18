const BROWSER_LONG = "Nu Replayer 0.96 (Beta)"

#IFNDEF __FORCE_OFFLINE__
' Online support parameters
const RECVBUFFLEN = 8192
const NEWLINE = !"\r\n"
const DEFAULT_HOST = "api.planets.nu"
const BROWSER_SHORT = "NuReplayer Beta"
dim shared as IPAddress NuIP
dim shared as TCPSocket NuSocket
#ENDIF

dim shared as string SendBuffer
dim shared as double LastFill
dim shared as integer PersonalIDs(12), LoadTurnDetected

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
					
					if .Race = "Fascist" AND LegacyRaceNames = 0 then
						.Race = "Fury"
					elseif .Race = "Fury" AND LegacyRaceNames then
						.Race = "Fascist"
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
	dim as string SettingsFile, PlanetsFile, ShipsFile, MapFile, BasesFile, StorageFile, _
		IonFile, MineFile, StarFile, NebFile, WormFile, ArtiFile, CombatsFile
	dim as short LoadObjID
	'Loads various files and renders their contents onto the starmap
	
	PlanetsFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Planetary.csv"
	ShipsFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Starships.csv"
	MapFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Map.csv"
	BasesFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Starbases.csv"
	StorageFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Base Stock.csv"
	MineFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Minefields.csv"
	IonFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Ion Storms.csv"
	StarFile = "games/"+str(GameID)+"/StarClusters.csv"
	NebFile = "games/"+str(GameID)+"/Nebulae.csv"
	WormFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Wormholes.csv"
	ArtiFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/Artifacts.csv"
	CombatsFile = "games/"+str(GameID)+"/"+str(TurnNum)+"/VCRs.csv"
	
	for OID as integer = 0 to MetaLimit
		if OID <= LimitObjs then
			with Planets(OID)
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
			
			Starships(OID) = ResetShip
			IonStorms(OID) = ResetStorm
			Wormholes(OID) = ResetWorm
			Artifacts(OID) = ResetArti
			VCRbattles(OID) = ResetVCR
			if ReplayerMode <> MODE_CLIENT then
				StarClusters(OID) = ResetStar
				Nebulae(OID) = ResetNeb
			end if
		end if
			
		Minefields(OID) = ResetMinef
	next OID

	for BID as integer = 0 to MetaLimit
		with BaseStorage(BID)
			erase .HullCount, .HullReference, .EngineCount, .BeamCount, .TubeCount, .TorpCount
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
				input #4, .DefPosts
				
				input #4, .WorkMine
				input #4, .WorkHarvest
				input #4, .WorkBurrow
				input #4, .WorkTerraform
				input #4, .Larva
				input #4, .BurrowSize

				input #4, .PodHull
				input #4, .PodCargo
				input #4, .PodX
				input #4, .PodY
				input #4, .PodCargo
			end with
		end if
	next PID
	close #4
	
	if FileExists(ShipsFile) then
		debugout("Opened ships file")
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

					input #5, .Mission
					input #5, .MisnTarget(1)
					input #5, .MisnTarget(2)
					input #5, .PrimEnemy
					
					input #5, .XLoc
					input #5, .YLoc
					input #5, .TargetX
					input #5, .TargetY
					input #5, .ShipName
					.ShipName = findReplace(.ShipName,"&",",")
					
					input #5, .ShipType
					input #5, .EnginePos
					input #5, .BeamNum
					input #5, .BeamPos
					input #5, .BayNum
					input #5, .TubeNum
					input #5, .TubePos
					
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
					input #5, .Infection
					
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
		end if
	end with
	
	if FileExists(BasesFile) then
		debugout("Opened bases file")
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
					input #7, .OrbDefense, .Fighters, .Damage
					input #7, .BaseOrders(1), .BaseTarget(1)
					input #7, .BaseOrders(2), .BaseTarget(2)
					input #7, .TechH, .TechE, .TechB, .TechT
					input #7, .UseH, .UseE, .UseB, .UseT  
				end with
			end if
		next PID
		close #7
	end if
	
	if FileExists(StorageFile) then
		debugout("Opened base storage file")
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
							if PartRef <= 110 AND CountFound > 0 then .TubeCount(PartRef) = CountFound
						case 5 'Torp ammo
							if PartRef <= 110 AND CountFound > 0 then .TorpCount(PartRef) = CountFound
					end select
				end with
			end if
		next BID
		close #8
	end if
	
	if FileExists(MineFile) then
		debugout("Opened minefield file")
		open MineFile for input as #10
		line input #10, NullStr
		for MFID as integer = 0 to MetaLimit
			if eof(10) then
				exit for
			else
				input #10, LoadObjID
	
				with Minefields(LoadObjID)
					input #10, .Ownership
					input #10, .Webbed, .MineUnits
					input #10, .X, .Y
					input #10, .Radius
					input #10, .FCode
					.FCode = findReplace(.FCode,"&",",")
				end with
			end if
		next MFID
		close #10
	end if
	
	if FileExists(IonFile) then
		debugout("Opened ion storms file")
		open IonFile for input as #9
		line input #9, NullStr
		for IID as integer = 0 to LimitObjs
			if eof(9) then
				exit for
			else
				input #9, LoadObjID
	
				with IonStorms(LoadObjID)
					input #9, .ParentID
					input #9, .X, .Y
					input #9, .Radius, .Voltage
					input #9, .Warp, .Heading
					input #9, .Growing
				end with
			end if
		next IID
		close #9
	end if

	if ReplayerMode <> MODE_CLIENT then
		if FileExists(StarFile) then
			debugout("Opened star clusters file")
			open StarFile for input as #11
			line input #11, NullStr
			for SID as integer = 0 to LimitObjs
				if eof(11) then
					exit for
				else
					input #11, LoadObjID
		
					with StarClusters(LoadObjID)
						input #11, .Namee
						input #11, .X, .Y
						input #11, .Temperature
						input #11, .Radius, .Mass
						input #11, .Planets
					end with
				end if
			next SID
			close #11
		end if
		
		if FileExists(NebFile) then
			debugout("Opened star nebulae file")
			open NebFile for input as #12
			line input #12, NullStr
			for SID as integer = 0 to LimitObjs
				if eof(12) then
					exit for
				else
					input #12, LoadObjID
		
					with Nebulae(LoadObjID)
						input #12, .Namee
						input #12, .X, .Y
						input #12, .Radius, .Intensity
						input #12, .Gas
					end with
				end if
			next SID
			close #12
		end if
	end if
	
	if FileExists(WormFile) then
		debugout("Opened wormholes file")
		open WormFile for input as #13
		line input #13, NullStr
		for WID as integer = 0 to LimitObjs
			if eof(13) then
				exit for
			else
				input #13, LoadObjID
	
				with Wormholes(LoadObjID)
					input #13, .Namee
					input #13, .X, .Y
					input #13, .DestX, .DestY
					input #13, .Stability, .LastScan
				end with
			end if
		next WID
		close #13
	end if
	
	if FileExists(ArtiFile) then
		debugout("Opened artifacts file")
		open ArtiFile for input as #14
		line input #14, NullStr
		for AID as integer = 0 to LimitObjs
			if eof(14) then
				exit for
			else
				input #14, LoadObjID
	
				with Artifacts(LoadObjID)
					input #14, .Namee
					input #14, .X, .Y
					input #14, .LocationType, .LocationID
				end with
			end if
		next AID
		close #14
	end if
	
	if FileExists(CombatsFile) then
		debugout("Opened VCRs file")
		open CombatsFile for input as #15
		line input #15, NullStr
		for VID as integer = 0 to LimitObjs
			if eof(15) then
				exit for
			else
				input #15, LoadObjID
				
				with VCRbattles(LoadObjID)
					.InternalID = LoadObjID
					input #15, .Seed
					input #15, .XLoc, .YLoc
					input #15, .Battletype
					input #15, .LeftOwner, .RightOwner
					input #15, .Turn
					for PID as byte = 1 to 2
						with .Combatants(PID)
							input #15, .PieceID
							input #15, .Namee
							input #15, .BeamCt
							input #15, .TubeCt
							input #15, .BayCt
							input #15, .HullID
							input #15, .BeamID
							input #15, .TorpID
							input #15, .Shield
							input #15, .Damage
							input #15, .Crew
							input #15, .Mass
							input #15, .RaceID
							input #15, .BeamKillX
							input #15, .BeamChargeX
							input #15, .TorpChargeX
							input #15, .TorpMissChance
							input #15, .CrewDefense
							input #15, .TorpAmmo
							input #15, .Fighters
							input #15, .Temperature
							input #15, .Starbase
							
							.ShieldEnd = .Shield
							.DamageEnd = .Damage
							.CrewEnd = .Crew
							.TorpAmmoEnd = .TorpAmmo
							.FightersEnd = .Fighters
						end with
					next PID
					
					.QuickDone = 0
				end with
			end if
		next VID
		close #15
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

declare sub syncReport(AddCycle as byte = 0)

sub loadTurnExtras
	OldTurnFormat = 0
	debugout("Loading game #"+str(GameID)+" turn "+str(TurnNum))
	updateStarmap
	updateStatistics
	updateCommentary
	syncReport
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
			"Supplying NU REPLAYER your information will allow easier access to your most recent finished games.")
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
				ErrorMsg = "Nu Replayer did not successfully send its request to Planets Nu's servers."
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
	#ELSE
	sub selectAccount
		Username = ""
		
		do
			line(CanvasScreen.Wideth/2+10,100)-(CanvasScreen.Wideth-6,124),rgb(0,0,0),bf
			gfxstring("Enter username: "+str(Username),CanvasScreen.Wideth/2+10,100,5,4,2,rgb(255,255,0))
	
			if InType = EscKey then
				if Username <> "" then
					Username = ""
				else
					exit do
				end if
			elseif InType = chr(8) then
				Username = left(Username,len(Username)-1)
			elseif InType <> "" then
				Username += InType
			end if
	
			screencopy
			sleep 15
			InType = inkey
		loop until InType = EnterKey
		
		if Username = "" then
			Username = "guest"
		end if
	end sub
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
				ErrorMsg = "Nu Replayer did not successfully send its request to Planets Nu's servers."
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

sub createMeter(Filling as double = LastFill, ProgressStr as string = LastProgress)
	line(0,CanvasScreen.Height-20)-(CanvasScreen.Wideth-1,CanvasScreen.Height-1),rgb(0,0,0),bf
	if Filling > 0 then
		line(1,CanvasScreen.Height-19)-(1+Filling*(CanvasScreen.Wideth-3),CanvasScreen.Height-2),rgb(255-Filling*255,Filling*255,0),bf
	end if
	line(0,CanvasScreen.Height-20)-(CanvasScreen.Wideth-1,CanvasScreen.Height-1),rgb(255,255,255),b

	gfxstring(ProgressStr,CanvasScreen.Wideth/2+1-gfxlength(ProgressStr,3,2,2)/2,CanvasScreen.Height-18,3,2,2,rgb(255,255,255))
	
	LastFill = Filling
	LastProgress = ProgressStr
end sub

sub loadTurnUI(Players as ubyte)
	dim as string ProgressMeter
	
	if ViewGame.PlayerCount > 0 then
		LoadTurnDetected = ViewGame.PlayerCount
	else
		LoadTurnDetected = GameParser.PlayerCount
	end if
	
	ProgressMeter = str(Players)+" / "+str(LoadTurnDetected)+" players converted"
	createMeter(Players/LoadTurnDetected,ProgressMeter)
	screencopy
	sleep 15
end sub

sub loadTurnKB(KBCount as integer, PlayerID as ubyte)
	dim as integer FileSize, XPos
	dim as string FileProgress
	if timer > KBUpdate + 0.005 then
		KBUpdate = timer
		FileSize = int(FileLen("raw/"+str(GameID)+"/player"+str(PlayerID)+"-turn"+str(TurnNum)+".trn")/1e3)

		if FileSize > 0 then
			createMeter((PlayerID-1+KBCount/FileSize)/LoadTurnDetected)
			FileProgress = str(KBCount)+"/"+str(FileSize)+" KB done for player "+str(PlayerID)
		else
			for PlotIndeter as short = 0 to 22
				XPos = (PlotIndeter-1)*50 + remainder(int(KBCount/2),50)
				put(XPos,748),Indeterminate,pset
			next PlotIndeter
			createMeter

			FileProgress = str(KBCount)+"/??? KB done for player "+str(PlayerID)
		end if
		'gfxstring(FileProgress,1024-gfxlength(FileProgress,3,3,2),730,3,3,2,rgb(255,255,255))
		screencopy
	end if
end sub

sub rotatePersonalGames(NewID as integer)
	for PersonalSlot as byte = 1 to 11
		PersonalIDs(PersonalSlot) = PersonalIDs(PersonalSlot+1)
	next PersonalSlot
	
	PersonalIDs(12) = NewID
end sub

function isPersonalGame(SearchID as integer) as integer
	dim as integer GameFound = 0
	
	for PersonalSlot as byte = 1 to 12
		if PersonalIDs(PersonalSlot) = SearchID then
			GameFound = 1
		end if
	next PersonalSlot
	
	return GameFound
end function
