sub importPrivateGame
	dim as string InStream, GameName, ShortDesc
	dim as integer GameNum, GameStatus, FinalTurn, SeekChar(1)
	
	dim SendBuffer as string
	dim RecvBuffer as zstring * RECVBUFFLEN+1
	dim Bytes as integer
	dim LinesReceived as ushort
	
	do
		line(CanvasScreen.Wideth/2+10,250)-(CanvasScreen.Wideth-6,274),rgb(0,0,0),bf
		gfxstring("Enter Game ID: "+str(GameNum),CanvasScreen.Wideth/2+10,250,5,4,2,rgb(255,255,0))

		if InType = EscKey then
			if GameNum > 0 then
				GameNum = 0
			else
				exit do
			end if
		elseif InType >= "0" AND InType <= "9" then
			GameNum = GameNum * 10 + valint(InType)
		elseif InType = chr(8) then
			GameNum = int(GameNum / 10)
		end if

		screencopy
		sleep 15
		InType = inkey
	loop until InType = EnterKey
	ErrorMsg = ""

	if GameNum > 0 then
		#IFDEF __USE_ZLIB__
		#ELSE
		SendBuffer = loadAddress("game/loadinfo?compress=false&gameid="+str(GameNum))
		NuSocket = SDLNet_TCP_Open( @NuIP )
		if( NuSocket = 0 ) then
			ErrorMsg = "Nu Replayer did not successfully open a socket to Planets Nu's servers."
		else
			if SDLNet_TCP_Send(NuSocket, strptr(SendBuffer), len(SendBuffer)) < len(SendBuffer) then
				ErrorMsg = "Nu Replayer did not successfully send its request to Planets Nu's servers."
			else
				mkdir "raw"
				open "raw/loadinfo.txt" for output as #7
	
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

		open "raw/loadinfo.txt" for input as #6
		do
			if eof(6) then
				ErrorMsg = "Nu Replayer could not successfully download one of the turn files due to lack of opening brace."
			end if
			line input #6, InStream
		loop until left(InStream,1) = "{"
		close #6
		
		if instr(Instream,"{"+quote("success")+":false") then
			ErrorMsg = "Nu Replayer could not successfully download one of the turn files due to API error."
		else
			SeekChar(0) = instr(InStream,quote("name"))
			SeekChar(1) = instr(SeekChar(0)+8,InStream,chr(34))
			GameName = mid(InStream, SeekChar(0)+8, SeekChar(1)-SeekChar(0)-8)

			SeekChar(0) = instr(InStream,quote("shortdescription"))
			SeekChar(1) = instr(SeekChar(0)+20,InStream,chr(34))
			ShortDesc = mid(InStream, SeekChar(0)+20, SeekChar(1)-SeekChar(0)-20)

			SeekChar(0) = instr(InStream,quote("status"))
			GameStatus = valint(mid(InStream,SeekChar(0)+9,3))
			if GameStatus = 3 then
				SeekChar(0) = instr(InStream,quote("turn"))
				FinalTurn = valint(mid(InStream,SeekChar(0)+7,4))
			else
				ErrorMsg = "This game is not finished."
			end if
		end if
	
		if GameName <> "" AND FinalTurn > 0 AND ErrorMsg = "" then
			if FileExists("games/Custom List.csv") = 0 then
				open "games/Custom List.csv" for output as #8
				print #8, quote("ID")+","+quote("Name")+","+quote("Desc")+","+quote("Turn")
				close #8
			end if
		
			open "games/Custom List.csv" for append as #9
			print #9, ""& GameNum;",";quote(GameName);",";quote(ShortDesc);","& FinalTurn
			close #9
		end if
	end if
	
	if ErrorMsg <> "" then
		print
		print word_wrap(ErrorMsg)
		screencopy
		sleep
	end if
end sub
