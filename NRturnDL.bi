declare function downloadLastTurns(GameID as integer) as integer
declare function downloadZipPackage(GameID as integer) as integer
#include "NRzip.bi"

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
		
		createMeter(1,"")
		print
		print word_wrap("Process successful. You can now use the Game Room for "+GameName+".")
		screencopy
		sleep
	else
		print
		print word_wrap(ErrorMsg)
		screencopy
		sleep
	end if
	
	ErrorMsg = ""
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
	GameParser.TorpSet = 0

	'Download a series of turns
	do
		Player += 1
		if Player > max(1,GameParser.PlayerCount) then
			exit do
		end if
		
		if Player = 1 then
			createMeter(0,"Downloading turns... (0 / ? players done)")
		else
			createMeter((Player-1)/GameParser.PlayerCount,"Downloading turns... ("+str(Player-1)+" / "+str(GameParser.PlayerCount)+" players done)")
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
			
			if instr(Instream,"{"+quote("success")+":false") then
				ErrorMsg = "Nu Replayer could not successfully download one of the turn files due to API error."
			elseif Player = 1 then
				with GameParser
					.DynamicMap = 0
					.PlayerCount = getJsonVal(InStream,"slots")
					FoundSettings = (.PlayerCount > 0)

					.LastTurn = getJsonVal(InStream,"turn")
					.MapWidth = getJsonVal(InStream,"mapwidth")
					.MapHeight = getJsonVal(InStream,"mapheight")

					.CloudyIonStorms = getJsonBool(InStream,"nuionstorms")
					.Sphere = getJsonBool(InStream,"sphere")
					.Academy = getJsonBool(InStream,"isacademy")
					.AccelStart = getJsonVal(InStream,"acceleratedturns")
					.TorpSet = getJsonVal(InStream,"torpedoset")

					mkdir("games/"+str(GameID))
					exportSettings(GameID,1)
					
					if FoundSettings then
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
						if .TorpSet > 0 then
							print "* Torpedo set "& .TorpSet;" active"
						end if
					end if
				end with
				
				TargetFile(1) = "raw/"+str(GameID)+"/player"+str(Player)+"-turn"+str(GameParser.LastTurn)+".trn"
				name(TargetFile(0),TargetFile(1))
			end if
		end if
		
		SDLNet_TCP_Close( NuSocket )
	loop

	createMeter(GameParser.PlayerCount/GameParser.PlayerCount,"")
	return ErrorMsg = ""
end function

function downloadZipPackage(GameID as integer) as integer
	dim SendBuffer as string
	dim RecvBufferTxt as zstring * RECVBUFFLEN+1
	dim Bytes as integer

	Static As UByte chunk(0 To (RECVBUFFLEN - 1))
	#define DL_BUFFER (@chunk(0))
	
	dim as string InStream, GoalStr, TargetFile
	dim as integer BlankLines = 0, ZipOutcome
	dim as longint BytesDownloaded = 0, TotalBytes = 0
	ErrorMsg = ""
	
	SendBuffer = loadAddress("game/loadall?gameid="+str(GameID))
	GoalStr = "Content-Length: "
	
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
			
			TargetFile = "raw/"+str(GameID)+"/gameZipPrep.txt"
			open TargetFile for output as #6

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
				
				createMeter(0,"Downloading ZIP package... (finalizing prep)")
				screencopy
			loop until BlankLines >= 4
			close #6

			open TargetFile for input as #7
			while eof(7) = 0
				input #7, InStream
				if left(InStream, len(GoalStr)) = GoalStr then
					TotalBytes = vallng(right(InStream, len(InStream) - len(GoalStr)))
					exit while
				end if
			wend
			close #7
			
			TargetFile = "raw/"+str(GameID)+"/game"+str(GameID)+".zip"
			BytesDownloaded = 0
			
			open TargetFile for binary as #8
			do
				Bytes = SDLNet_TCP_Recv( NuSocket, DL_BUFFER, RECVBUFFLEN )
				if ( Bytes <= 0 ) then
					exit do
				end if

				put #8, , *DL_BUFFER, Bytes
				
				BytesDownloaded += Bytes
				createMeter(BytesDownloaded/TotalBytes/2,"Downloading ZIP package... ("+commaSep(int(BytesDownloaded/1e3))+" / "+commaSep(int(TotalBytes/1e3))+" KB downloaded)")
				screencopy
			loop
			close #8
		end if
		
		ZipOutcome = unpackZipPackage(TargetFile, (GameParser.PlayerCount+1)/(GameParser.PlayerCount+2))
	end if
	
	if ZipOutcome = 2 then
		ErrorMsg = "Could not open the ZIP package for extraction."
	elseif ZipOutcome = 1 then
		ErrorMsg = "Some files could not be extracted from the ZIP package."
	end if

	while inkey <> "":wend	
	SDLNet_TCP_Close( NuSocket )
	return ErrorMsg = ""
end function
