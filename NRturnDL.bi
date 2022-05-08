declare function downloadLastTurns(GameID as integer) as integer
declare function downloadZipPackage(GameID as integer) as integer

sub downloadGame(GameName as string, GameID as integer)
	'Downloads game summary and data
	cls
	print word_wrap("Creating preparation data and downloading turns for "+GameName+". This may take several minutes depending on the number of players and ZIP package size...")
	screencopy
	
	if downloadLastTurns(GameID) AND downloadZipPackage(GameID) then
		'Indicate successful operation
		open "raw/DLturn.txt" for output as #9
		print #9, "Last downloaded game #"& GameID
		close #9

		print
		print word_wrap("Process successful. To retrieve earlier turns, just extract the included ZIP package.")
		screencopy
		sleep
	else
		print
		print word_wrap(ErrorMsg)
		screencopy
		sleep
	end if
end sub

function downloadLastTurns(GameID as integer) as integer
	dim SendBuffer as string
	dim RecvBuffer as zstring * RECVBUFFLEN+1
	dim Bytes as integer
	
	dim as string InStream, TargetFile(1)
	dim as byte Player = 0, FoundSettings = 0
	ErrorMsg = ""
	
	GameParser.LastTurn = 0
	GameParser.DynamicMap = 0

	'Download a series of turns
	do
		Player += 1
		if Player > max(1,GameParser.PlayerCount) then
			exit do
		end if
		
		if Player = 1 then
			createMeter(0,"Acquiring settings...",0,abs(CanvasScreen.Height < 768))
		else
			createMeter((Player-1)/(GameParser.PlayerCount+2),str(Player-1)+" / "+str(GameParser.PlayerCount)+" players downloaded",0,abs(CanvasScreen.Height < 768))
		end if
		screencopy
		
		if APIKey = "" then
			SendBuffer = loadAddress("game/loadturn?gameid="+str(GameID)+"&playerid="+str(Player)+"&compress=false")
		else
			SendBuffer = loadAddress("game/loadturn?gameid="+str(GameID)+"&playerid="+str(Player)+"&apikey="+APIKey+"&compress=false")
		end if
		
		TargetFile(0) = "raw/"+str(GameID)+"/player"+str(Player)+"-turn"+str(GameParser.LastTurn)+".trn"
		
		NuSocket = SDLNet_TCP_Open( @NuIP )
		if( NuSocket = 0 ) then
			ErrorMsg = "Nu Replayer did not successfully open a socket to Planets Nu's servers."
			return 0
		else
			if SDLNet_TCP_Send(NuSocket, strptr(SendBuffer), len(SendBuffer)) < len(SendBuffer) then
				ErrorMsg = "Nu Replayer did not successfully send its request to Planets Nu's servers."
				return 0
			else
				mkdir "raw"
				mkdir "raw/"+str(GameID)+""
				open TargetFile(0) for output as #4
	
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
			
			open TargetFile(0) for input as #5
			do
				if eof(5) then
					ErrorMsg = "Nu Replayer could not successfully download one of the turn files due to lack of opening brace."
				end if
				line input #5, InStream
			loop until left(InStream,1) = "{"
			close #5
			
			if strMatch(Instream,1,"{"+quote("success")+":false") then
				ErrorMsg = "Nu Replayer could not successfully download one of the turn files due to API error."
			elseif Player = 1 then
				with GameParser
					.PlayerCount = 0
					.MapWidth = 2000
					.MapHeight = 2000
					.CloudyIonStorms = 0
					.Sphere = 0
					.Academy = 0
					.DynamicMap = 0
					.AccelStart = 0
					.LastTurn = 0
				
					for DID as integer = 1 to len(InStream)
						if strMatch(InStream,DID,quote("slots")+":") then
							FoundSettings = 1
							.PlayerCount = valint(mid(InStream,DID+8,2))
						end if
				
						if .LastTurn = 0 AND strMatch(InStream,DID,quote("turn")+":") then
							.LastTurn = valint(mid(InStream,DID+7,4))
						end if
				
						if strMatch(InStream,DID,quote("mapwidth")+":") then
							.MapWidth = valint(mid(InStream,DID+11,4))
						end if
				
						if strMatch(InStream,DID,quote("mapheight")+":") then
							.MapHeight = valint(mid(InStream,DID+12,4))
						end if
				
						if strMatch(InStream,DID,quote("nuionstorms")+":true") then
							.CloudyIonStorms = 1
						end if
				
						if strMatch(InStream,DID,quote("sphere")+":true") then
							.Sphere = 1
						end if
				
						if strMatch(InStream,DID,quote("isacademy")+":true") then
							.Academy = 1
						end if
						
						if strMatch(InStream,DID,quote("acceleratedturns")) then
							.AccelStart = valint(mid(InStream,DID+19,3))
						end if
						
						if strMatch(InStream,DID,quote("id")) AND FoundSettings then
							exit for
						end if
					next DID

					mkdir("games/"+str(GameID))
					exportSettings(GameID,1)
					
					print
					print "Found the following settings..."
					print "* Players: "& .PlayerCount
					print "* Map Size: "& .MapWidth;" X "& .MapHeight
					if .CloudyIonStorms > 0 then
						print "* Cloudy ion storms active"
					end if
					if .Sphere > 0 then
						print "* Sphere active"
					end if
					if .Academy > 0 then
						print "* Academy active"
					end if
					if .AccelStart > 0 then
						print "* Accelerated Start: "& .AccelStart;" turns"
					end if
				end with
				
				TargetFile(1) = "raw/"+str(GameID)+"/player"+str(Player)+"-turn"+str(GameParser.LastTurn)+".trn"
				name(TargetFile(0),TargetFile(1))
			end if
		end if
		
		SDLNet_TCP_Close( NuSocket )
	loop

	createMeter(GameParser.PlayerCount/(GameParser.PlayerCount+2),"",0,abs(CanvasScreen.Height < 768))
	return ErrorMsg = ""
end function

function downloadZipPackage(GameID as integer) as integer
	dim SendBuffer as string
	dim RecvBufferTxt as zstring * RECVBUFFLEN+1
	dim Bytes as integer

	Static As UByte chunk(0 To (RECVBUFFLEN - 1))
	#define DL_BUFFER (@chunk(0))
	
	dim as string InStream, TargetFile
	dim as integer BlankLines = 0, ZipOutcome
	dim as longint TotalBytes = 0
	ErrorMsg = ""
	
	SendBuffer = loadAddress("game/loadall?gameid="+str(GameID))
	
	NuSocket = SDLNet_TCP_Open( @NuIP )
	if FileExists("raw/"+str(GameID)+"/game"+str(GameID)+".zip") then
		ErrorMsg = "Nu Replayer skipped downloading the ZIP archive: It already exists"
		return 0
	elseif( NuSocket = 0 ) then
		ErrorMsg = "Nu Replayer did not successfully open a socket to Planets Nu's servers."
		return 0
	else
		if SDLNet_TCP_Send(NuSocket, strptr(SendBuffer), len(SendBuffer)) < len(SendBuffer) then
			ErrorMsg = "Nu Replayer did not successfully send its request to Planets Nu's servers."
			return 0
		else
			mkdir "raw"
			mkdir "raw/"+str(GameID)+""
			open "raw/"+str(GameID)+"/gameZipPrep.txt" for output as #6

			do
				Bytes = SDLNet_TCP_Recv( NuSocket, strptr( RecvBufferTxt ), 1 )
				if ( Bytes <= 0 ) then
					ErrorMsg = "Nu Replayer did not successfully acquire the file."
					return 0
				end if

				'' add the null-terminator
				RecvBufferTxt[Bytes] = 0

				'' print it as string
				print #6, RecvBufferTxt;
				
				if left(RecvBufferTxt,1) < chr(32) then
					BlankLines += 1
				else
					BlankLines = 0
				end if 
				
				TotalBytes += Bytes
				createMeter(GameParser.PlayerCount/(GameParser.PlayerCount+2),commaSep(TotalBytes)+" bytes downloaded so far",0,abs(CanvasScreen.Height < 768))
				screencopy
			loop until BlankLines >= 4
			close #6
			
			TargetFile = "raw/"+str(GameID)+"/game"+str(GameID)+".zip"
			
			open TargetFile for binary as #7

			do
				Bytes = SDLNet_TCP_Recv( NuSocket, DL_BUFFER, RECVBUFFLEN )
				if ( Bytes <= 0 ) then
					exit do
				end if

				put #7, , *DL_BUFFER, Bytes
				
				TotalBytes += Bytes
				createMeter(GameParser.PlayerCount/(GameParser.PlayerCount+2),commaSep(TotalBytes)+" bytes downloaded so far",0,abs(CanvasScreen.Height < 768))
				screencopy
			loop
			close #7
		end if
	end if
	
	createMeter(1,commaSep(TotalBytes)+" bytes downloaded",0,abs(CanvasScreen.Height < 768))
	SDLNet_TCP_Close( NuSocket )
	return ErrorMsg = ""
end function
