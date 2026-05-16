function getArenaTurn as integer
	dim SendBuffer as string
	dim RecvBuffer as zstring * RECVBUFFLEN+1
	dim Bytes as integer
	
	dim as byte GameStatus = 0, ConnError
	dim as string InStream, TargetFile, GameType
	SendBuffer = loadAddress("game/loadinfo?gameid="+str(FeaturedArena)+"&compress=false")
	TargetFile = "raw/"+str(FeaturedArena)+"/loadinfo.txt"
	
	GameName = "" 
	
	createMeter(0, "Checking arena turn...")
	screencopy
	NuSocket = SDLNet_TCP_Open( @NuIP )
	ErrorMsg = ""
	if( NuSocket = 0 ) then
		ErrorMsg = "Nu Replayer did not successfully open a socket to Planets Nu's servers."
		ConnError = 1
	else
		if SDLNet_TCP_Send(NuSocket, strptr(SendBuffer), len(SendBuffer)) < len(SendBuffer) then
			ErrorMsg = "Nu Replayer did not successfully send its request to Planets Nu's servers."
			ConnError = 1
		else
			mkdir "raw"
			mkdir "raw/"+str(FeaturedArena)
			open TargetFile for output as #4

			do
				Bytes = SDLNet_TCP_Recv( NuSocket, strptr( RecvBuffer ), RECVBUFFLEN )
				if( Bytes <= 0 ) then
					exit do
				end if

				'' add the null-terminator
				RecvBuffer[Bytes] = 0

				'' print it as string
				print #4, RecvBuffer;
			loop
			close #4
		end if
			
		if ErrorMsg = "" then
			open TargetFile for input as #5
			do
				if eof(5) then
					ErrorMsg = "Nu Replayer could not download the game info: No opening brace found"
					exit do
				end if
				line input #5, InStream
			loop until left(InStream,1) = "{"
			close #5
		end if

		if ErrorMsg = "" then
			ErrorMsg = findAPIerror(InStream)
		end if
		
		if ErrorMsg = "" then
			TurnNum = getJsonVal(InStream,"turn")
			GameStatus = getJsonVal(InStream,"status")
			GameType = getJsonStr(InStream,"shortdescription")
			
			if GameType <> "Campaign Arena" then
				ErrorMsg = "Not a valid arena game"
				FeaturedArena = 0
			end if
		else
			ErrorMsg = "Nu Replayer could not download the game info: " + ErrorMsg
		end if
	end if
	
	SDLNet_TCP_Close( NuSocket )
	if GameStatus = 3 then
		ErrorMsg = "Game Over"
		createMeter(1, "GAME OVER! Use Nu Replayer's core functionality to acquire/update data.")
		FeaturedArena = 0
		screencopy
		sleep
	elseif ErrorMsg <> "" then
		createMeter(0, "FAILURE! "+ErrorMsg)
		if ConnError = 0 then
			FeaturedArena = 0
		end if
		screencopy
		sleep
	end if
	
	return ErrorMsg = ""
end function