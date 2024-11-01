const ClimateDeathRate = 10
const FtrSweepRate = 20

const PopDividor = 500
const ReportBG = rgb(0,0,24)
const BorderBG = rgb(16,0,48)

dim shared as uinteger PaintColor(2)
dim shared as AuxObj AuxList(MetaLimit), ResetAux
dim shared as short Sidebar, PlanetFound, BaseFound, AuxCount, AuxPage, StorePage, MoreStorage, HissBonus, ArtiBonus, NebDensity, StarRadiation, DiamondBase, DiamH, DiamL

ResetAux.Coloring = rgb(192,192,192)

sub getReport
	dim as ViewSpecs ActiveReport, SelectionCursor
	line (Sidebar,40)-(CanvasScreen.Wideth-1,CanvasScreen.Height-1),ReportBG,bf

	dim as string NativeRaces(1 to 11) => {"Humanoid", "Bovinoid", "Reptilian", _
		"Avian", "Amorphou", "Insectoid", "Amphibian", "Ghipsodal", "Siliconoid", _
		"", "Botanical"}
	
	dim as integer TrueItem
	dim as uinteger ReportColor
	
	select case SelectedObjType
		case REPORT_PLAN
			'Planet Report
			dim as string FullObjName, ClimateStr, HappyDelStr, TaxStr, NativeStr, ResourceStr
			dim as integer PopulationNum, TaxRevenue, MaxNatives, _
				RacialTaxes = 100, OptimalTemp = 50, NativeHappyBonus = 0, _
				StructCap, UsableMetals, MinableOre, OreDensity, MiningRate, RacialMining = 100
			dim as byte HorwaspPlanet
			dim as double MaxColonists, HappyDelta, NebVis
			ReportColor = rgb(96,255,96)
			
			with Planets(SelectedID)
				ActiveReport.X = .X
				ActiveReport.Y = .Y
				if .Asteroid > 0 then
					gfxString("Planetoid "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				else
					gfxString("Planet "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				end if
				
				NebVis = 4000 / (NebDensity + 1)
				
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
				
				if .Asteroid > 0 then
					MaxColonists = sgn(.BasePresent) * 500
				end if
				if .NativeType = 9 then
					MaxNatives = .Temp * 1000
				end if
				
				if .Natives > MaxNatives then
					'Ensure that the meter remains solid. Besides, excess natives do not die
					MaxNatives = .Natives
				end if
			
				if .Ownership = 0 AND .LastScan = 0 then	
					gfxString("Never scanned",Sidebar,80,3,2,2,rgb(128,128,128))	
					gfxString("(No colony present)",Sidebar,120,3,2,2,rgb(128,128,128))
				else
					if .Ownership = 0 then
						gfxString("No colony present",Sidebar,120,3,2,2,rgb(128,128,128))
						if .LastScan = TurnNum then
							gfxString("Current information",Sidebar,80,3,2,2,rgb(192,192,192))
						else
							gfxString("Last scanned turn "+str(.LastScan),Sidebar,80,3,2,2,rgb(192,192,192))
						end if
					else
						if .DNeu = 50 AND .DDur = 15 AND .DTrit = 20 AND .DMoly = 95 then
							FullObjName += " [homeworld]"
						end if
						HorwaspPlanet = abs(sgn(PlayerSlot(.Ownership).Race = "Horwasp"))
					end if
					if ViewGame.Academy = 0 AND HorwaspPlanet = 0 then
						ClimateStr += " (FC "+str(.FCode)+")"
					end if

					gfxString(FullObjName,Sidebar,60,3,2,2,ReportColor)
					gfxString(ClimateStr,Sidebar,100,3,2,2,ReportColor)
					
					'Artifact bonus inferred based on how it stacks with Reptilians
					RacialMining *= (ArtiBonus + 1)
					
					'Uses default mining/tax rate modifers
					if PlayerSlot(.OwnerShip).Race = "Lizard" then
						RacialMining *= 2
					elseif PlayerSlot(.OwnerShip).Race = "Fed" then
						RacialMining *= 0.7
						RacialTaxes = 200
					end if

					if .Ownership > 0 then
						PaintColor(1) = convertColor(Coloring(.Ownership))
						with PlayerSlot(.Ownership)
							gfxString(.Race + " (" + .PlayerName + ")",Sidebar,80,3,2,2,PaintColor(1))
						end with
						
						if PlayerSlot(.Ownership).Race = "Crystalline" then
							MaxColonists = 1000 * .Temp
							OptimalTemp = 100
						elseif PlayerSlot(.Ownership).Race = "Rebel" then
							if .Temp < 20 then
								MaxColonists = 90000
							elseif .Temp >= 80 AND MaxColonists < 60 then
								MaxColonists = 60
							end if
						elseif (PlayerSlot(.Ownership).Race = "Fascist" OR PlayerSlot(.Ownership).Race = "Fury" OR _
							PlayerSlot(.Ownership).Race = "Robotic" OR PlayerSlot(.Ownership).Race = "Colonial") AND _
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
		
						PopulationNum = .Colonists * 100
						gfxString(commaSep(PopulationNum)+" colonists",Sidebar,120,3,2,2,ReportColor)
						
						TaxRevenue = int(.Colonists * .ColTaxRate/1000 * RacialTaxes/100)
						HappyDelta = trunc((1000 - sqr(.Colonists) - 80*.ColTaxRate - abs(OptimalTemp - .Temp) * 3 - (.Factories + .MineralMines) / 3) / 100) + _
							min(HissBonus,100 - .ColHappy) + (ArtiBonus*5)
						
						if HorwaspPlanet then
							gfxString("Liquify: "+str(.ColTaxRate)+"%",Sidebar,140,3,2,2,ReportColor)
							gfxString("Terraform: "+str(.WorkTerraform)+"%",Sidebar,160,3,2,2,ReportColor)
						else
							if HappyDelta > 0 then
								HappyDelStr = "+"+str(HappyDelta)
								PaintColor(1) = ReportColor
							elseif HappyDelta = 0 then
								HappyDelStr = "+0"
								PaintColor(1) = rgb(255,255,0)
							else
								HappyDelStr = str(HappyDelta)
								PaintColor(1) = rgb(255,64,64)
							end if
							gfxString("Taxes: "+str(.ColTaxRate)+"%  +"+str(TaxRevenue)+" mc",Sidebar,140,3,2,2,PaintColor(1))
							
							if .ColHappy >= 70 then
								PaintColor(1) = ReportColor
							elseif .ColHappy >= 40 then
								PaintColor(1) = rgb(255,255,0)
							elseif .ColHappy >= 0 then
								PaintColor(1) = rgb(255,128,0)
							else
								PaintColor(1) = rgb(255,64,64)
							end if
							gfxString("Happy: "+str(.ColHappy)+"%  "+HappyDelStr,Sidebar,160,3,2,2,PaintColor(1))
						end if
					
						PaintColor(1) = rgb(96,128,128)
						line(Sidebar,178)-(Sidebar+int(.Colonists/PopDividor),196),PaintColor(1),bf
		
						DiamondBase = max(Sidebar,Sidebar+int(MaxColonists/PopDividor))
						for DiamSize as byte = 0 to 9
							DiamL = 178 + DiamSize
							DiamH = 196 - DiamSize
							if DiamondBase-DiamSize >= Sidebar then
								line(DiamondBase-DiamSize,DiamL)-(DiamondBase-DiamSize,DiamH),PaintColor(1)
							end if
							line(DiamondBase+DiamSize,DiamL)-(DiamondBase+DiamSize,DiamH),PaintColor(1)
						next
					end if

					if .Natives > 0 then
						PopulationNum = .Natives * 100
						NativeStr = commaSep(PopulationNum)+" "
						if (.NativeType >= 1 AND .NativeType <= 11) then
							NativeStr += NativeRaces(.NativeType)
						else
							NativeStr += "Chupanoid"
						end if
						NativeStr += "s ("+str(.NativeGov*20)+"%)"
						gfxString(NativeStr,Sidebar,200,3,2,2,ReportColor)
						
						if (.Ownership > 0 OR .LastScan = TurnNum) AND HorwaspPlanet = 0 then
							if NativeRaces(.NativeType) = "Amorphou" then
								'Amorphous do not pay taxes
								RacialTaxes = 0
							elseif NativeRaces(.NativeType) = "Insectoid" then
								'Insectoids pay double
								RacialTaxes *= 2
							elseif NativeRaces(.NativeType) = "Avian" then
								'Avians have a faster happy gain
								NativeHappyBonus = 10
							end if
							
							'Additional native happy bonus for reduced visibility
							if NebVis < 50.5 then
								NativeHappyBonus += 5
							end if
							
							'Colonists need to be present to collect taxes from natives
							TaxRevenue = int(.Natives * .NatTaxRate/1000 * RacialTaxes/100 * .NativeGov/5)
							HappyDelta = trunc((1000 - sqr(.Natives) - 85*.NatTaxRate - (.Factories + .MineralMines) / 2 - 50 * (10 - .NativeGov)) / 100) + _
								NativeHappyBonus + min(HissBonus,100 - .NatHappy) + (ArtiBonus*5)
							
							if HappyDelta > 0 then
								HappyDelStr = "+"+str(HappyDelta)
								PaintColor(1) = ReportColor
							elseif HappyDelta = 0 then
								HappyDelStr = "+0"
								PaintColor(1) = rgb(255,255,0)
							else
								HappyDelStr = str(HappyDelta)
								PaintColor(1) = rgb(255,64,64)
							end if
							TaxStr = str(TaxRevenue)
							if TaxRevenue > .Colonists*RacialTaxes/100 then
								dim as integer EffTax = int(.Colonists*RacialTaxes/100)
								TaxStr = str(EffTax)+"/"+TaxStr
							end if
							gfxString("Taxes: "+str(.NatTaxRate)+"%  +"+TaxStr+" mc",Sidebar,220,3,2,2,PaintColor(1))
							
							if .NatHappy >= 70 then
								PaintColor(1) = ReportColor
							elseif .NatHappy >= 40 then
								PaintColor(1) = rgb(255,255,0)
							elseif .NatHappy >= 0 then
								PaintColor(1) = rgb(255,128,0)
							else
								PaintColor(1) = rgb(255,64,64)
							end if
							gfxString("Happy: "+str(.NatHappy)+"%  "+HappyDelStr,Sidebar,240,3,2,2,PaintColor(1))
						elseif HorwaspPlanet then
							gfxString("Harvest: "+str(.WorkHarvest)+"%",Sidebar,220,3,2,2,ReportColor)
						end if

						PaintColor(1) = rgb(128,80,80)
						line(Sidebar,258)-(Sidebar+int(.Natives/PopDividor),276),PaintColor(1),bf

						DiamondBase = max(Sidebar,Sidebar+int(MaxNatives/PopDividor))
						for DiamSize as byte = 0 to 9
							DiamL = 258 + DiamSize
							DiamH = 276 - DiamSize
							if DiamondBase-DiamSize >= Sidebar then
								line(DiamondBase-DiamSize,DiamL)-(DiamondBase-DiamSize,DiamH),PaintColor(1)
							end if
							line(DiamondBase+DiamSize,DiamL)-(DiamondBase+DiamSize,DiamH),PaintColor(1)
						next
					else
						gfxString("No native life",Sidebar,200,3,2,2,ReportColor)
					end if

					if ViewGame.Academy = 0 then
						PaintColor(1) = rgb(128,128,128)
						if .Megacredits = -1 then
							ResourceStr = "Megacredits: ?"
						else
							ResourceStr = "Megacredits: "+commaSep(.Megacredits)
							if HorwaspPlanet = 0 then
								PaintColor(1) = ReportColor
							end if
						end if
						gfxString(ResourceStr,Sidebar,280,3,2,2,PaintColor(1))
						if .Supplies = -1 then
							ResourceStr = "Supplies: ?"
							PaintColor(1) = rgb(128,128,128)
						else
							ResourceStr = "Supplies: "+commaSep(.Supplies)
							PaintColor(1) = ReportColor
						end if
						gfxString(ResourceStr,Sidebar,300,3,2,2,PaintColor(1))
					end if
					
					PaintColor(1) = rgb(128,128,128)
					if .Factories = -1 then
						ResourceStr = "Factories: ?"
					elseif .Ownership > 0 AND HorwaspPlanet = 0 then
						if .Colonists <= 100 then
							StructCap = .Colonists
						else
							StructCap = 100+int(sqr(.Colonists-100))
						end if
						
						ResourceStr = "Factories: "+str(.Factories)+"/"+str(StructCap)
						PaintColor(1) = ReportColor
					elseif HorwaspPlanet then
						ResourceStr = "Factories: "+str(.Factories)+" / Mines: "+str(.MineralMines)
					else
						ResourceStr = "Factories: "+str(.Factories)
					end if
					gfxString(ResourceStr,Sidebar,320,3,2,2,PaintColor(1))
					
					if .MineralMines = -1 then
						ResourceStr = "Mines: ?"
					elseif .Ownership > 0 AND HorwaspPlanet = 0 then
						if .Colonists <= 100 then
							StructCap = .Colonists
						else
							StructCap = 200+int(sqr(.Colonists-200))
						end if
						
						ResourceStr = "Mines: "+str(.MineralMines)+"/"+str(StructCap)
						PaintColor(1) = ReportColor
					elseif HorwaspPlanet then
						ResourceStr = "Mining: "+str(.WorkMine)+"%"
						PaintColor(1) = ReportColor
					else
						ResourceStr = "Mines: "+str(.MineralMines)
					end if
					gfxString(ResourceStr,Sidebar,340,3,2,2,PaintColor(1))

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
						
						if ViewGame.Academy then	
							if MinableOre > 0 AND Mineral > 1 then
								line(Sidebar,338+Mineral*40)-(Sidebar+int(MinableOre/50),356+Mineral*40),PaintColor(1),bf
							end if
						else
							if UsableMetals > 0 then
								line(Sidebar,338+Mineral*40)-(Sidebar+int(UsableMetals/50),356+Mineral*40),PaintColor(1),bf
							end if
	
							DiamondBase = max(Sidebar,Sidebar+int((UsableMetals+MinableOre)/50))
							for DiamSize as byte = 0 to 9
								DiamL = 338+Mineral*40 + DiamSize
								DiamH = 356+Mineral*40 - DiamSize
								if DiamondBase-DiamSize >= Sidebar then
									line(DiamondBase-DiamSize,DiamL)-(DiamondBase-DiamSize,DiamH),PaintColor(1)
								end if
								line(DiamondBase+DiamSize,DiamL)-(DiamondBase+DiamSize,DiamH),PaintColor(1)
							next
						end if
						
						PaintColor(1) = ReportColor
						if MiningRate > MinableOre then
							PaintColor(2) = rgb(255,255,128)
							MiningRate = MinableOre
						else
							PaintColor(2) = 0
						end if
						
						if ViewGame.Academy then	
							if Mineral > 1 then
								if MinableOre >= 0 then
									ResourceStr += str(MinableOre)+" ore ("+str(OreDensity)+"%) +"+str(MiningRate)
								else
									ResourceStr += "? ore (?%)"
								end if
							end if
						else
							if MinableOre >= 0 then
								ResourceStr += str(UsableMetals)+"/"+str(MinableOre)+" ("+str(OreDensity)+"%) +"+str(MiningRate)
							else
								ResourceStr += "?/? (?%)"
							end if
						end if
						
						gfxString(ResourceStr,Sidebar,320+Mineral*40,3,2,2,PaintColor(1),PaintColor(2))
					next Mineral
					
					if .Colonists <= 50 then
						StructCap = .Colonists
					else
						StructCap = 50 + int(sqr(.Colonists - 50))
					end if
					
					PaintColor(1) = ReportColor
					if .DefPosts = -1 then
						ResourceStr = "Defense: ?"
						PaintColor(1) = rgb(128,128,128)
					elseif .Ownership > 0 AND HorwaspPlanet = 0 then
						ResourceStr = "Defense: "+str(.DefPosts)+"/"+str(StructCap)
						if .DefPosts < 15 AND (.MineralMines >= 20 OR .Factories >= 15) then
							PaintColor(1) = rgb(255,255,0)
						end if
					elseif HorwaspPlanet then
						ResourceStr = "Burrows: "+commaSep(.BurrowSize)+"  +"+str(.WorkBurrow)+"%"
					else
						ResourceStr = "Defense: "+str(.DefPosts)
						PaintColor(1) = rgb(128,128,128)
					end if
					gfxString(ResourceStr,Sidebar,520,3,2,2,PaintColor(1))
					if StarRadiation > 0 then
						gfxString("Radiation: "+str(StarRadiation)+" MJ",Sidebar,540,3,2,2,ReportColor)
					end if
					if NebDensity > 0 then
						gfxString("Visibility: "+commaSep(int(NebVis+0.5))+" LY",Sidebar,560,3,2,2,ReportColor)
					end if
				end if
			end with
		case REPORT_SHIP
			'Ship report
			with Starships(SelectedID)
				dim as double Distance, DistLeft
				dim as integer FuelNeeded, TimeNeeded, CargoTaken, BaseMass, CalcMass
				dim as byte HorwaspShip, CloakCost, AdvancedCloak, Gravitonic
				
				dim as string HullClassName
				dim as string MisnNames(25) => {"Exploration", "Mine Sweep", "Lay Mines", "Kill!", "Sensor Sweep", _
					"Land + Disassemble", "Tow Ship {1}", "Intercept Ship {2}", "{Racial}", "Cloak", _
					"Beam up Fuel", "Beam up Duranium", "Beam up Tritanium", "Beam up Molybdenum", "Beam up Supplies", _
					"", "", "", "", "", "", "", "", "", "Load Artifact {2}", "Transfer Artifact {2} to Ship {1}"}
				dim as string DispMisn, RacialMisn
				ReportColor = rgb(128,224,192)
				
				ActiveReport.X = .XLoc
				ActiveReport.Y = .YLoc
				gfxString("Ship "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				HullClassName = ShiplistObj(.ShipType).HullName
				gfxString(HullClassName,Sidebar,60,3,2,2,ReportColor)
				Gravitonic = abs(sgn(HullClassName = "Br4 Gunship" OR HullClassName = "Br5 Kaye Boat" OR _
					HullClassName = "Meteor Blockade Runner"))
				AdvancedCloak = abs(sgn(HullClassName = "Resolute Battlecruiser" OR HullClassName = "Darkwing Battleship" OR _
					HullClassName = "Deth Specula Heavy Frigate" OR HullClassName = "Red Wind Storm-Carrier"))
				
				PaintColor(1) = convertColor(Coloring(.Ownership))
				with PlayerSlot(.Ownership)
					gfxString(.Race + " (" + .PlayerName + ")",Sidebar,80,3,2,2,PaintColor(1))
					
					select case .Race
						case "Fed"
							RacialMisn = "Super Refit"
						case "Lizard"
							RacialMisn = "HissSSssSS!"
						case "Bird Man"
							RacialMisn = "Super Spy"
						case "Fascist", "Fury"
							RacialMisn = "Pillage Planet"
						case "Privateer"
							RacialMisn = "Rob Ships"
						case "Cyborg"
							RacialMisn = "Repair Self"
						case "Crystalline"
							RacialMisn = "Lay Web Mines"
						case "Empire"
							RacialMisn = "Dark Sense"
						case "Rebel"
							RacialMisn = "Rebel Ground Attack"
						case "Horwasp"
							HorwaspShip = 1
						case else
							RacialMisn = "Build Fighters"
					end select
				end with
				
				if HorwaspShip then
					.BeamPos = 1 + int(.Colonists/ShiplistObj(.ShipType).Cargo*9)
					.TubePos = .BeamPos
				end if
				
				gfxString(.ShipName,Sidebar,100,3,2,2,ReportColor)
				if ShiplistObj(.ShipType).Engines > 0 then 
					gfxString(str(ShiplistObj(.ShipType).Engines)+"x "+Engines(.EnginePos).PartName,Sidebar,120,3,2,2,ReportColor)
				else
					gfxString("No engines",Sidebar,120,3,2,2,rgb(128,128,128))
				end if
				if .BeamNum > 0 then 
					gfxString(str(.BeamNum)+"x "+Beams(.BeamPos).PartName,Sidebar,140,3,2,2,ReportColor)
				else
					gfxString("No beam banks",Sidebar,140,3,2,2,rgb(128,128,128))
				end if
				if .TubeNum > 0 then 
					gfxString(str(.TubeNum)+"x "+Tubes(.TubePos).PartName,Sidebar,160,3,2,2,ReportColor)
				else
					gfxString("No torpedo tubes",Sidebar,160,3,2,2,rgb(128,128,128))
				end if
				if ShiplistObj(.ShipType).FtrBays > 0 then 
					gfxString(str(ShiplistObj(.ShipType).FtrBays)+"x Fighter Bay",Sidebar,180,3,2,2,ReportColor)
				else
					gfxString("No fighter bays",Sidebar,180,3,2,2,rgb(128,128,128))
				end if
				
				if .Mission > ubound(MisnNames) OR MisnNames(.Mission) = "" then
					DispMisn = "("+str(.Mission)+")"
				else
					DispMisn = MisnNames(.Mission)
					if .Mission = 25 AND .MisnTarget(1) = 0 then
						DispMisn = "Unload Artifact {2}"
					end if
					
					DispMisn = findReplace(DispMisn,"{1}",str(.MisnTarget(1)))
					DispMisn = findReplace(DispMisn,"{2}",str(.MisnTarget(2)))
					DispMisn = findReplace(DispMisn,"{Racial}",RacialMisn)
				end if
				gfxString("Mission: "+DispMisn,Sidebar,220,3,2,2,ReportColor)
				
				if AdvancedCloak = 0 AND (.Mission = 9 OR (.Mission = 10 AND RacialMisn = "Super Spy")) then
					CloakCost = max(int(.HullMass/20),5)
				end if
				
				CargoTaken = .Dur + .Trit + .Moly + .Colonists + .Supplies + .Ammo
				BaseMass = .HullMass + .Neu + CargoTaken + .BeamNum * Beams(.BeamPos).Mass + .TubeNum * Tubes(.TubePos).Mass
				if .Mission = 6 then
					with Starships(.MisnTarget(1))
						BaseMass += .HullMass + .Neu + .Dur + .Trit + .Moly + .Supplies + .Colonists + .Ammo + _
							.BeamNum * Beams(.BeamPos).Mass + .TubeNum * Tubes(.TubePos).Mass
							
						if .Mission = 9 then
							CloakCost = max(.HullMass/20,5)
						end if
					end with
				end if
				
				if HorwaspShip then
					gfxString("Mass: "+commaSep(BaseMass)+" kT",Sidebar,260,3,2,2,ReportColor)
				else
					if .PrimEnemy > 0 then
						gfxString("Enemy: "+PlayerSlot(.PrimEnemy).PlayerName,Sidebar,240,3,2,2,ReportColor)
					else
						gfxString("Enemy: None",Sidebar,240,3,2,2,ReportColor)
					end if
					gfxString("FCode: "+.FCode+" / Mass: "+commaSep(BaseMass)+" kT",Sidebar,260,3,2,2,ReportColor)
				end if

				if .WarpSpeed > .EnginePos then
					PaintColor(1) = rgb(255,255,0)
				elseif .WarpSpeed > int((100 - .HullDmg)/10) then
					PaintColor(1) = rgb(255,64,64)
				else
					PaintColor(1) = ReportColor
				end if
				gfxString("Warp: "+str(.WarpSpeed),Sidebar,280,3,2,2,PaintColor(1))
				if .TargetX = .XLoc OR .TargetY = .YLoc then
					gfxString("Dest: None",Sidebar,300,3,2,2,ReportColor)
				else
					Distance = int(sqr((.TargetX - .XLoc)^2 + (.TargetY - .YLoc)^2)*1000)/1000+1e-6
					
					gfxString("Dest: ("+str(.TargetX)+","+str(.TargetY)+")",Sidebar,300,3,2,2,ReportColor)
					
					if .WarpSpeed > 0 then
						TimeNeeded = ceil(Distance/(.WarpSpeed^2 + 0.549))
						gfxString("Dist: "+left(str(Distance),len(str(int(Distance)))+4)+" LY / ETA: "+str(TimeNeeded),Sidebar,320,3,2,2,ReportColor)
					end if
				end if

				if HorwaspShip = 0 then
					if .Crew < ShiplistObj(.ShipType).Crew then
						PaintColor(1) = rgb(255,255,0)
					else
						PaintColor(1) = rgb(128,224,192)
					end if
					gfxString("Crew  : "+commaSep(.Crew)+"/"+commaSep(ShiplistObj(.ShipType).Crew),Sidebar,340,3,2,2,PaintColor(1))
				end if
				
				if .HullDmg >= 10 then
					PaintColor(1) = rgb(255,64,64)
				elseif .HullDmg > 0 then
					PaintColor(1) = rgb(255,255,0)
				else
					PaintColor(1) = rgb(128,224,192)
				end if
				gfxString("Damage: "+commaSep(.HullDmg)+"% / XP: "+commaSep(.Experience),Sidebar,360,3,2,2,PaintColor(1))
				
				if ShiplistObj(.ShipType).Neu > 0 then
					FuelNeeded = 0
					
					DistLeft = Distance
					if TimeNeeded > 0 then
						'Attempt to compute cost over multiple turns
						for PunchTurn as short = TimeNeeded to 1 step -1
							CalcMass = BaseMass - CloakCost - FuelNeeded
							FuelNeeded += CloakCost + int(Engines(.EnginePos).EngineEfficiency(.WarpSpeed) * int(CalcMass/10) * int(min(.WarpSpeed^2,DistLeft)) / (.WarpSpeed^2*(1+Gravitonic)) / 10000)
							
							DistLeft -= .WarpSpeed^2
						next PunchTurn
					else
						'Simply assess a cloak cost for stationary targets
						FuelNeeded = CloakCost
					end if
				end if
				
				if .Neu = 0 OR FuelNeeded > .Neu then
					PaintColor(1) = rgb(255,64,64)
				elseif .Neu < 25 OR FuelNeeded >= .Neu - 1 then
					PaintColor(1) = rgb(255,255,0)
				else
					PaintColor(1) = ReportColor
				end if
				gfxString("Fuel  : "+commaSep(.Neu)+"/"+commaSep(ShiplistObj(.ShipType).Neu)+" kT",Sidebar,380,3,2,2,PaintColor(1))
				if FuelNeeded > 0 then
					gfxString("Burn  : "+commaSep(FuelNeeded)+" kT",Sidebar,400,3,2,2,PaintColor(1))
				end if
				
				gfxString("Cargo      : "+commaSep(CargoTaken)+"/"+commaSep(ShiplistObj(.ShipType).Cargo)+" kT",Sidebar,420,3,2,2,ReportColor)
				if HorwaspShip = 0 then
					gfxString("Duranium   : "+commaSep(.Dur)+" kT",Sidebar,440,3,2,2,ReportColor)
					gfxString("Tritanium  : "+commaSep(.Trit)+" kT",Sidebar,460,3,2,2,ReportColor)
					gfxString("Molybdenum : "+commaSep(.Moly)+" kT",Sidebar,480,3,2,2,ReportColor)
					gfxString("Supplies   : "+commaSep(.Supplies)+" kT",Sidebar,500,3,2,2,rgb(128,224,192))
					gfxString("Ammo       : "+commaSep(.Ammo)+" kT",Sidebar,520,3,2,2,rgb(128,224,192))
					gfxString("Colonists  : "+commaSep(.Colonists)+" clans",Sidebar,540,3,2,2,rgb(128,224,192))
					gfxString("Megacredits: "+commaSep(.Megacredits),Sidebar,560,3,2,2,rgb(128,224,192))
				end if
			end with
			
		case REPORT_BASE
			'Starbase report
			with Planets(SelectedID)
				dim as string PrimaryOrder(6) => {"None", "Refuel", "Maximize Defense", _
					"Load Torps", "Unload Freighters", "Repair Base", "Force Surrenders"}
				dim as string SecondaryOrder(2) => {"None", "Fix Ship {1}", "Recycle Ship {1}"}
				
				dim as string DispOrders(2)
				ReportColor = rgb(160,160,255)
				
				ActiveReport.X = .X
				ActiveReport.Y = .Y
				if .Asteroid > 0 then
					gfxString("Mining Station "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				else
					gfxString("Starbase "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				end if
				gfxString(.ObjName,Sidebar,60,3,2,2,ReportColor)
				
				PaintColor(1) = convertColor(Coloring(.Ownership))
				with PlayerSlot(.Ownership)
					gfxString(.Race + " (" + .PlayerName + ")",Sidebar,80,3,2,2,PaintColor(1))
				end with
				
				gfxString("Defense : "+str(.OrbDefense),Sidebar,100,3,2,2,ReportColor)
				gfxString("Fighters: "+str(.Fighters),Sidebar,120,3,2,2,ReportColor)
				if .Damage = 0 then
					PaintColor(1) = ReportColor
				elseif .Damage <= 5 then
					PaintColor(1) = rgb(255,255,0)
				elseif .Damage < 50 then
					PaintColor(1) = rgb(255,128,0)
				else
					PaintColor(1) = rgb(255,64,64)
				end if
				gfxString("Damage  : "+str(.Damage)+"%",Sidebar,140,3,2,2,PaintColor(1))
				
				if .BaseOrders(1) > ubound(PrimaryOrder) OR PrimaryOrder(.BaseOrders(1)) = "" then
					DispOrders(1) = "("+str(.BaseOrders(1))+")"
				else
					DispOrders(1) = findReplace(PrimaryOrder(.BaseOrders(1)), "{1}", str(.BaseTarget(1)))
				end if
				if .BaseOrders(2) > ubound(SecondaryOrder) OR SecondaryOrder(.BaseOrders(2)) = "" then
					DispOrders(2) = "("+str(.BaseOrders(2))+")"
				else
					DispOrders(2) = findReplace(SecondaryOrder(.BaseOrders(2)), "{1}", str(.BaseTarget(2)))
				end if
				
				
				gfxString("Primary  : "+DispOrders(1),Sidebar,180,3,2,2,ReportColor)
				gfxString("Secondary: "+DispOrders(2),Sidebar,200,3,2,2,ReportColor)
				
				if .Asteroid = 0 then
					gfxString("Hull   Tech: "+str(.TechH),Sidebar,240,3,2,2,ReportColor)
					gfxString("Engine Tech: "+str(.TechE),Sidebar,260,3,2,2,ReportColor)
				end if
				gfxString("Beam   Tech: "+str(.TechB),Sidebar,280,3,2,2,ReportColor)
				gfxString("Torp   Tech: "+str(.TechT),Sidebar,300,3,2,2,ReportColor)
				
				dim as integer StoragePerPage = int((CanvasScreen.Height - 550)/15), StorageItems = -StorePage * StoragePerPage
				
				line(Sidebar,318)-(CanvasScreen.Wideth-1,338),BorderBG,bf
				gfxString("Base Storage",Sidebar,320,3,2,2,rgb(255,255,255))
				with BaseStorage(.BasePresent)
					'Hulls
					for HID as byte = 1 to 100
						if .HullCount(HID) > 0 then
							for STID as short = 1 to 5000	
								if .HullReference(HID) = STID then	
									if Planets(SelectedID).UseH = STID then
										PaintColor(1) = rgb(255,255,0) 
									else
										PaintColor(1) = ReportColor
									end if
									
									StorageItems += 1
									if StorageItems > 0 AND StorageItems <= StoragePerPage then
										gfxString(ShiplistObj(STID).HullName+" x"+str(.HullCount(HID)),Sidebar,325+StorageItems*15,2,2,1,PaintColor(1))
									end if
									exit for
								end if
							next STID
						end if	
					next HID
					
					for Phase as byte = 1 to 3
						for CID as ushort = 1 to 310
							select case Phase
								case 1 'Engines
									if CID < 10 AND len(Engines(CID).PartName) > 0 then
										if .EngineCount(CID) > 0 then
											if Planets(SelectedID).UseE = CID then
												PaintColor(1) = rgb(255,255,0) 
											else
												PaintColor(1) = ReportColor
											end if
											
											StorageItems += 1
											if StorageItems > 0 AND StorageItems <= StoragePerPage then
												gfxString(Engines(CID).PartName+" x"+str(.EngineCount(CID)),Sidebar,325+StorageItems*15,2,2,1,PaintColor(1))
											end if
										end if
									end if
								case 2 'Beams
									if CID <= 10 AND len(Beams(CID).PartName) > 0 then
										if .BeamCount(CID) > 0 then
											if Planets(SelectedID).UseB = CID then
												PaintColor(1) = rgb(255,255,0) 
											else
												PaintColor(1) = ReportColor
											end if
											
											StorageItems += 1
											if StorageItems > 0 AND StorageItems <= StoragePerPage then
												gfxString(Beams(CID).PartName+" x"+str(.BeamCount(CID)),Sidebar,325+StorageItems*15,2,2,1,PaintColor(1))
											end if
										end if
									end if
								case 3 'Torps and ammo
									if .TubeCount(CID) > 0 AND len(Tubes(CID).PartName) > 0 then
										if Planets(SelectedID).UseT = CID then
											PaintColor(1) = rgb(255,255,0) 
										else
											PaintColor(1) = ReportColor
										end if
											
										StorageItems += 1
										if StorageItems > 0 AND StorageItems <= StoragePerPage then
											gfxString(Tubes(CID).PartName+" x"+str(.TubeCount(CID)),Sidebar,325+StorageItems*15,2,2,1,PaintColor(1))
										end if
									end if
									if .TorpCount(CID) > 0 AND len(TorpAmmo(CID).PartName) > 0 then
										StorageItems += 1
										if StorageItems > 0 AND StorageItems <= StoragePerPage then
											gfxString(TorpAmmo(CID).PartName+" ammo x"+str(.TorpCount(CID)),Sidebar,325+StorageItems*15,2,2,1,ReportColor)
										end if
									end if
							end select
						next
					next Phase
				end with
				
				line(Sidebar,CanvasScreen.Height-210)-(CanvasScreen.Wideth-1,CanvasScreen.Height-171),BorderBG,bf
				if StorePage > 0 then
					gfxstring("Home",Sidebar+20,CanvasScreen.Height-208,3,2,2,rgb(255,255,255))
				end if
				if StorageItems > StoragePerPage then
					gfxstring("End",Sidebar+180,CanvasScreen.Height-208,3,2,2,rgb(255,255,255))
					MoreStorage = 1
				else
					MoreStorage = 0
				end if
			end with
			
		case REPORT_MINE
			dim as byte SweepRate
			dim as integer BmsNeeded
			
			'Minefield report
			with Minefields(SelectedID)
				ActiveReport.X = .X
				ActiveReport.Y = .Y
				gfxString("Minefield "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				PaintColor(1) = convertColor(Coloring(.Ownership))
				with PlayerSlot(.Ownership)
					gfxString(.Race + " (" + .PlayerName + ")",Sidebar,60,3,2,2,PaintColor(1))
				end with
				
				if .Webbed then
					gfxString("Quantity: "+commaSep(.MineUnits)+" web units",Sidebar,100,3,2,2,rgb(255,128,255))
					SweepRate = 3
				else
					gfxString("Quantity: "+commaSep(.MineUnits)+" units",Sidebar,100,3,2,2,rgb(255,255,255))
					SweepRate = 4
				end if
				gfxString("Radius: "+str(.Radius)+" LY",Sidebar,120,3,2,2,rgb(255,255,255))
				gfxString("FCode: "+str(.FCode),Sidebar,140,3,2,2,rgb(255,255,255))
				
				gfxString("To sweep:",Sidebar,180,3,2,2,rgb(255,255,255))
				for BMID as byte = 1 to 10
					BmsNeeded = ceil(.MineUnits/SweepRate/BMID^2)
					
					gfxString(space(1)+commaSep(BmsNeeded)+" "+Beams(BMID).PartName,Sidebar,180+BMID*20,3,2,2,rgb(255,255,255))
				next BMID
				
				if .Webbed = 0 then
					BmsNeeded = ceil(.MineUnits/FtrSweepRate)
					gfxString(space(1)+commaSep(BmsNeeded)+" fighters",Sidebar,400,3,2,2,rgb(255,255,255))
				end if
			end with
			
		case REPORT_ION
			dim as byte IonClass
			dim as string IonGrade, IonStrength
			dim as uinteger IonColor
			
			'Ion Storm report
			with IonStorms(SelectedID)
				ActiveReport.X = .X
				ActiveReport.Y = .Y
				gfxString("Ion Storm "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				gfxString("Radius: "+str(.Radius)+" LY",Sidebar,80,3,2,2,rgb(255,255,0))
				gfxString("Heading: "+str(.Heading)+" deg",Sidebar,100,3,2,2,rgb(255,255,0))
				gfxString("Warp Factor: "+str(.Warp),Sidebar,120,3,2,2,rgb(255,255,0))
				
				IonClass = ceil(.Voltage/50)
				select case IonClass
					case 1
						IonGrade = "Harmless"
						IonColor = rgb(0,255,0)
					case 2
						IonGrade = "Moderate"
						IonColor = rgb(128,255,0)
					case 3
						IonGrade = "Strong"
						IonColor = rgb(255,255,0)
					case 4
						IonGrade = "Dangerous"
						IonColor = rgb(255,128,0)
					case else
						IonGrade = "Very Dangerous"
						IonColor = rgb(255,64,64)
				end select
				if .Voltage mod 2 = 0 then
					IonStrength = "weakening"
				else
					IonStrength = "growing"
				end if
				gfxString(IonGrade+" and "+IonStrength,Sidebar,160,3,2,2,IonColor)
				gfxString("("+str(.Voltage)+" V)",Sidebar,180,3,2,2,IonColor)
			end with
			
		case REPORT_STAR
			dim as short Radiation
			
			'Star Cluster report
			with StarClusters(SelectedID)
				Radiation = ceil(sqr(.Mass))
				
				ActiveReport.X = .X
				ActiveReport.Y = .Y
				gfxString("Star Cluster "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				gfxString(.Namee,Sidebar,60,3,2,2,rgb(255,255,255))
				gfxString("Core Radius: "+str(.Radius)+" LY",Sidebar,80,3,2,2,rgb(255,255,255))
				gfxString("Radiation Radius: "+str(Radiation)+" LY",Sidebar,100,3,2,2,rgb(255,255,255))
				gfxString("Mass: "+commaSep(.Mass)+" kT",Sidebar,120,3,2,2,rgb(255,255,255))
				gfxString("Temperature: "+commaSep(.Temperature)+" W",Sidebar,140,3,2,2,rgb(255,255,255))
			end with
			
		case REPORT_NEB
			'Nebula report
			with Nebulae(SelectedID)
				ActiveReport.X = .X
				ActiveReport.Y = .Y
				gfxString("Nebula "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				gfxString(.Namee,Sidebar,60,3,2,2,rgb(255,255,255))
				gfxString("Radius: "+str(.Radius)+" LY",Sidebar,80,3,2,2,rgb(255,255,255))
				gfxString("Intensity: "+str(.Intensity),Sidebar,100,3,2,2,rgb(255,255,255))
			end with
			
		case REPORT_WORM
			'Wormhole report
			with Wormholes(SelectedID)
				ReportColor = rgb(128,255,240)
				
				ActiveReport.X = .X
				ActiveReport.Y = .Y
				gfxString("Wormhole "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				gfxString(.Namee,Sidebar,60,3,2,2,ReportColor)
				if .LastScan = TurnNum then
					gfxString("Current information",Sidebar,80,3,2,2,rgb(192,192,192))
				else
					gfxString("Last scanned turn "+str(.LastScan),Sidebar,80,3,2,2,rgb(192,192,192))
				end if

				if .DestX > 0 AND .DestY > 0 then
					gfxString("Dest: ("+str(.DestX)+","+str(.DestY)+")",Sidebar,100,3,2,2,ReportColor)
				end if
				gfxString("Stability: "+str(.Stability)+"%",Sidebar,120,3,2,2,ReportColor)
			end with
			
		case REPORT_ARTI
			'Artifact report
			with Artifacts(SelectedID)
				ReportColor = rgb(224,192,160)
				
				ActiveReport.X = .X
				ActiveReport.Y = .Y
				gfxString("Artifact "+str(SelectedID)+" Report",Sidebar,40,3,2,2,rgb(192,192,192))
				gfxString(.Namee,Sidebar,60,3,2,2,ReportColor)
				
				select case .LocationType
					case 1
						gfxString("Bound to local planet "+str(.LocationID),Sidebar,100,3,2,2,ReportColor)
						gfxString(Planets(.LocationID).ObjName,Sidebar,120,3,2,2,ReportColor)
						
						gfxString("+100% mining efficiency",Sidebar,160,3,2,2,ReportColor)
						gfxString("Improved ground defense",Sidebar,180,3,2,2,ReportColor)
						gfxString("+5 to happiness",Sidebar,200,3,2,2,ReportColor)
					case 2
						gfxString("Bound to ship "+str(.LocationID),Sidebar,100,3,2,2,ReportColor)
						gfxString(Starships(.LocationID).ShipName,Sidebar,120,3,2,2,ReportColor)
						
						if right(.Namee,5) = "Blood" then
							gfxString("Can move without fuel",Sidebar,160,3,2,2,ReportColor)
						elseif right(.Namee,5) = "Bones" then
							gfxString("Combat mass 200% of hull mass",Sidebar,160,3,2,2,ReportColor)
						elseif right(.Namee,5) = "Flesh" then
							gfxString("Ground Combat attack ratio set to 50:1",Sidebar,160,3,2,2,ReportColor)
						elseif right(.Namee,4) = "Mind" then
							gfxString("Decreases visibility to 5 LY",Sidebar,160,3,2,2,ReportColor)
						elseif right(.Namee,6) = "Spirit" then
							gfxString("Gains 2X Faster Beams ability",Sidebar,160,3,2,2,ReportColor)
						end if
				end select
					
			end with
	end select
	
	'Auxillary List
	with ActiveReport
		gfxString("("+str(.X)+","+str(.Y)+")",Sidebar,20,3,2,2,rgb(255,255,255))
		line(Sidebar,CanvasScreen.Height-190)-(CanvasScreen.Wideth-1,CanvasScreen.Height-171),BorderBG,bf
		
		SelectionCursor = getRelativePos(.X,.Y)
		drawCursor(SelectionCursor.X,SelectionCursor.Y)
		
		if BaseFound AND SelectedObjType <> REPORT_BASE then
			gfxstring("Base",Sidebar+20,CanvasScreen.Height-188,3,2,2,rgb(255,255,255))
			printgfx("B",Sidebar+20,CanvasScreen.Height-188,3,rgb(255,255,0))
		end if
		if PlanetFound AND SelectedObjType <> REPORT_PLAN then
			gfxstring("Planet",Sidebar+180,CanvasScreen.Height-188,3,2,2,rgb(255,255,255))
			printgfx("P",Sidebar+180,CanvasScreen.Height-188,3,rgb(255,255,0))
		end if
		
		for AuxItem as integer = 1 to 10
			TrueItem = AuxItem + AuxPage * 10
			if TrueItem <= AuxCount then
				with AuxList(TrueItem)
					gfxstring(space(4-len(str(TrueItem)))+str(TrueItem)+". "+.Namee,Sidebar,CanvasScreen.Height-183+AuxItem*15,2,2,1,.Coloring)
					printgfx(str(AuxItem mod 10), Sidebar+21, CanvasScreen.Height-183+AuxItem*15, 2, rgb(255,255,192))
					
					if SelectedID = .ObjID AND SelectedObjType = .ObjType then
						line(Sidebar,CanvasScreen.Height-185+AuxItem*15)-(CanvasScreen.Wideth-1,CanvasScreen.Height-171+AuxItem*15),rgb(255,255,192),b
					end if 
				end with
			end if
		next AuxItem
		
		line(Sidebar,CanvasScreen.Height-20)-(CanvasScreen.Wideth-1,CanvasScreen.Height-1),BorderBG,bf
		if AuxPage > 0 then
			gfxstring("PgUp",Sidebar+20,CanvasScreen.Height-18,3,2,2,rgb(255,255,255))
		end if
		if AuxPage < ceil(AuxCount/10) - 1 then
			gfxstring("PgDn",Sidebar+180,CanvasScreen.Height-18,3,2,2,rgb(255,255,255))
		end if
	end with
end sub

sub clearReport
	setmouse(,,0)
	SelectedObjType = 0
end sub

sub buildAuxList
	dim as double ObjDist
	
	HissBonus = 0
	ArtiBonus = 0
	NebDensity = 0
	StarRadiation = 0
	setmouse(,,1)
	
	for AuxPass as byte = 1 to 4
		for AID as integer = 1 to MetaLimit
			if AuxPass = 1 then
				with Starships(AID)
					if .ShipType > 0 AND .XLoc = ViewPort.X AND .YLoc = ViewPort.Y then
						AuxCount += 1
						with AuxList(AuxCount)
							.Namee = Starships(AID).ShipName
							.Coloring = convertColor(Coloring(Starships(AID).Ownership))
							.ObjType = REPORT_SHIP
							.ObjID = AID
						end with
						
						'Record Lizard Hiss bonus
						if .Mission = 8 AND .Neu > 0 AND .BeamNum > 0 AND _
							PlayerSlot(.Ownership).Race = "Lizard" then
							HissBonus += 5
						end if
					end if
				end with
				
				if AID >= LimitObjs then
					exit for
				end if
				
			elseif AuxPass = 2 then
				with Artifacts(AID)
					if .Namee <> "" AND .X = ViewPort.X AND .Y = ViewPort.Y then
						AuxCount += 1
						with AuxList(AuxCount)
							.Namee =  Artifacts(AID).Namee
							.Coloring = rgb(224,192,160)
							.ObjType = REPORT_ARTI
							.ObjID = AID
						end with
						
						'Record Artifact bonus
						if .LocationType = 1 then
							ArtiBonus += 1
						end if
					end if
				end with
				
				if AID >= LimitObjs then
					exit for
				end if
				
			elseif AuxPass = 3 then
				with Minefields(AID)
					if .MineUnits > 0 AND .X = ViewPort.X AND .Y = ViewPort.Y then
						AuxCount += 1
						with AuxList(AuxCount)
							.Namee = "Minefield "+commaSep(AID)
							if Minefields(AID).Webbed then
								.Namee = "Web "+.Namee
							end if
							.Coloring = convertColor(Coloring(Minefields(AID).Ownership))
							.ObjType = REPORT_MINE
							.ObjID = AID
						end with
					end if
				end with
				
			else
				with IonStorms(AID)				
					if .Voltage > 0 AND .X = ViewPort.X AND .Y = ViewPort.Y then
						AuxCount += 1
						with AuxList(AuxCount)
							.Namee = "Ion Storm "+str(AID)
							.Coloring = rgb(255,255,64)
							.ObjType = REPORT_ION
							.ObjID = AID
						end with
					end if
				end with
				
				with Nebulae(AID)
					ObjDist = sqr((.X - ViewPort.X)^2 + (.Y - ViewPort.Y)^2)
					
					if .Intensity > 0 then
						if .X = ViewPort.X AND .Y = ViewPort.Y then
							NebDensity += .Intensity 
							AuxCount += 1
							with AuxList(AuxCount)
								.Namee = Nebulae(AID).Namee+" Nebula"
								.Coloring = rgb(0,176,0)
								.ObjType = REPORT_NEB
								.ObjID = AID
							end with
						elseif ObjDist <= .Radius then
							NebDensity += ceil(.Intensity * (1 - (ObjDist / .Radius)))
						end if
					end if
				end with
					
				with Wormholes(AID)
					if .Stability > 0 AND .X = ViewPort.X AND .Y = ViewPort.Y then
						AuxCount += 1
						with AuxList(AuxCount)
							.Namee = Wormholes(AID).Namee+" Wormhole"
							.Coloring = rgb(0,160,176)
							.ObjType = REPORT_WORM
							.ObjID = AID
						end with
					end if
				end with
				
				with StarClusters(AID)
					if .Mass > 0 then
						ObjDist = sqr((.X - ViewPort.X)^2 + (.Y - ViewPort.Y)^2)
						
						if ObjDist <= sqr(.Mass) then
							StarRadiation += ceil((.Temperature/100) * (1 - (ObjDist / sqr(.Mass))))
						end if
					end if
				end with
				
				if AID >= LimitObjs then
					exit for
				end if
			end if
		next AID
	next AuxPass 
end sub

sub syncReport(AddCycle as byte = 0)
	BaseFound = 0
	PlanetFound = 0

	select case SelectedObjType
		case REPORT_PLAN
			with Planets(SelectedID)
				ViewPort.X = .X
				ViewPort.Y = .Y
				
				PlanetFound = SelectedID
				BaseFound = max(SelectedID*sgn(.BasePresent),0)
			end with
		
		case REPORT_SHIP
			with Starships(SelectedID)
				if .ShipType <= 0 then
					clearReport
				else
					ViewPort.X = .XLoc
					ViewPort.Y = .YLoc
				end if
			end with
		
		case REPORT_BASE
			with Planets(SelectedID)
				if .BasePresent <= 0 then
					clearReport
				else
					ViewPort.X = .X
					ViewPort.Y = .Y
					
					PlanetFound = SelectedID
					BaseFound = max(SelectedID*sgn(.BasePresent),0)
				end if
			end with
						
		case REPORT_MINE
			with Minefields(SelectedID)
				if .MineUnits <= 0 then
					clearReport
				else
					ViewPort.X = .X
					ViewPort.Y = .Y
				end if
			end with
			
		case REPORT_STAR
			with StarClusters(SelectedID)
				ViewPort.X = .X
				ViewPort.Y = .Y
			end with

		case REPORT_NEB
			with Nebulae(SelectedID)
				ViewPort.X = .X
				ViewPort.Y = .Y
			end with

		case REPORT_ION
			with IonStorms(SelectedID)
				if .Voltage <= 0 then
					clearReport
				else
					ViewPort.X = .X
					ViewPort.Y = .Y
				end if
			end with

		case REPORT_WORM
			with Wormholes(SelectedID)
				if .Stability <= 0 then
					clearReport
				else
					ViewPort.X = .X
					ViewPort.Y = .Y
				end if
			end with

		case REPORT_ARTI
			with Artifacts(SelectedID)
				if .Namee = "" then
					clearReport
				else
					ViewPort.X = .X
					ViewPort.Y = .Y
				end if
			end with
	end select
	
	if SelectedObjType > 0 AND PlanetFound = 0 then
		for PID as short = 1 to LimitObjs
			with Planets(PID)
				if .X = ViewPort.X AND .Y = ViewPort.Y then
					PlanetFound = PID
					BaseFound = max(PID*sgn(.BasePresent),0)
					
					exit for
				end if
			end with
		next PID
	end if

	AuxCount = 0
	AuxPage = 0
	StorePage = 0
	
	if SelectedObjType > 0 then
		buildAuxList
	end if
	RedrawIslands = 1 + AddCycle
end sub
