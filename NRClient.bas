LastProgress = ""
#include "NRClient.bi"

sub renderClient
	dim as short Sidebar, DiamondBase, MapSize, AbsMin, DiamH, DiamL, TotalShips, TotalPlanets
	dim as uinteger PaintColor(2)
	dim as string TurnStr

	Sidebar = CanvasScreen.Wideth - 768
	with ViewGame
		MapSize = max(.MapWidth,.MapHeight)
		AbsMin = 2000 - MapSize/2
	end with 

	/'
	 ' The client serves as a means to view the replay data
	 '/

	'Game title gets an animating rainbow color to differentiate from the rest of the text
	with GameTitle
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

	if InType = CtrlJ then
		'Allows instantly jumping to any turn
		dim as ushort JumpCut, OldTurn
		dim as ubyte CutLegal, ProcessNeeded, ZipDLenabled = 0
		dim as byte Results
		dim as string ScoreFile, AuxFile, RawFile, ZipFile

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
			AuxFile = "games/"+str(GameID)+"/"+str(JumpCut)+"/Ion Storms.csv"
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
			elseif FileExists(AuxFile) = 0 OR FileDateTime(AuxFile) < DataFormat then
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
				AuxFile = "games/"+str(GameID)+"/"+str(TID)+"/Ion Storms.csv"
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
				elseif FileExists(AuxFile) = 0 OR FileDateTime(AuxFile) < DataFormat then
					if FileExists(RawFile) then
						color rgb(255,128,128)
					else
						color rgb(128,128,128)
					end if
				else
					color rgb(0,255,0)
				end if
				print space(5-len(str(TID)));TID;
				if remainder(TID,20) = 0 then
					print
				end if
			next TID
			color rgb(255,255,255)
			print
			print
			if ZipDLenabled then
				if FileExists(ZipFile) then
					print "A ZIP package has been detected alongside the raw turn files. Simply extract it to acquire the remaining turns."
				else
					print "You can use Nu Replayer to download a ZIP package containing the remaining turns. Hit ENTER on an invalid turn to proceed."
				end if
			end if
			
			if InType = chr(27) AND JumpCut > 0 then
				JumpCut = 0
				InType = chr(255)
			elseif InType >= "0" AND InType <= "9" then
				JumpCut = JumpCut * 10 + valint(InType)
			elseif InType = chr(8) then
				JumpCut = int(JumpCut / 10)
			elseif InType = chr(13) AND CutLegal then
				OldTurn = TurnNum
				TurnNum = JumpCut
				if ProcessNeeded > 0 then
					TurnWIP = 1
					cls
					color rgb(255,255,255)
					print word_wrap("Now converting turn "+str(JumpCut)+" for "+GameName+_
						". This may take several minutes depending on game specifications...")
					print
					print word_wrap("Once conversion is complete, Nu Replayer will "+_
						"automatically jump to the newly created turn.")

					line(0,748)-(1023,767),rgb(255,255,255),b
					screencopy
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
			elseif InType = chr(13) AND ZipDLenabled AND FileExists(ZipFile) = 0 then
				if downloadZipPackage(GameId) then
					ZipDLenabled = 0
				else
					print word_wrap(ErrorMsg)
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
		loop until InType = chr(27)
	end if

	if InType = FunctionFive then
		playerList
	elseif InType = FunctionSix then
		planetList
	elseif InType = FunctionSeven then
		shipList
	end if


	dim as string NativeRaces(1 to 11) => {"Humanoid", "Bovinoid", "Reptilian", _
		"Avian", "Amorphou", "Insectoid", "Amphibian", "Ghipsodal", "Siliconoid", _
		"", "Botanical"}

	windowtitle WindowStr
	cls

	if TurnNum > 1 AND _
		FileExists("games/"+str(GameID)+"/"+str(TurnNum-1)+"/Ion Storms.csv") AND _
		FileDateTime("games/"+str(GameID)+"/"+str(TurnNum-1)+"/Ion Storms.csv") >= DataFormat AND _
		FileExists("games/"+str(GameID)+"/"+str(TurnNum-1)+"/Working") = 0 then
		CanNavigate(0) = 1
	else
		CanNavigate(0) = 0
	end if

	if TurnNum < ViewGame.LastTurn AND _
		FileExists("games/"+str(GameID)+"/"+str(TurnNum+1)+"/Ion Storms.csv") AND _
		FileDateTime("games/"+str(GameID)+"/"+str(TurnNum+1)+"/Ion Storms.csv") >= DataFormat AND _
		FileExists("games/"+str(GameID)+"/"+str(TurnNum+1)+"/Working") = 0 then
		CanNavigate(1) = 1
	else
		CanNavigate(1) = 0
	end if

	/'
	'Fading effect for the selected player's planets
	FadingSelect += 3
	if FadingSelect > 255 then
		FadingSelect = -255
	elseif FadingSelect >= -144 AND FadingSelect < 144 then
		FadingSelect = 144
	end if
	'/

	' Checks mouse coordinates
	MouseError = getmouse(MouseX,MouseY)

	if ReplayerMode = MODE_CLIENT_NORMAL AND ViewGame.Academy = 0 then
		' If in Normal mode, it applies a faint territory map
		put (0,0),TerritoryMap,trans
	elseif ReplayerMode = MODE_CLIENT_ISLAND then
		' If in Island mode, it applies the island map
		put (0,0),IslandMap,trans
	end if

	' Highlights the territory of the selected planet
	if ViewGame.Academy = 0 then
		for TerrY as short = 0 to 767
			for TerrX as short = 0 to 767
				with Coloring(Planets(Territory(TerrX,TerrY)).Ownership)
					if Territory(TerrX,TerrY) = NearestPlan then
						pset (TerrX,TerrY),rgba(.Red,.Green,.Blue,64)
					end if
				end with
			next TerrX
		next TerrY
	end if

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
			.TotalSupplies = 0
			.TotalTerritory = 0
			.EconomicScore = (.TotalDur + .TotalTrit + .TotalMoly) * 3 + .TotalMoney
		end with
	next RID

	TotalShips = 0
	TotalPlanets = 0

	'Plots the planets down, and colors them according to ownership
	for PID as short = 1 to LimitObjs
		with Planets(PID)
			if .X >= MinXPos AND .X < MaxXPos AND .Y >= MinYPos AND .Y < MaxYPos then
				dim as short CalcX, CalcY
				CalcX = (.X-AbsMin)/MapSize*766
				CalcY = 767-(.Y-AbsMin)/MapSize*766
				if .Ownership = 0 then
					if .LastScan = 0 then
						pset(CalcX,CalcY),rgb(64,64,64)
					else
						pset(CalcX,CalcY),rgb(192,192,192)
					end if
				else
					PlayerSlot(.Ownership).PlanetCount += 1
					PlayerSlot(.Ownership).Starbases += sgn(.BasePresent)
					if ReplayerMode = MODE_CLIENT_NORMAL then
						with Coloring(.Ownership)
							circle(CalcX,CalcY),1+sgn(Planets(PID).BasePresent),rgb(.Red,.Green,.Blue),,,,F
						end with
					else
						with Coloring(.Ownership)
							circle(CalcX,CalcY),1+sgn(Planets(PID).BasePresent),rgba(.Red,.Green,.Blue,192),,,,F
						end with
					end if

					PlayerSlot(.Ownership).TotalNeu += .Neu
					PlayerSlot(.Ownership).TotalDur += .Dur
					PlayerSlot(.Ownership).TotalTrit += .Trit
					PlayerSlot(.Ownership).TotalMoly += .Moly
					PlayerSlot(.Ownership).TotalMoney += .Megacredits
					PlayerSlot(.Ownership).TotalSupplies += .Supplies
					PlayerSlot(.Ownership).TotalTerritory += .TerritoryValue
					TotalPlanets += 1
				end if
			end if
		end with
	next PID
	
	'Use custom select style in Academy games
	if (NearestPlan > 0 OR ShipsFound > 0) AND ViewGame.Academy then
		dim as short CalcX, CalcY, SelRadius
		CalcX = (ActualX-AbsMin)/MapSize*766
		CalcY = 767-(ActualY-AbsMin)/MapSize*766
		SelRadius = 5 + int((GameTitle.Red + GameTitle.Green + GameTitle.Blue + 1)/128)
		
		circle(CalcX,CalcY),SelRadius,rgb(255,255,255),degtorad(22.5),degtorad(67.5)
		circle(CalcX,CalcY),SelRadius,rgb(255,255,255),degtorad(112.5),degtorad(157.5)
		circle(CalcX,CalcY),SelRadius,rgb(255,255,255),degtorad(202.5),degtorad(247.5)
		circle(CalcX,CalcY),SelRadius,rgb(255,255,255),degtorad(292.5),degtorad(337.5)
	end if

	if ReplayerMode = MODE_CLIENT_NORMAL then
		'In Normal mode, the ships get rendered alongside the territory
		for SID as short = 1 to LimitObjs
			with Starships(SID)
				if .ShipType > 0 AND .Ownership > 0 then
					TotalShips += 1
				end if
				
				if .XLoc >= MinXPos AND .XLoc < MaxYPos AND .YLoc >= MinXPos AND .YLoc < MaxYPos AND _
					.Ownership > 0 then
					dim as short CalcX, CalcY, Orbiting
					CalcX = (.XLoc-AbsMin)/MapSize*766
					CalcY = 767-(.YLoc-AbsMin)/MapSize*766

					for PID as short = 1 to LimitObjs
						if Planets(PID).X = .XLoc AND Planets(PID).Y = .YLoc then
							Orbiting = 1
							exit for
						end if
					next PID


					with Coloring(.Ownership)
						if Orbiting then
							circle(CalcX,CalcY),5,rgb(.Red,.Green,.Blue)
						else
							pset(CalcX,CalcY),rgb(.Red,.Green,.Blue)
						end if
					end with
				end if
			end with
		next SID
	end if

	'Creates a game summary. It can contain the players, or a planet report
	with GameTitle
		gfxString(GameName, min(768 + Sidebar - gfxLength(GameName,3,2,2), 768) ,0,3,2,2,rgb(.Red,.Green,.Blue))
	end with
	TurnStr = "Turn "+str(TurnNum)

	'Turn navigation keys
	if CanNavigate(0) then
		TurnStr += " [pgup]"
	else
		TurnStr += " [----]"
	end if

	if CanNavigate(1) then
		TurnStr += " [pgdn]"
	else
		TurnStr += " [----]"
	end if

	gfxString(TurnStr,768,20,3,2,2,rgb(255,255,255))

	if NearestPlan <= 0 AND ShipsFound = 0 then
		dim as byte PlayersFound = 0
		
		'If no planets or ships are selected, then this provides a player list
		for RID as short = 1 to ParticipatingPlayers
			with PlayerSlot(RID)
				if len(.Race) > 0 AND len(.PlayerName) > 0 AND .Race <> "Unassigned" then
					PlayersFound += 1 
					dim as string PrintStr = .Race + " (" + .PlayerName + ")"
					if gfxLength(PrintStr,3,2,2) >= Sidebar then
						PrintStr = .PlayerName
					end if
					with Coloring(RID)
						PaintColor(1) = rgb(.Red,.Green,.Blue)
						PaintColor(2) = rgb(.Red * .75,.Green * .75,.Blue * .75)
						if PlayerSlot(RID).PlanetCount > 0 then
							line(1024,(PlayersFound+1)*20-2)-(1024+PlayerSlot(RID).Starbases,(PlayersFound+2)*20-4),PaintColor(2),bf

							DiamondBase = 1024 + PlayerSlot(RID).PlanetCount
							for DiamSize as byte = 0 to 9
								DiamL = (PlayersFound+1)*20-2 + DiamSize
								DiamH = (PlayersFound+2)*20-4 - DiamSize
								if DiamondBase-DiamSize >= 1024 then
									line(DiamondBase-DiamSize,DiamL)-(DiamondBase-DiamSize,DiamH),PaintColor(2)
								end if
								line(DiamondBase+DiamSize,DiamL)-(DiamondBase+DiamSize,DiamH),PaintColor(2)
							next
						end if
					end with
					gfxString(PrintStr,768,(PlayersFound+1)*20,3,2,2,PaintColor(1))
				end if
			end with
		next RID
		
		if MouseError = 0 AND ActualX >= 0 AND ActualY >= 0 then
			gfxString("("+str(ActualX)+","+str(ActualY)+")",768,733,3,2,2,rgb(255,255,255))
		end if
		if ReplayerMode = MODE_CLIENT_NORMAL then
			gfxString(str(TotalPlanets)+" planets, "+str(TotalShips)+" ships",768,753,3,2,2,rgb(255,255,255))
		end if
	elseif NearestPlan <= 0 then
		dim as ushort ShipsCounted
		gfxString("("+str(ActualX)+","+str(ActualY)+")",768,40,3,2,2,rgb(192,192,192))
		gfxString("Deep space",768,60,3,2,2,rgb(255,255,255))
		ShipsCounted = 0
		for SID as short = 1 to LimitObjs
			with Starships(SID)
				if ViewGame.Academy then
					if .XLoc = ActualX AND .YLoc = ActualY AND .ShipType > 0 then
						with Coloring(.Ownership)
							PaintColor(1) = rgb(.Red,.Green,.Blue)
						end with
						
						ShipsCounted += 1
						gfxstring(" "+str(SID)+". "+.ShipName,768,245+ShipsCounted*15,2,2,1,PaintColor(1))
					end if
				end if
			end with
		next SID
		gfxString("Ships found: "+str(ShipsCounted),768,240,3,2,2,rgb(255,255,255))
	else
		dim as string FullObjName, ClimateStr, NativeStr, ResourceStr
		dim as integer PopulationNum, UsableMetals, MinableOre, OreDensity, MiningRate, RacialMining, _
			MaxNatives
		dim as ushort ShipCX, ShipCY, ShipsCounted
		dim as double MaxColonists

		'With a planet selected, this provides a planet report with ships that are closest to the planet
		with Planets(NearestPlan)
			if ViewGame.Academy then
				gfxString("("+str(ActualX)+","+str(ActualY)+")",768,40,3,2,2,rgb(192,192,192))
			else
				gfxString("Nearest Planet: "+str(NearestPlan),768,40,3,2,2,rgb(192,192,192))
			end if
			FullObjName = .ObjName
			ClimateStr = "Climate: "
			MaxColonists = sin(3.14 * (100 - .Temp)/100) * 100000
			MaxNatives = sin(3.14 * (100 - .Temp)/100) * 150000
			if .Temp < 15 then
				ClimateStr += "Arctic "+str(.Temp)
				MaxColonists = (299.9 + (200 * .Temp)) / ClimateDeathRate
			elseif .Temp < 38 then
				ClimateStr += "Cool   "+str(.Temp)
			elseif .Temp < 63 then
				ClimateStr += "Warm   "+str(.Temp)
			elseif .Temp < 85 then
				ClimateStr += "Tropic "+str(.Temp)
			else
				ClimateStr += "Desert "+str(.Temp)
				MaxColonists = (20099.9 - (200 * .Temp)) / ClimateDeathRate
			end if
			
			if .NativeType = 9 then
				MaxNatives = .Temp * 1000
			end if
			
			if .Natives > MaxNatives then
				'Ensure that the meter remains solid. Besides, excess natives do not die
				MaxNatives = .Natives
			end if
			
			if .Ownership = 0 then
				FullObjName += " [unowned]"

				gfxString(FullObjName,768,60,3,2,2,rgb(255,255,255))
				if .LastScan = 0 then
					gfxString("Never scanned",768,80,3,2,2,rgb(128,128,128))
				else
					if .LastScan = TurnNum then
						gfxString("Current information",768,80,3,2,2,rgb(192,192,192))
					else
						gfxString("Last scanned turn "+str(.LastScan),768,80,3,2,2,rgb(192,192,192))
					end if
					if ViewGame.Academy = 0 then
						ClimateStr += " (FC "+str(.FCode)+")"
					end if

					gfxString(ClimateStr,768,100,3,2,2,rgb(255,255,255))

					if .Natives > 0 then
						PaintColor(1) = rgb(128,80,80)
						line(1024,138)-(1024+int(.Natives/PopDividor),156),PaintColor(1),bf

						DiamondBase = max(1024,1024+int(MaxNatives/PopDividor))
						for DiamSize as byte = 0 to 9
							DiamL = 138 + DiamSize
							DiamH = 156 - DiamSize
							if DiamondBase-DiamSize >= 1024 then
								line(DiamondBase-DiamSize,DiamL)-(DiamondBase-DiamSize,DiamH),PaintColor(1)
							end if
							line(DiamondBase+DiamSize,DiamL)-(DiamondBase+DiamSize,DiamH),PaintColor(1)
						next

						PopulationNum = .Natives * 100
						NativeStr = commaSep(PopulationNum)+" "
						if (.NativeType >= 1 AND .NativeType <= 11) then
							NativeStr += NativeRaces(.NativeType)
						else
							NativeStr += "Chupanoid"
						end if
						NativeStr += "s ("+str(.NativeGov*20)+"%)"
						gfxString(NativeStr,768,140,3,2,2,rgb(255,255,255))
					else
						gfxString("No native life",768,140,3,2,2,rgb(255,255,255))
					end if

					if ViewGame.Academy then
						for Mineral as byte = 1 to 3
							select case Mineral
								case 1 'Duranium
									PaintColor(1) = rgb(128,64,128)
									UsableMetals = .Dur
									MinableOre = .GDur
									OreDensity = .DDur
									ResourceStr = "Du: "
	
								case 2 'Tritanium
									PaintColor(1) = rgb(64,32,128)
									UsableMetals = .Trit
									MinableOre = .GTrit
									OreDensity = .DTrit
									ResourceStr = "Tr: "
	
								case 3 'Molybdenum
									PaintColor(1) = rgb(128,128,0)
									UsableMetals = .Moly
									MinableOre = .GMoly
									OreDensity = .DMoly
									ResourceStr = "Mo: "
	
							end select
							
							if MinableOre > 0 then
								line(1024,158+Mineral*20)-(1024+int(MinableOre/50),176+Mineral*20),PaintColor(1),bf
							end if
	
							PaintColor(1) = rgb(255,255,255)
							
							if MinableOre >= 0 then
								ResourceStr += str(MinableOre)+" ore ("+str(OreDensity)+"%)"
							else
								ResourceStr += "? ore (?%)"
							end if
							gfxString(ResourceStr,768,160+Mineral*20,3,2,2,PaintColor(1))
						next Mineral

						if .MineralMines = -1 then
							ResourceStr = "Mines: ?/"
						else
							ResourceStr = "Mines: "+str(.MineralMines)+"/"
						end if
						if .Factories = -1 then
							ResourceStr += "Factories: ?"
						else
							ResourceStr += "Factories: "+str(.Factories)
						end if
						gfxString(ResourceStr,768,240,3,2,2,rgb(255,255,255))
					else
						for Mineral as byte = 1 to 4
							select case Mineral
								case 1 'Neutronium
									PaintColor(1) = rgb(0,128,0)
									UsableMetals = .Neu
									MinableOre = .GNeu
									OreDensity = .DNeu
									ResourceStr = "Ne: "
	
								case 2 'Duranium
									PaintColor(1) = rgb(128,64,128)
									UsableMetals = .Dur
									MinableOre = .GDur
									OreDensity = .DDur
									ResourceStr = "Du: "
	
								case 3 'Tritanium
									PaintColor(1) = rgb(64,32,128)
									UsableMetals = .Trit
									MinableOre = .GTrit
									OreDensity = .DTrit
									ResourceStr = "Tr: "
	
								case 4 'Molybdenum
									PaintColor(1) = rgb(128,128,0)
									UsableMetals = .Moly
									MinableOre = .GMoly
									OreDensity = .DMoly
									ResourceStr = "Mo: "
	
							end select
	
							if UsableMetals > 0 then
								line(1024,158+Mineral*20)-(1024+int(UsableMetals/50),176+Mineral*20),PaintColor(1),bf
							end if
	
							DiamondBase = max(1024,1024+int((UsableMetals+MinableOre)/50))
							for DiamSize as byte = 0 to 9
								DiamL = 158+Mineral*20 + DiamSize
								DiamH = 176+Mineral*20 - DiamSize
								if DiamondBase-DiamSize >= 1024 then
									line(DiamondBase-DiamSize,DiamL)-(DiamondBase-DiamSize,DiamH),PaintColor(1)
								end if
								line(DiamondBase+DiamSize,DiamL)-(DiamondBase+DiamSize,DiamH),PaintColor(1)
							next
	
							PaintColor(1) = rgb(255,255,255)
							if MinableOre >= 0 then
								ResourceStr += str(UsableMetals)+"/"+str(MinableOre)+" ("+str(OreDensity)+"%)"
							else
								ResourceStr += "?/? (?%)"
							end if
							gfxString(ResourceStr,768,160+Mineral*20,3,2,2,PaintColor(1))
						next Mineral
	
						if .Megacredits = -1 then
							ResourceStr = "Cash: ?/"
						else
							ResourceStr = "Cash: "+str(.Megacredits)+"/"
						end if
						if .Supplies = -1 then
							ResourceStr += "Supplies: ?"
						else
							ResourceStr += "Supplies: "+str(.Supplies)
						end if
						gfxString(ResourceStr,768,260,3,2,2,rgb(255,255,255))
						if .MineralMines = -1 then
							ResourceStr = "Mines: ?/"
						else
							ResourceStr = "Mines: "+str(.MineralMines)+"/"
						end if
						if .Factories = -1 then
							ResourceStr += "Factories: ?"
						else
							ResourceStr += "Factories: "+str(.Factories)
						end if
						gfxString(ResourceStr,768,280,3,2,2,rgb(255,255,255))
					end if
				end if
			else
				dim as string OwnerStr
				with PlayerSlot(.Ownership)
					OwnerStr = .Race + " (" + .PlayerName + ")"
					if gfxLength(OwnerStr,3,2,2) >= Sidebar then
						OwnerStr = .PlayerName
					end if
				end with
					
				'Uses default mining rates
				if PlayerSlot(.OwnerShip).Race = "Lizard" then
					RacialMining = 200
				elseif PlayerSlot(.OwnerShip).Race = "Fed" then
					RacialMining = 70
				else
					RacialMining = 100
				end if
				
				if PlayerSlot(.Ownership).Race = "Crystalline" then
					MaxColonists = 1000 * .Temp
				elseif PlayerSlot(.Ownership).Race = "Rebel" then
					if .Temp < 20 then
						MaxColonists = 90000
					elseif .Temp >= 80 AND MaxColonists < 60 then
						MaxColonists = 60
					end if
				elseif (PlayerSlot(.Ownership).Race = "Fascist" OR PlayerSlot(.Ownership).Race = "Robotic" OR PlayerSlot(.Ownership).Race = "Colonial") AND _
					.Temp >= 80 AND MaxColonists < 60 then
					MaxColonists = 60
				end if
				
				'Newly discovered Botanicals allow for 50% more colonists
				if .NativeType = 11 AND .Natives > 0 then
					MaxColonists = int(MaxColonists * 1.5)
				else
					MaxColonists = int(MaxColonists)
				end if
				
				if .Colonists > MaxColonists then
					'Ensure that the meter remains solid
					MaxColonists = .Colonists
				end if

				if .BasePresent <= 0 then
					FullObjName += " [no base]"
				else
					if .DNeu = 50 AND .DDur = 15 AND .DTrit = 20 AND .DMoly = 95 then
						FullObjName += " [homeworld]"
					else
						FullObjName += " [starbase]"
					end if
				end if

				with Coloring(.Ownership)
					PaintColor(1) = rgb(.Red,.Green,.Blue)
				end with

				gfxString(FullObjName,768,60,3,2,2,rgb(255,255,255))
				gfxString(OwnerStr,768,80,3,2,2,PaintColor(1))
				if ViewGame.Academy = 0 then
					ClimateStr += " (FC "+str(.FCode)+")"
				end if

				PaintColor(1) = rgb(64,128,128)
				line(1024,118)-(1024+int(.Colonists/PopDividor),136),PaintColor(1),bf

				DiamondBase = max(1024,1024+int(MaxColonists/PopDividor))
				for DiamSize as byte = 0 to 9
					DiamL = 118 + DiamSize
					DiamH = 136 - DiamSize
					if DiamondBase-DiamSize >= 1024 then
						line(DiamondBase-DiamSize,DiamL)-(DiamondBase-DiamSize,DiamH),PaintColor(1)
					end if
					line(DiamondBase+DiamSize,DiamL)-(DiamondBase+DiamSize,DiamH),PaintColor(1)
				next

				PopulationNum = .Colonists * 100
				gfxString(ClimateStr,768,100,3,2,2,rgb(255,255,255))
				gfxString(commaSep(PopulationNum)+" colonists",768,120,3,2,2,rgb(255,255,255))
				
				if .Natives > 0 then
					PaintColor(1) = rgb(128,80,80)
					line(1024,138)-(1024+int(.Natives/PopDividor),156),PaintColor(1),bf

					DiamondBase = max(1024,1024+int(MaxNatives/PopDividor))
					for DiamSize as byte = 0 to 9
						DiamL = 138 + DiamSize
						DiamH = 156 - DiamSize
						if DiamondBase-DiamSize >= 1024 then
							line(DiamondBase-DiamSize,DiamL)-(DiamondBase-DiamSize,DiamH),PaintColor(1)
						end if
						line(DiamondBase+DiamSize,DiamL)-(DiamondBase+DiamSize,DiamH),PaintColor(1)
					next

					PopulationNum = .Natives * 100
					NativeStr = commaSep(PopulationNum)+" "
					if (.NativeType >= 1 AND .NativeType <= 11) then
						NativeStr += NativeRaces(.NativeType)
					else
						NativeStr += "Chupanoid"
					end if
					NativeStr += "s ("+str(.NativeGov*20)+"%)"
					gfxString(NativeStr,768,140,3,2,2,rgb(255,255,255))
						
					'Reptilians double the base mining
					if .NativeType = 3 then
						RacialMining *= 2
					end if
				else
					gfxString("No native life",768,140,3,2,2,rgb(255,255,255))
				end if

				if ViewGame.Academy then
					for Mineral as byte = 1 to 3
						select case Mineral
							case 1 'Duranium
								PaintColor(1) = rgb(128,64,128)
								UsableMetals = .Dur
								MinableOre = .GDur
								OreDensity = .DDur
								MiningRate = int(.DDur * .MineralMines * RacialMining / (100^2) + 0.5)
								ResourceStr = "Du: "
	
							case 2 'Tritanium
								PaintColor(1) = rgb(64,32,128)
								UsableMetals = .Trit
								MinableOre = .GTrit
								OreDensity = .DTrit
								MiningRate = int(.DTrit * .MineralMines * RacialMining / (100^2) + 0.5)
								ResourceStr = "Tr: "
	
							case 3 'Molybdenum
								PaintColor(1) = rgb(128,128,0)
								UsableMetals = .Moly
								MinableOre = .GMoly
								OreDensity = .DMoly
								MiningRate = int(.DMoly * .MineralMines * RacialMining / (100^2) + 0.5)
								ResourceStr = "Mo: "
	
						end select
	
						if MinableOre > 0 then
							line(1024,158+Mineral*20)-(1024+int(MinableOre/50),176+Mineral*20),PaintColor(1),bf
						end if
	
						PaintColor(1) = rgb(255,255,255)
						if MiningRate > MinableOre then
							PaintColor(2) = rgb(255,255,0)
							MiningRate = MinableOre
						else
							PaintColor(2) = 0
						end if
						ResourceStr += str(MinableOre)+" ore ("+str(OreDensity)+"%) +"+str(MiningRate)
						gfxString(ResourceStr,768,160+Mineral*20,3,2,2,PaintColor(1),PaintColor(2))
					next Mineral
	
					gfxString("Mines: "+str(.MineralMines)+"/Factories: "+str(.Factories),768,240,3,2,2,rgb(255,255,255))
				else
					for Mineral as byte = 1 to 4
						select case Mineral
							case 1 'Neutronium
								PaintColor(1) = rgb(0,128,0)
								UsableMetals = .Neu
								MinableOre = .GNeu
								OreDensity = .DNeu
								MiningRate = int(.DNeu * .MineralMines * RacialMining / (100^2) + 0.5)
								ResourceStr = "Ne: "
	
							case 2 'Duranium
								PaintColor(1) = rgb(128,64,128)
								UsableMetals = .Dur
								MinableOre = .GDur
								OreDensity = .DDur
								MiningRate = int(.DDur * .MineralMines * RacialMining / (100^2) + 0.5)
								ResourceStr = "Du: "
	
							case 3 'Tritanium
								PaintColor(1) = rgb(64,32,128)
								UsableMetals = .Trit
								MinableOre = .GTrit
								OreDensity = .DTrit
								MiningRate = int(.DTrit * .MineralMines * RacialMining / (100^2) + 0.5)
								ResourceStr = "Tr: "
	
							case 4 'Molybdenum
								PaintColor(1) = rgb(128,128,0)
								UsableMetals = .Moly
								MinableOre = .GMoly
								OreDensity = .DMoly
								MiningRate = int(.DMoly * .MineralMines * RacialMining / (100^2) + 0.5)
								ResourceStr = "Mo: "
	
						end select
	
						if UsableMetals > 0 then
							line(1024,158+Mineral*20)-(1024+int(UsableMetals/50),176+Mineral*20),PaintColor(1),bf
						end if
	
						DiamondBase = max(1024,1024+int((UsableMetals+MinableOre)/50))
						for DiamSize as byte = 0 to 9
							DiamL = 158+Mineral*20 + DiamSize
							DiamH = 176+Mineral*20 - DiamSize
							if DiamondBase-DiamSize >= 1024 then
								line(DiamondBase-DiamSize,DiamL)-(DiamondBase-DiamSize,DiamH),PaintColor(1)
							end if
							line(DiamondBase+DiamSize,DiamL)-(DiamondBase+DiamSize,DiamH),PaintColor(1)
						next
	
						PaintColor(1) = rgb(255,255,255)
						if MiningRate > MinableOre then
							PaintColor(2) = rgb(255,255,0)
							MiningRate = MinableOre
						else
							PaintColor(2) = 0
						end if
						ResourceStr += str(UsableMetals)+"/"+str(MinableOre)+" ("+str(OreDensity)+"%) +"+str(MiningRate)
						gfxString(ResourceStr,768,160+Mineral*20,3,2,2,PaintColor(1),PaintColor(2))
					next Mineral
	
					gfxString("Cash: "+str(.Megacredits)+"/Supplies: "+str(.Supplies),768,260,3,2,2,rgb(255,255,255))
					gfxString("Mines: "+str(.MineralMines)+"/Factories: "+str(.Factories),768,280,3,2,2,rgb(255,255,255))
				end if
			end if
			
			ShipsCounted = 0
			for SID as short = 1 to LimitObjs
				with Starships(SID)
					if ViewGame.Academy then
						if .XLoc = ActualX AND .YLoc = ActualY AND .ShipType > 0 then
							with Coloring(.Ownership)
								PaintColor(1) = rgb(.Red,.Green,.Blue)
							end with
							
							ShipsCounted += 1
							gfxstring("<"+str(SID)+"> "+.ShipName,768,245+ShipsCounted*15,2,2,1,PaintColor(1))
						end if
					else
						if .ShipType > 0 AND .XLoc >= MinXPos AND .YLoc >= MinYPos AND _
							.XLoc < MaxXPos AND .YLoc < MaxYPos then
							dim as string Prefix
							
							ShipCX = (.XLoc-AbsMin)/MapSize*766
							ShipCY = 767-(.YLoc-AbsMin)/MapSize*766
	
							if Territory(ShipCX,ShipCY) = NearestPlan then
								with Coloring(.Ownership)
									PaintColor(1) = rgb(.Red,.Green,.Blue)
								end with
								
								ShipsCounted += 1
								if .XLoc = Planets(NearestPlan).X AND .YLoc = Planets(NearestPlan).Y then
									Prefix = "<"+str(SID)+"> "
								elseif sqr(abs(.XLoc - Planets(NearestPlan).X)^2 + abs(.YLoc - Planets(NearestPlan).Y)^2) <= 3 then
									Prefix = "["+str(SID)+"] "
								else
									Prefix = " "+str(SID)+". "
								end if
		
								gfxstring(Prefix+.ShipName,768,285+ShipsCounted*15,2,2,1,PaintColor(1))
								
								gfxstring("("+str(.XLoc)+","+str(.YLoc)+")",1024,285+ShipsCounted*15,2,2,1,PaintColor(1))
								'gfxstring(str(.Neu)+" Ne  "+str(.Dur)+" Du  "+str(.Trit)+" Tr  "+str(.Moly)+" Mo  "+str(.Supplies)+" sp  "+str(.Megacredits)+" mc",1150,285+ShipsCounted*15,2,2,1,PaintColor(1))
								
								/'
								if ShipsCounted > SkipShips AND ShipsCounted - SkipShips <= ShipsPerPage then
									with Coloring(.Ownership)
										color rgb(.Red,.Green,.Blue)
									end with
									locate 34-ShipsCounted+SkipShips,97
									if len(.ShipName) <= 27 then
										print .ShipName;
									else
										print left(.ShipName,24);
										color rgb(255,255,255)
										print "...";
									end if
									if .Cloaked then
										color rgb(128,128,128)
									else
										color rgb(255,255,255)
									end if
									locate 34-ShipsCounted+SkipShips,125
									print "#"& SID
								elseif ShipsCounted > SkipShips then
									MoreShips = 1
								end if
								'/
							end if
						end if
					end if
				end with
			next SID
		end with
	end if

	/'
	locate 2+ParticipatingPlayers,97
	color rgb(150,150,150)
	print string(30,"-")
	color rgb(255,255,255)
	'/

	with ViewGame
		if MouseError = 0 AND MouseX < 768 AND MouseY < 768 then
			ActualX = 2000-MapSize/2 + MouseX/768*MapSize
			ActualY = 2000+MapSize/2 - MouseY/768*MapSize
		else
			ActualX = -2
			ActualY = -2
		end if

		if .Academy then
			NearestPlan = -1
			ShipsFound = 0
			for PID as short = 1 to LimitObjs
				if Planets(PID).X = ActualX AND Planets(PID).Y = ActualY then
					NearestPlan = PID
					exit for
				end if
			next PID
			
			if ReplayerMode = MODE_CLIENT_NORMAL then
				for SID as short = 1 to LimitObjs
					if Starships(SID).ShipType > 0 AND Starships(SID).XLoc = ActualX AND Starships(SID).YLoc = ActualY then
						ShipsFound = 1
					end if
				next SID
			end if
		else
			ShipsFound = 0
			if MouseError = 0 AND MouseX < 768 AND MouseY < 768 then
				NearestPlan = Territory(MouseX,MouseY)
			else
				NearestPlan = -1
			end if
		end if
	end with
	
	screencopy
	sleep 15
	InType = inkey
	select case InType
		case PageUp
			'Goes back one turn, if possible
			if CanNavigate(0) then
				TurnNum -= 1
				loadTurnExtras
			end if
		case PageDown
			'Goes forward one turn
			if CanNavigate(1) then
				TurnNum += 1
				loadTurnExtras
			end if
		case FunctionOne
			'Switches to Normal Mode
			ReplayerMode = MODE_CLIENT_NORMAL
		case FunctionTwo
			'Switches to Island Mode
			ReplayerMode = MODE_CLIENT_ISLAND
		case CtrlR
			'Reloads the starmap
			updateStarmap
		case FunctionTwelve
			'Takes a snapshot of the client
			bsave("shot.bmp",0)
		case chr(255,107)
			'Ensures program is closed by hitting the X button
			ReplayerMode = MODE_EXIT
		case chr(27)
			'If in a game and holding SHIFT, then exit. Otherwise, return to main menu
			if multikey(SC_LSHIFT) then
				ReplayerMode = MODE_EXIT
			else
				if BaseScreen.Wideth > 1024 AND BaseScreen.Height > 768 AND SimpleView = 0 then
					prepCanvas(1024,768)
				end if
				
				ViewGame.PlayerCount = 0
				GameID = 0
				ReplayerMode = MODE_MENU
				InType = chr(255)
			end if
	end select
end sub

