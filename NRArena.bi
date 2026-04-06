function getArenaTurn as integer
	dim SendBuffer as string
	dim RecvBuffer as zstring * RECVBUFFLEN+1
	dim Bytes as integer
	
	dim as integer FetchNumeral = 0
	dim as string InStream, TargetFile
	SendBuffer = loadAddress("game/loadinfo?gameid="+str(FeaturedArena)+"&compress=false")
	TargetFile = "raw/"+str(FeaturedArena)+"/loadinfo.txt"
	
	createMeter(0, "Checking arena turn...")
	screencopy
	NuSocket = SDLNet_TCP_Open( @NuIP )
	if( NuSocket = 0 ) then
		ErrorMsg = "Nu Replayer did not successfully open a socket to Planets Nu's servers."
	else
		if SDLNet_TCP_Send(NuSocket, strptr(SendBuffer), len(SendBuffer)) < len(SendBuffer) then
			ErrorMsg = "Nu Replayer did not successfully send its request to Planets Nu's servers."
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
					ErrorMsg = "Nu Replayer could not successfully download the static data file due to lack of opening brace."
					exit do
				end if
				line input #5, InStream
			loop until left(InStream,1) = "{"
			close #5
		end if

		if instr(Instream,"{"+quote("success")+":false") then
			ErrorMsg = "Nu Replayer could not successfully download the static data file due to API error."
		elseif ErrorMsg = "" then
			FetchNumeral = getJsonVal(InStream,"turn")
		end if
	end if
	
	SDLNet_TCP_Close( NuSocket )
	if ErrorMsg <> "" then
		print " Failure! ";ErrorMsg
		screencopy
		sleep
	end if
	
	return FetchNumeral
end function