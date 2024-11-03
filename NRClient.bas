LastProgress = ""
#include "NRClient.bi"
#include "NuReport.bas"

sub renderClient
	dim as short TotalShips, TotalPlanets, Results
	dim as string TurnStr
	dim as ViewSpecs RelativePos, CursorPos

	/'
	 ' The client serves as a means to view the replay data
	 '/

	'Some objects get an animating rainbow color to differentiate from the rest
	with Rainbow
		if .Red = 255 AND .Green < 255 then
			if .Blue > 0 then
				.Blue -= 5
			else
				.Green += 5
			end if
		elseif .Green = 255 AND .Blue < 255 then
			if .Red > 0 then
				.Red -= 5
			else
				.Blue += 5
			end if
		elseif .Blue = 255 then
			if .Green > 0 then
				.Green -= 5
			else
				.Red += 5
			end if
		end if
	end with

	DestPattern = int(DestPattern / 2)
	if (DestPattern AND (1 SHL 8)) = 0 then
		DestPattern += 2^16
	end if

	if InType = CtrlJ then
		'Allows instantly jumping to any turn
		dim as ushort JumpCut, OldTurn
		dim as ubyte CutLegal, ProcessNeeded, ZipDLenabled = 0
		dim as string ScoreFile, AuxFile, RawFile, ZipFile
		dim as short TurnsPerRow = int((CanvasScreen.Wideth-20)/48)

		do
			color rgb(255,255,255)
			windowtitle WindowStr
			cls
			print "Instantly jump to which turn number? ";
			color rgb(255,255,0)
			print JumpCut
			color rgb(255,255,255)

			print "Turn status: ";
			CutLegal = 0
			ProcessNeeded = 0
			ScoreFile = "games/"+str(GameID)+"/"+str(JumpCut)+"/Score.csv"
			'AuxFile = "games/"+str(GameID)+"/Nebulae.csv"
			RawFile = "raw/"+str(GameID)+"/player1-turn"+str(JumpCut)+".trn"
			ZipFile = "raw/"+str(GameID)+"/game"+str(GameID)+".zip"
			
			if JumpCut = 0 then
				color rgb(255,128,128)
				print "Please input a turn number"
			elseif JumpCut > ViewGame.LastTurn then
				color rgb(255,128,128)
				print "Game has not lasted that long"
			elseif FileExists("games/"+str(GameID)+"/"+str(JumpCut)+"/Working") then
				color rgb(255,255,0)
				print "Being converted externally"
			elseif FileExists(ScoreFile) = 0 AND _
				dir("raw/"+str(GameID)+"/"+str(JumpCut),fbDirectory) = "" AND _
				FileExists(RawFile) = 0 then
				color rgb(128,128,128)
				print "Missing"
				ZipDLenabled = 1
			elseif FileExists(ScoreFile) = 0 then
				CutLegal = 1
				ProcessNeeded = 1
				color rgb(128,255,128)
				print "Ready for conversion"
			elseif FileDateTime(ScoreFile) < DataFormat then
				color rgb(255,128,128)
				if FileExists(RawFile) then
					CutLegal = 1
					ProcessNeeded = 1
					print "Data format compatibility broken. Re-conversion required"
				else
					print "Data format compatibility broken. No raw files available"
					ZipDLenabled = 1
				end if
			else
				CutLegal = 1
				color rgb(0,255,0)
				print "Available for viewing"
			end if
			color rgb(255,255,255)
			print
			print "Turn Reference for ";
			color rgb(0,255,255)
			print GameName
			for TID as short = 1 to ViewGame.LastTurn
				ScoreFile = "games/"+str(GameID)+"/"+str(TID)+"/Score.csv"
				'AuxFile = "games/"+str(GameID)+"/Nebulae.csv"
				RawFile = "raw/"+str(GameID)+"/player1-turn"+str(TID)+".trn"

				if FileExists("games/"+str(GameID)+"/"+str(TID)+"/Working") then
					if Now - FileDateTime("games/"+str(GameID)+"/"+str(TID)+"/Working") > 1/24 then
						'Assume conversions that take more than an hour have failed or been aborted, and delete the working flag
						kill("games/"+str(GameID)+"/"+str(TID)+"/Working")
						rmdir("games/"+str(GameID)+"/"+str(TID))
					end if
					color rgb(255,255,0)
				elseif FileExists(ScoreFile) = 0 then
					color rgb(128,128,128)
				elseif FileDateTime(ScoreFile) < DataFormat then
					if FileExists(RawFile) then
						color rgb(255,128,128)
					else
						color rgb(128,128,128)
					end if
				else
					color rgb(0,255,0)
				end if
				print space(5-len(str(TID)));TID;
				if remainder(TID,TurnsPerRow) = 0 then
					print
				end if
			next TID
			color rgb(255,255,255)
			print
			print
			if ZipDLenabled then
				if FileExists(ZipFile) then
					print "A ZIP package has been detected alongside the raw turn files. Hit ENTER on an invalid turn to unpack them."
				else
					print "You can use Nu Replayer to download a ZIP package containing the remaining turns. Hit ENTER on an invalid turn to proceed."
				end if
			end if
			
			if InType = EscKey AND JumpCut > 0 then
				JumpCut = 0
				InType = chr(255)
			elseif InType = CtrlQ then
				'Use a dedicated thread to process any remaining incomplete turns
				if ConvertorUse = 0 then
					ConvertorSes = ThreadCreate(@launchConvertor)
				end if
			elseif InType >= "0" AND InType <= "9" then
				JumpCut = JumpCut * 10 + valint(InType)
			elseif InType = chr(8) then
				JumpCut = int(JumpCut / 10)
			elseif InType = EnterKey AND CutLegal then
				OldTurn = TurnNum
				TurnNum = JumpCut
				if ProcessNeeded > 0 then
					TurnWIP = 1
					Results = loadTurn(GameId,JumpCut,0)
					TurnWIP = 0
					if QueueNextSong then
						QueueNextSong = 0
						#IFDEF __NR_AUDIO__
						cycleMusic
						#ENDIF
					end if
				end if
				loadTurnExtras
				exit do
			#IFDEF __DOWNLOAD_TURNS__
			elseif InType = EnterKey AND ZipDLenabled then
				if FileExists(ZipFile) then
					if unpackZipPackage(ZipFile, 0) = 0 then
						ZipDLenabled = 0
					else
						print word_wrap("Unpack sequence unsuccessful.")
						screencopy
						sleep
					end if
				else
					if downloadZipPackage(GameId) then
						ZipDLenabled = 0
					else
						print word_wrap(ErrorMsg)
						screencopy
						sleep
					end if
				end if
				ErrorMsg = ""
			#ENDIF
			end if
			if Results > 0 then
				TurnNum = OldTurn
			end if

			screencopy
			sleep 15
			InType = inkey
		loop until InType = EscKey
	end if

	if InType = FunctionFive then
		playerList
	elseif InType = FunctionSix then
		planetList
	elseif InType = FunctionSeven then
		shipList
	end if

	windowtitle WindowStr
	cls

	CanNavigate(0) = 0
	CanNavigate(1) = 0
	if TurnNum > 1 then
		if FileExists("games/"+str(GameID)+"/"+str(TurnNum-1)+"/Score.csv") AND _
			FileDateTime("games/"+str(GameID)+"/"+str(TurnNum-1)+"/Score.csv") >= DataFormat AND _
			FileExists("games/"+str(GameID)+"/"+str(TurnNum-1)+"/Working") = 0 then
			CanNavigate(0) = 2
		elseif FileExists("raw/"+str(GameID)+"/player1-turn"+str(TurnNum-1)+".trn") then
			CanNavigate(0) = 1
		end if
	end if

	if TurnNum < ViewGame.LastTurn then
		if	FileExists("games/"+str(GameID)+"/"+str(TurnNum+1)+"/Score.csv") AND _
			FileDateTime("games/"+str(GameID)+"/"+str(TurnNum+1)+"/Score.csv") >= DataFormat AND _
			FileExists("games/"+str(GameID)+"/"+str(TurnNum+1)+"/Working") = 0 then
			CanNavigate(1) = 2
		elseif FileExists("raw/"+str(GameID)+"/player1-turn"+str(TurnNum+1)+".trn") then
			CanNavigate(1) = 1
		end if
	end if

	'Mouse handling
	MouseError = getmouse(MouseX,MouseY,,ButtonCombo)

	'Resets dynamic statistics
	for RID as short = 1 to MaxPlayers
		with PlayerSlot(RID)
			.PlanetCount = 0
			.Starbases = 0
			.TotalNeu = 0
			if ViewGame.Academy = 0 then
				'Do not mess with these in Academy games, as players actually have global stockpiles 
				.TotalDur = 0
				.TotalTrit = 0
				.TotalMoly = 0
				.TotalMoney = 0
			end if
			.TotalClans = 0
			.TotalSupplies = 0
			.EconomicScore = (.TotalDur + .TotalTrit + .TotalMoly) * 3 + .TotalMoney
		end with
	next RID

	TotalShips = 0
	TotalPlanets = 0

	if RedrawIslands then
		line IslandMap,(0,0)-(4095,2159),rgb(255,0,255),bf
	end if
	
	'Scalable "Remastered"-style UI
	if MouseError = 0 then
		with CursorPos	
			.X = (MouseX / ViewPort.Zoom + ViewPort.X) - CanvasScreen.Height/2 / ViewPort.Zoom
			.Y = CanvasScreen.Height/2 / ViewPort.Zoom + (-MouseY / ViewPort.Zoom + ViewPort.Y)
		end with
	end if
	
	'Paint objects as appropriate
	for DrawLayer as byte = 1 to 3
		if DrawLayer = 2 AND ViewGame.Sphere then
			'Wraparound Border
			dim as integer WrapWidth, WrapHeight
			dim as ViewSpecs EndingPos
			
			WrapWidth = ViewGame.MapWidth + 20
			WrapHeight = ViewGame.MapHeight + 20
			
			RelativePos = getRelativePos(2000 - WrapWidth/2, 2000 - WrapHeight/2)
			EndingPos = getRelativePos(2000 + WrapWidth/2, 2000 + WrapHeight/2)
			line(RelativePos.X,RelativePos.Y)-(EndingPos.X,EndingPos.Y),rgb(255,255,255),b,&b1100110011001100
		end if
		
		for OID as integer = 1 to MetaLimit
			if DrawLayer = 1 then
				'Nebulae
				with Nebulae(OID)
					if .Intensity > 0 then
						RelativePos = getRelativePos(.X, .Y)
						circle(RelativePos.X,RelativePos.Y),.Radius*ViewPort.Zoom,rgb(0,16,4),,,,F
					end if
				end with
				
				if OID >= LimitObjs then
					exit for
				end if 
				
			elseif DrawLayer = 2 then
				if RedrawIslands = 0 AND OID = 1 then
					put (0,0),IslandMap,trans
				end if
				
				'Minefields
				with Minefields(OID)
					if .MineUnits > 0 then
						RelativePos = getRelativePos(.X, .Y)
						
						circle(RelativePos.X,RelativePos.Y),.Radius*ViewPort.Zoom,convertColor(Coloring(.Ownership))
					end if
				end with
				
			else
				'Nebulae selection
				with Nebulae(OID)
					if SelectedObjType = REPORT_NEB AND SelectedID = OID then
						RelativePos = getRelativePos(.X, .Y)
						for Seg as short = 10 to 350 step 20
							circle(RelativePos.X,RelativePos.Y),.Radius*ViewPort.Zoom,rgb(255,255,255),degtorad(Seg),degtorad(Seg+10)
						next Seg
					end if
				end with

				'Star Clusters
				with StarClusters(OID)
					if .Mass > 0 then
						dim as uinteger TempColor
						RelativePos = getRelativePos(.X, .Y)
						
						if .Temperature <= 3000 then
							TempColor = rgb(192,0,0)
						elseif .Temperature <= 6000 then
							TempColor = rgb(192,96,0)
						elseif .Temperature <= 10000 then
							TempColor = rgb(192,192,0)
						elseif .Temperature <= 20000 then
							TempColor = rgb(192,192,192)
						else
							TempColor = rgb(192,192,255)
						end if
						
						circle(RelativePos.X,RelativePos.Y),.Radius*ViewPort.Zoom,TempColor,,,,F
						if .Mass > .Radius^2 then
							for Seg as short = 0 to 350 step 10
								circle(RelativePos.X,RelativePos.Y),ceil(sqr(.Mass))*ViewPort.Zoom,TempColor,degtorad(Seg+2.5),degtorad(Seg+7.5)
							next Seg
						end if
					end if
				end with
	
				'Ion Storms
				with IonStorms(OID)
					if .Voltage > 0 then
						RelativePos = getRelativePos(.X, .Y)
						
						circle(RelativePos.X,RelativePos.Y),.Radius*ViewPort.Zoom,convertColor(Rainbow)
						line(RelativePos.X+cos(degtorad(90-.Heading))*.Warp^2*ViewPort.Zoom,RelativePos.Y-sin(degtorad(90-.Heading))*.Warp^2*ViewPort.Zoom)-_
							(RelativePos.X,RelativePos.Y),convertColor(Rainbow)
					end if
				end with
				
				'Wormholes
				with Wormholes(OID)
					if .Stability > 0 then
						dim as ViewSpecs EndingPos
						
						RelativePos = getRelativePos(.X, .Y)
						circle(RelativePos.X,RelativePos.Y),3,rgb(128,255,240)
						
						if .DestX > 0 AND (.DestX > .X OR (.DestX = .X AND .DestY > .Y)) then 
							EndingPos = getRelativePos(.DestX, .DestY)
							line(RelativePos.X,RelativePos.Y)-(EndingPos.X,EndingPos.Y),rgb(128,255,240),,&b0011110000111100
						end if
					end if
				end with
				
				'Artifacts
				with Artifacts(OID)
					if .Namee <> "" then
						RelativePos = getRelativePos(.X, .Y)
						
						drawFlag(RelativePos.X,RelativePos.Y)
					end if
				end with
				
				'Planets
				with Planets(OID)
					if .ObjName <> "" then
						RelativePos = getRelativePos(.X, .Y)
						
						'Check for connections
						if RedrawIslands = 1 AND RelativePos.X > -85 * ViewPort.Zoom AND RelativePos.Y > -85 * ViewPort.Zoom AND _
							RelativePos.X < CanvasScreen.Wideth + 85 * ViewPort.Zoom AND RelativePos.Y < CanvasScreen.Height + 85 * ViewPort.Zoom then
							for PID as short = OID+1 to LimitObjs
								if Planets(PID).ObjName <> "" AND sqr((.X - Planets(PID).X)^2 + (.Y - Planets(PID).Y)^2) <= 84.554 AND _
									.Asteroid = 0 AND Planets(PID).Asteroid = 0 then
									dim as ViewSpecs Neighbor
									
									Neighbor.X = (Planets(PID).X - ViewPort.X) * ViewPort.Zoom + CanvasScreen.Height/2
									Neighbor.Y = CanvasScreen.Height/2 - (Planets(PID).Y - ViewPort.Y) * ViewPort.Zoom
									
									line IslandMap,(RelativePos.X,RelativePos.Y)-(Neighbor.X,Neighbor.Y),rgb(48,48,48)
								end if 
							next PID
						end if
						
						if .Asteroid > 1 then
							for Seg as double = 12.5 to 357.5 step 15
								circle(RelativePos.X,RelativePos.Y),.Asteroid*ViewPort.Zoom,rgb(128,48,0),degtorad(Seg),degtorad(Seg+5)
							next Seg
						end if
						
						if .Ownership = 0 then
							dim as uinteger ScanColor = rgb(192,192,192)
							
							if .LastScan = 0 then
								ScanColor = rgb(64,64,64)
							end if
							pset(RelativePos.X,RelativePos.Y),ScanColor
						else
							PlayerSlot(.Ownership).PlanetCount += 1
							PlayerSlot(.Ownership).Starbases += sgn(.BasePresent)
							circle(RelativePos.X,RelativePos.Y),1+sgn(Planets(OID).BasePresent),convertColor(Coloring(.Ownership)),,,,F
			
							PlayerSlot(.Ownership).TotalNeu += .Neu
							PlayerSlot(.Ownership).TotalDur += .Dur
							PlayerSlot(.Ownership).TotalTrit += .Trit
							PlayerSlot(.Ownership).TotalMoly += .Moly
							PlayerSlot(.Ownership).TotalClans += .Colonists
							PlayerSlot(.Ownership).TotalMoney += .Megacredits
							PlayerSlot(.Ownership).TotalSupplies += .Supplies
							
							if .Asteroid = 0 then
								TotalPlanets += 1
							end if
						end if
					end if
				end with
				
				'Ships
				with Starships(OID)
					if .ShipType > 0 AND .Ownership > 0 then
						TotalShips += 1
					end if
					
					if .XLoc >= MinXPos AND .XLoc < MaxYPos AND .YLoc >= MinXPos AND .YLoc < MaxYPos AND _
						.Ownership > 0 then
						dim as short CalcX, CalcY, Orbiting
						RelativePos = getRelativePos(.XLoc, .YLoc)
		
						for PID as short = 1 to LimitObjs
							if Planets(PID).X = .XLoc AND Planets(PID).Y = .YLoc then
								Orbiting = 1
								exit for
							end if
						next PID
						
						if Orbiting then
							circle(RelativePos.X,RelativePos.Y),5,convertColor(Coloring(.Ownership))
						else
							pset(RelativePos.X,RelativePos.Y),convertColor(Coloring(.Ownership))
						end if
						
						if SelectedID = OID AND SelectedObjType = REPORT_SHIP AND _
							(.XLoc <> .TargetX OR .YLoc <> .TargetY) then
							dim as ViewSpecs EndingPos = getRelativePos(.TargetX, .TargetY)

							line(RelativePos.X,RelativePos.Y)-(EndingPos.X,EndingPos.Y),rgb(255,176,240),,DestPattern
						end if
					end if
				end with
				
				if OID >= LimitObjs then
					exit for
				end if 
			end if
		next OID
	next DrawLayer
	
	'Flexible Sidebar
	TurnStr = "Turn "+str(TurnNum)
	Sidebar = min(CanvasScreen.Wideth - gfxLength(GameName+" ",3,2,2) - gfxLength(TurnStr,3,2,2), CanvasScreen.Height)
	line(Sidebar,0)-(CanvasScreen.Wideth-1,39),ReportBG,bf
	
	gfxString(GameName,Sidebar,0,3,2,2,rgb(255,215,0))
	gfxString(TurnStr,Sidebar+gfxLength(GameName+" ",3,2,2),0,3,2,2,rgb(255,255,255))
	
	if SelectedObjType > 0 then
		getReport
	elseif MouseError = 0 then
		with CursorPos
			gfxString("("+str(.X)+","+str(.Y)+")",Sidebar,20,3,2,2,rgb(255,255,255))
		end with
		
		drawCursor(MouseX,MouseY)
		
		'Object selection
		if (ButtonCombo AND (1 SHL 0)) then
			dim as double MinDist = 1e6, CurDist
			
			for OID as integer = 1 to MetaLimit
				if OID < LimitObjs then
					with IonStorms(OID)
						if .Voltage > 0 then
							RelativePos = getRelativePos(.X, .Y)
							CurDist = sqr((RelativePos.X - MouseX)^2 + (RelativePos.Y - MouseY)^2)
							
							if CurDist < MinDist then
								MinDist = CurDist
								SelectedObjType = REPORT_ION
								SelectedID = OID
							end if
						end if
					end with
					
					with Starships(OID)
						if .ShipType > 0 then
							RelativePos = getRelativePos(.XLoc, .YLoc)
							CurDist = sqr((RelativePos.X - MouseX)^2 + (RelativePos.Y - MouseY)^2)
							
							if CurDist < MinDist then
								MinDist = CurDist
								SelectedObjType = REPORT_SHIP
								SelectedID = OID
							end if
						end if
					end with
					
					with StarClusters(OID)
						if .Mass > 0 then
							RelativePos = getRelativePos(.X, .Y)
							CurDist = sqr((RelativePos.X - MouseX)^2 + (RelativePos.Y - MouseY)^2)
							
							if CurDist < MinDist then
								MinDist = CurDist
								SelectedObjType = REPORT_STAR
								SelectedID = OID
							end if
						end if
					end with
					
					with Planets(OID)		
						if .ObjName <> "" then				
							RelativePos = getRelativePos(.X, .Y)
							CurDist = sqr((RelativePos.X - MouseX)^2 + (RelativePos.Y - MouseY)^2)
							
							if CurDist <= MinDist then
								MinDist = CurDist
								SelectedObjType = REPORT_PLAN
								SelectedID = OID
							end if
						end if
					end with
					
					with Nebulae(OID)
						if .Intensity > 0 then
							RelativePos = getRelativePos(.X, .Y)
							CurDist = sqr((RelativePos.X - MouseX)^2 + (RelativePos.Y - MouseY)^2)
							
							if CurDist < MinDist then
								MinDist = CurDist
								SelectedObjType = REPORT_NEB
								SelectedID = OID
							end if
						end if
					end with
				
					with Wormholes(OID)
						if .Stability > 0 then
							RelativePos = getRelativePos(.X, .Y)
							CurDist = sqr((RelativePos.X - MouseX)^2 + (RelativePos.Y - MouseY)^2)
								
							if CurDist < MinDist then
								MinDist = CurDist
								SelectedObjType = REPORT_WORM
								SelectedID = OID
							end if
						end if
					end with
				end if
				
				with Minefields(OID)
					if .MineUnits > 0 then
						RelativePos = getRelativePos(.X, .Y)
						CurDist = sqr((RelativePos.X - MouseX)^2 + (RelativePos.Y - MouseY)^2)
						
						if CurDist < MinDist then
							MinDist = CurDist
							SelectedObjType = REPORT_MINE
							SelectedID = OID
						end if
					end if
				end with
				
				AuxList(OID) = ResetAux
			next OID
			
			syncReport(1)
		end if
	else
		gfxString(commaSep(TotalPlanets)+" planets + "+commaSep(TotalShips)+" ships",Sidebar,20,3,2,2,rgb(255,255,255))
	end if

	RedrawIslands = max(RedrawIslands - 1, 0)
	'Allow scrolling while no object is selected and no slideshow is active
	if MouseError = 0 AND SelectedObjType = 0 AND NextMapSlide = 0 then
		if MouseX <= 16 AND ViewPort.X > 2000 - ViewGame.MapWidth/2 then
			ViewPort.X -= 8 / ViewPort.Zoom
			RedrawIslands = 2
		end if
		if MouseX >= CanvasScreen.Wideth - 16 AND ViewPort.X < 2000 + ViewGame.MapWidth/2 then
			ViewPort.X += 8 / ViewPort.Zoom
			RedrawIslands = 2
		end if

		if MouseY >= CanvasScreen.Height - 16 AND ViewPort.Y > 2000 - ViewGame.MapHeight/2 then
			ViewPort.Y -= 8 / ViewPort.Zoom
			RedrawIslands = 2
		end if
		if MouseY <= 16 AND ViewPort.Y < 2000 + ViewGame.MapHeight/2 then
			ViewPort.Y += 8 / ViewPort.Zoom
			RedrawIslands = 2
		end if
	end if
	
	screencopy
	sleep 15
	InType = inkey
	if left(InType,1) <> chr(255) then
		InType = lcase(InType)
	end if
	if NextMapSlide > 0 AND (InType <> "" OR ButtonCombo > 0 OR CanNavigate(1) < 2) then
		NextMapSlide = 0
	end if
	for NID as byte = 1 to 10
		if InType = right(str(NID),1) then
			dim as short SelAux = NID + AuxPage * 10
			if SelAux <= AuxCount then
				with AuxList(SelAux)
					SelectedID = .ObjID
					SelectedObjType = .ObjType
				end with
			end if
		end if
	next NID
	
	if NextMapSlide > 0 AND timer > NextMapSlide then
		TurnNum += 1
		loadTurnExtras
		NextMapSlide = max(NextMapSlide + SlideshowDelay/1000,timer + SlideshowDelay/2000)
	end if
	
	select case InType
		case "i"
			'Goes back one turn, if possible
			if CanNavigate(0) = 2 then
				TurnNum -= 1
				loadTurnExtras
			elseif CanNavigate(0) = 1 then
				Results = loadTurn(GameId,TurnNum-1,0)
				while inkey <> "":wend
				
				if Results = 0 then
					TurnNum -= 1
					loadTurnExtras
				end if
			end if
		case "o"
			'Goes forward one turn
			if CanNavigate(1) = 2 then
				TurnNum += 1
				loadTurnExtras
			elseif CanNavigate(1) = 1 then
				Results = loadTurn(GameId,TurnNum+1,0)
				while inkey <> "":wend
				
				if Results = 0 then
					TurnNum += 1
					loadTurnExtras
				end if
			end if
		case "-"
			ViewPort.Zoom = max(ViewPort.Zoom / 2, 0.25)
			RedrawIslands = 1
		case "+"
			ViewPort.Zoom = min(ViewPort.Zoom * 2, 8)
			RedrawIslands = 1
		case "b"
			if BaseFound > 0 AND SelectedObjType <> REPORT_BASE then
				SelectedObjType = REPORT_BASE
				SelectedID = BaseFound
				
				StorePage = 0
			end if
		case "p"
			if PlanetFound > 0 AND SelectedObjType <> REPORT_PLAN then
				SelectedObjType = REPORT_PLAN
				SelectedID = PlanetFound
			end if
		case HomeKey
			if StorePage > 0 then
				StorePage -= 1
			end if
		case EndKey
			if MoreStorage then
				StorePage += 1
			end if
		case PageUp
			if AuxPage > 0 then
				AuxPage -= 1
			end if
		case PageDown
			if AuxPage < ceil(AuxCount/10) - 1 then
				AuxPage += 1
			end if
		case "x"
			clearReport
		case CtrlQ
			if ConvertorUse = 0 then
				ConvertorSes = ThreadCreate(@launchConvertor)
			end if
		case CtrlW
			NextMapSlide = timer + SlideshowDelay/500
			InType = ""
		case CtrlR
			'Reloads the starmap
			updateStarmap
		case FunctionTwelve
			'Takes a snapshot of the client
			bsave("shot.bmp",0)
		case chr(255,107)
			'Ensures program is closed by hitting the X button
			ReplayerMode = MODE_EXIT
		case EscKey
			'If in a game and holding SHIFT, then exit. Otherwise, return to main menu
			if multikey(SC_LSHIFT) then
				ReplayerMode = MODE_EXIT
			else
				if BaseScreen.Wideth > 1024 AND BaseScreen.Height > 768 AND SimpleView = 0 then
					prepCanvas(1024,768)
				else
					setmouse(,,0)
				end if
				
				resetViewport
				SelectedObjType = 0
				ViewGame.PlayerCount = 0
				GameID = 0
				ReplayerMode = MODE_MENU
				InType = chr(255)
			end if
	end select
end sub
