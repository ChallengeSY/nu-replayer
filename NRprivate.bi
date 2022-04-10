sub importPrivateGame
	dim as string InStream
	dim as integer GameNum
	dim as string GameName
	dim as string ShortDesc
	dim as integer GameStatus
	dim as integer FinalTurn
	
	dim SendBuffer as string
	dim RecvBuffer as zstring * RECVBUFFLEN+1
	dim Bytes as integer
	dim LinesReceived as ushort
	
	do
		line(CanvasScreen.Wideth/2+10,250)-(CanvasScreen.Wideth-6,274),rgb(0,0,0),bf
		gfxstring("Enter Game ID: "+str(GameNum),CanvasScreen.Wideth/2+10,250,5,4,2,rgb(255,255,0))

		if InType = chr(27) then
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
	loop until InType = chr(13)
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
		
		if strMatch(Instream,1,"{"+quote("success")+":false") then
			ErrorMsg = "Nu Replayer could not successfully download one of the turn files due to API error."
		else
			for DID as integer = 1 to len(InStream)
				if strMatch(InStream,DID,quote("name")) then
					for StringLen as short = 2 to 500
						GameName = mid(InStream,DID+7,StringLen)
						if right(GameName,1) = chr(34) then
							exit for
						end if
					next StringLen
				end if

				if strMatch(InStream,DID,quote("shortdescription")) then
					for StringLen as short = 2 to 500
						ShortDesc = mid(InStream,DID+19,StringLen)
						if right(ShortDesc,1) = chr(34) then
							exit for
						end if
					next StringLen
				end if
		
				if strMatch(InStream,DID,quote("status")+":") then
					GameStatus = valint(mid(InStream,DID+9,4))
					
					if GameStatus <> 3 then
						ErrorMsg = "This game is not finished."
						exit for
					end if
				end if

				if strMatch(InStream,DID,quote("turn")+":") then
					FinalTurn = valint(mid(InStream,DID+7,4))
				end if
				
				if strMatch(InStream,DID,quote("settings")+":{") then
					'We are done here
					exit for
				end if
			next DID
		end if
	
		if GameName <> "" AND FinalTurn > 0 AND ErrorMsg = "" then
			if FileExists("games/Custom List.csv") = 0 then
				open "games/Custom List.csv" for output as #8
				print #8, quote("ID")+","+quote("Name")+","+quote("Desc")+","+quote("Turn")
				close #8
			end if
		
			open "games/Custom List.csv" for append as #9
			print #9, ""& GameNum;",";GameName;",";ShortDesc;","& FinalTurn
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
