enum ReportCollection
	REPORT_PLAN = 1
	REPORT_BASE
	REPORT_SHIP
	REPORT_MINE
	REPORT_ION
	REPORT_STAR
	REPORT_NEB
	REPORT_WORM
	REPORT_BHOLE
	REPORT_ARTI
	REPORT_VCR
end enum

dim shared as integer SelectedID
dim shared as double NextMapSlide
dim shared as short Sidebar, SidebarMem
dim shared as ReportCollection SelectedObjType

function convertColor(Brush as ColorSpecs) as uinteger
	return rgb(Brush.Red, Brush.Green, Brush.Blue)
end function

function getRelativePos(InX as short, InY as short) as ViewSpecs
	dim as ViewSpecs WorkObj
	
	WorkObj.X = round((InX - ViewPort.X) * ViewPort.Zoom + Sidebar/2)
	WorkObj.Y = round(CanvasScreen.Height/2 - (InY - ViewPort.Y) * ViewPort.Zoom)
	
	return WorkObj
end function

sub drawFlag(DispX as short, DispY as short, Coloring as uinteger = rgb(224,192,255))
	line(DispX,DispY)-(DispX,DispY-12),Coloring
	line(DispX,DispY-12)-(DispX+6,DispY-9),Coloring
	line(DispX,DispY-6)-(DispX+6,DispY-9),Coloring
end sub

sub planetList
	dim as string NativeRaces(1 to 14) => {"Humanoid", "Bovinoid", "Reptilian", _
		"Avian", "Amorphous", "Insectoid", "Amphibian", "Ghipsodal", "Siliconoid", _
		"", "Botanical", "Diaphanous", "Aquatic", "Ranine"}

	SelectedIndex = 1

	dim as byte ViewMode = 0
	dim as short MaxObjs
	dim as integer RefBaseObj, RefID
	dim as string PlanetOwner
	for Index as integer = LimitObjs to 1 step -1
		if Planets(Index).ObjName <> "" then
			MaxObjs = Index
			exit for
		end if
	next Index
	Midpoint = NormalObjsPerPage/2 

	do
		color rgb(255,255,255),rgb(0,0,0)
		windowtitle WindowStr
		cls
		color rgb(192,192,255)
		select case ViewMode
			case 0
				print "Planet List for ";GameName;" (turn "& TurnNum;")"
				print "ID    Planet Name                 Temp   Colonists    Minerals                    Natives"
				for Index as uinteger = 1 to LimitObjs
					with Planets(Index)
						if (Index-SelectedIndex < ceil(MidPoint) OR _
							-1*(Index-SelectedIndex) < int(MidPoint + 1) OR _
							((Index <= NormalObjsPerPage AND SelectedIndex < ceil(MidPoint + 0.5)) OR _
							(abs(Index-MaxObjs) < NormalObjsPerPage AND SelectedIndex > MaxObjs - ceil(MidPoint)))) AND .ObjName <> "" then
							if SelectedIndex = Index then
								color ,rgb(0,0,64)
								RefID = Index
							else
								color ,rgb(0,0,0)
							end if
							if .Ownership = 0 then
								color rgb(128,128,128)
							else
								color convertColor(Coloring(.Ownership))
							end if
							if .Ownership > 0 then
								'            ID    Planet Name                 Temp   Colonists    Minerals
								print using "###   \                       \    ###   ##,###,###   ";_
									Index;.ObjName;.Temp;.Colonists*100;
								if .Neu < 10000 then
									print using "####N/";.Neu;
								else
									print "++++N/";
								end if
								if .Dur < 10000 then
									print using "####D/";.Dur;
								else
									print "++++D/";
								end if
								if .Trit < 10000 then
									print using "####T/";.Trit;
								else
									print "++++T/";
								end if
								if .Moly < 10000 then
									print using "####M   ";.Moly;
								else
									print "++++M   ";
								end if
								if .Natives > 0 then
									print using "##,###,###  &";.Natives*100;NativeRaces(.NativeType)
								else
									print "--,---,---"
								end if
							elseif .LastScan > 0 then
								'            ID    Planet Name                 Temp   Colonists
								print using "###   \                       \    ###            0   ";_
									Index;.ObjName;.Temp;
								if .Neu >= 10000 then
									print "++++N/";
								elseif .DNeu > 0 then
									print using "####N/";.Neu;
								else
									print "----N/";
								end if
								if .Dur >= 10000 then
									print "++++D/";
								elseif .DDur > 0 then
									print using "####D/";.Dur;
								else
									print "----D/";
								end if
								if .Trit >= 10000 then
									print "++++T/";
								elseif .DTrit > 0 then
									print using "####T/";.Trit;
								else
									print "----T/";
								end if
								if .Moly >= 10000 then
									print "++++M   ";
								elseif .DMoly > 0 then
									print using "####M   ";.Moly;
								else
									print "----M   ";
								end if
								if .Natives > 0 then
									print using "##,###,###  &";.Natives*100;NativeRaces(.NativeType)
								else
									print "--,---,---"
								end if
							else
								'            ID    Planet Name                 Temp   Colonists
								print using "###   \                       \    ---   --,---,---";_
									Index;.ObjName
							end if
						end if
					end with
				next Index
			case 1
				print "Starbase List for ";GameName;" (turn "& TurnNum;")"
				print "ID    Planet Name                 Ownership                            Defense   Fighters   Damage   Tech (HEBT)"
				for Index as uinteger = 1 to LimitObjs
					with Planets(Index)
						if (Index-SelectedIndex < ceil(MidPoint) OR _
							-1*(Index-SelectedIndex) < int(MidPoint + 1) OR _
							((Index <= NormalObjsPerPage AND SelectedIndex < ceil(MidPoint + 0.5)) OR _
							(abs(Index-MaxObjs) < NormalObjsPerPage AND SelectedIndex > MaxObjs - ceil(MidPoint)))) AND .ObjName <> "" then
							if SelectedIndex = Index then
								color ,rgb(0,0,64)
								RefID = Index
							else
								color ,rgb(0,0,0)
							end if
							
							if .Ownership = 0 then
								PlanetOwner = "(unowned planet)"
								color rgb(128,128,128)
							else
								with PlayerSlot(.Ownership)
									PlanetOwner = .Race+" ("+.PlayerName+")"
								end with 
								color convertColor(Coloring(.Ownership))
							end if
							
							'            ID    Planet Name                 Ownership
							print using "###   \                       \   \                                \   ";_
								Index;.ObjName;PlanetOwner;
							
							if .BasePresent > 0 then
								'            Defense   Fighters   Damage   Tech (HEBT)
								print using "    ###        ###     ###%   ##_-##_-##_-##";_
									.OrbDefense;.Fighters;.Damage;.TechH;.TechE;.TechB;.TechT
							else
								'
								print "(no starbase)"
							end if
						end if
					end with
				next Index
		end select
		locate 3+NormalObjsPerPage,1
		color rgb(255,255,255),rgb(0,0,0)
		print "Press TAB to cycle lists. Press ENTER to jump to the selected planet or base"
		screencopy
		do
			sleep 5
			InType = inkey
		loop until InType <> ""

		if InType = UpArrow AND SelectedIndex > 1 then
			SelectedIndex -= 1
		elseif InType = DownArrow AND SelectedIndex < MaxObjs then
			SelectedIndex += 1
		elseif InType = PageUp then
			SelectedIndex = max(SelectedIndex - (NormalObjsPerPage - 1), 1)
		elseif InType = PageDown then
			SelectedIndex = min(SelectedIndex + (NormalObjsPerPage - 1), MaxObjs)
		elseif InType = HomeKey then
			SelectedIndex = 1
		elseif InType = EndKey then
			SelectedIndex = MaxObjs
		elseif InType = EnterKey then
			SelectedID = RefID
			if ViewMode = 1 AND Planets(RefID).BasePresent > 0 then
				SelectedObjType = REPORT_BASE
			else
				SelectedObjType = REPORT_PLAN
			end if
			syncReport(1)
			exit do
		elseif InType = chr(9) then
			ViewMode += 1
			if ViewMode > 1 then ViewMode = 0
		elseif InType = EscKey then
			exit do
		end if
	loop
end sub

sub copyShipEntry(ShipA as short, ShipB as short)
	ShipListIndex(ShipB) = Starships(ShipA)
	
	ShipListIndex(ShipB).LinkId = ShipA
end sub

function searchShips(Filter as string = "") as integer
	dim as short ObjId = 0
	'Null out the ship types first
	for Index as uinteger = 1 to LimitObjs
		ShipListIndex(Index).ShipType = 0
	next Index

	'Fill the list with ships that match the filter (if any)
	for Index as uinteger = 1 to LimitObjs
		if Starships(Index).ShipType > 0 AND left(lcase(Starships(Index).ClassName),len(Filter)) = Filter then
			ObjId += 1
			copyShipEntry(Index,ObjId)
		end if
	next Index
	
	return ObjId
end function

sub shipList
	dim as byte ViewMode = 0
	dim as string ShipOwner, AmmoStr
	dim as string ClassFilter
	
	dim as short MaxObjs, CargoUsed, RefID
	
	'First, consolidate the list (to allow the list to display correctly even with holes in the ship numbers)
	MaxObjs = searchShips
	SelectedIndex = 1
	Midpoint = NormalObjsPerPage/2 

	do
		color rgb(255,255,255),rgb(0,0,0)
		windowtitle WindowStr
		cls
		color rgb(192,192,255)
		select case ViewMode
			case 0
				print "Ship Status for ";GameName;" (turn "& TurnNum;")"
				locate 2,1
				print "ID    Ship Name                        Location      Ship Class                     Ownership                         Dmg   XP"
				for Index as uinteger = 1 to LimitObjs
					with ShipListIndex(Index)
						if (Index-SelectedIndex < ceil(MidPoint) OR _
							-1*(Index-SelectedIndex) < int(MidPoint + 1) OR _
							((Index <= NormalObjsPerPage AND SelectedIndex < ceil(MidPoint + 0.5)) OR _
							(abs(Index-MaxObjs) < NormalObjsPerPage AND SelectedIndex > MaxObjs - ceil(MidPoint)))) AND .ShipType > 0 then
							if SelectedIndex = Index then
								RefID = .LinkId
								color ,rgb(0,0,64)
							else
								color ,rgb(0,0,0)
							end if
							
							if .Ownership = 0 then
								ShipOwner = "(ghost ship)"
								color rgb(128,128,128)
							else
								with PlayerSlot(.Ownership)
									ShipOwner = .Race+" ("+.PlayerName+")"
								end with
								color convertColor(Coloring(.Ownership))
							end if
							
							print using "####  \                            \   ";.LinkId;.ShipName;
							if .OrbitingPlan > 0 then
								'            Location      '
								print using "Planet ###    ";.OrbitingPlan;
							else
								print using "(####_,####)   ";.XLoc;.YLoc;
							end if
							'            Ship Class                     Ownership                         Dmg   XP
							print using "\                          \   \                             \   ###%  ";_
								.ClassName;ShipOwner;.HullDmg;
							
							if .Experience < 1000 then
								print using "###";.Experience
							else
								print "+++"
							end if
						end if
					end with
				next Index
				
			case 1
				print "Ship Details for ";GameName;" (turn "& TurnNum;")"
				locate 2,1
				print "ID    Ship Name                        Fuel        Clans   Dur    Trit   Moly   Supp   Money   Ammo   Cargo       Mass"
				for Index as uinteger = 1 to LimitObjs
					with ShipListIndex(Index)
						if (Index-SelectedIndex < ceil(MidPoint) OR _
							-1*(Index-SelectedIndex) < int(MidPoint + 1) OR _
							((Index <= NormalObjsPerPage AND SelectedIndex < ceil(MidPoint + 0.5)) OR _
							(abs(Index-MaxObjs) < NormalObjsPerPage AND SelectedIndex > MaxObjs - ceil(MidPoint)))) AND .ShipType > 0 then
							
							if SelectedIndex = Index then
								RefID = .LinkId
								color ,rgb(0,0,64)
							else
								color ,rgb(0,0,0)
							end if
							
							if .Ownership = 0 then
								color rgb(128,128,128)
							else
								color convertColor(Coloring(.Ownership))
							end if
							
							CargoUsed = .Colonists + .Dur + .Trit + .Moly + .Supplies + .Ammo
							if PlayerSlot(.Ownership).Race = "Horwasp" then
								if .BayNum > 0 then
									dim as integer MaxWaspFtrs = 70
									if .ClassName = "Soldier" then
										MaxWaspFtrs = 40
									end if 
									
									dim as integer ComputeAmmo = int(.Colonists * (MaxWaspFtrs - 10) / .MaxCargo) + 10 
									
									AmmoStr = space(4-len(str(ComputeAmmo))) + str(ComputeAmmo)
								else
									AmmoStr = "----"
								end if
							elseif .TubeNum > 0 OR .BayNum > 0 then
								AmmoStr = space(4-len(str(.Ammo))) + str(.Ammo)
							else
								AmmoStr = "----"
							end if
							
							'               ID    Ship Name                        Fuel        Clans   Dur    Trit   Moly   Supp   Money   Ammo   Cargo       Mass
							if .MaxCargo > 9999 then
								print using "####  \                            \   ####/####   #####   ####   ####   ####   ####   #####   \  \   #####/##K   ####/#####";_
									.LinkId;.ShipName;.Neu;.MaxFuel;.Colonists;.Dur;.Trit;.Moly;.Supplies;.Megacredits;AmmoStr;CargoUsed;ceil(.MaxCargo/1000);.HullMass;.TotalMass
							else
								print using "####  \                            \   ####/####   #####   ####   ####   ####   ####   #####   \  \   ####/####   ####/#####";_
									.LinkId;.ShipName;.Neu;.MaxFuel;.Colonists;.Dur;.Trit;.Moly;.Supplies;.Megacredits;AmmoStr;CargoUsed;.MaxCargo;.HullMass;.TotalMass
							end if
		
						end if
					end with
				next Index
		end select
		color rgb(255,255,255),rgb(0,0,0)
		locate 3+NormalObjsPerPage,1
		if MaxObjs > 0 then
			print "Press TAB to cycle lists. Press ENTER to jump to the selected ship. Type in letters to narrow ship list by class"
			color rgb(255,192,192)
			print ""& MaxObjs;" ships found. Current class filter: "+ClassFilter+"*"
		elseif ClassFilter <> "" then
			print "No ships were found matching your filter. Try hitting BACKSPACE to relax the filter."
			color rgb(255,192,192)
			print "Current class filter: "+ClassFilter+"*"
		else
			print "No ships were found. Press ESC to return to starmap."
		end if
		screencopy
		do
			sleep 5
			InType = inkey
		loop until InType <> ""

		if InType = UpArrow AND SelectedIndex > 1 then
			SelectedIndex -= 1
		elseif InType = DownArrow AND SelectedIndex < MaxObjs then
			SelectedIndex += 1
		elseif InType = PageUp then
			SelectedIndex = max(SelectedIndex - (NormalObjsPerPage - 1), 1)
		elseif InType = PageDown then
			SelectedIndex = min(SelectedIndex + (NormalObjsPerPage - 1), MaxObjs)
		elseif InType = HomeKey then
			SelectedIndex = 1
		elseif InType = EndKey then
			SelectedIndex = MaxObjs
		elseif ((InType >= "a" AND InType <= "z") OR (InType >= "A" AND InType <= "Z") OR (InType >= "0" AND InType <= "9") OR _
			InType = "-" OR InType = chr(32)) AND MaxObjs > 0 then
			ClassFilter += lcase(InType)
			MaxObjs = searchShips(ClassFilter)
			SelectedIndex = 1
		elseif InType = chr(8) then
			ClassFilter = left(ClassFilter,len(ClassFilter)-1)
			MaxObjs = searchShips(ClassFilter)
			SelectedIndex = 1
		elseif InType = EnterKey AND MaxObjs > 0 then
			SelectedID = RefID
			SelectedObjType = REPORT_SHIP
			syncReport
			exit do
		elseif InType = chr(9) then
			ViewMode += 1
			if ViewMode > 1 then ViewMode = 0
		elseif InType = EscKey then
			exit do
		end if
	loop
end sub

dim shared as VCRobj VCRindex(LimitObjs)

sub copyVCRentry(VCRa as short, VCRb as short)
	VCRindex(VCRb) = VCRbattles(VCRa)
	
	VCRindex(VCRb).InternalID = VCRa
end sub

function compileVCRs as integer
	dim as short ObjId = 0
	'Null out the VCRs first
	for Index as uinteger = 1 to LimitObjs
		VCRindex(Index).InternalID = 0
	next Index

	'Fill the list with fresh VCRs
	for Index as uinteger = 1 to MetaLimit
		if VCRbattles(Index).InternalID > 0 then
			ObjId += 1
			copyVCRentry(Index,ObjId)
		end if
	next Index
	
	return ObjId
end function

sub VCRlist
	dim as byte ViewMode = 0
	dim as string ShipOwner, AmmoStr
	dim as string ClassFilter
	
	dim as short MaxObjs, CargoUsed, RefID
	
	'First, consolidate the list (to allow the list to display correctly even with holes in the VCR numbers)
	MaxObjs = compileVCRs
	SelectedIndex = 1
	Midpoint = NormalObjsPerPage/2 

	do
		color rgb(255,255,255),rgb(0,0,0)
		windowtitle WindowStr
		cls
		color rgb(192,192,255)
		select case ViewMode
			case 0
				print "VCR Status for ";GameName;" (turn "& TurnNum;")"
				locate 2,1
				print "ID    Combatant Left                                      Combatant Right                                    Location     Seed"
				for Index as uinteger = 1 to LimitObjs
					with VCRindex(Index)
						if (Index-SelectedIndex < ceil(MidPoint) OR _
							-1*(Index-SelectedIndex) < int(MidPoint + 1) OR _
							((Index <= NormalObjsPerPage AND SelectedIndex < ceil(MidPoint + 0.5)) OR _
							(abs(Index-MaxObjs) < NormalObjsPerPage AND SelectedIndex > MaxObjs - ceil(MidPoint)))) AND .InternalID > 0 then
							if SelectedIndex = Index then
								RefID = .InternalID
								color ,rgb(0,0,64)
							else
								color ,rgb(0,0,0)
							end if
							
							color rgb(255,255,255)
							'            ID    Combatant Left                              Combatant Right                    Location     Seed
							print using "####  ";.InternalID;
							color convertColor(Coloring(.LeftOwner))
							print using "\                                              \";.Combatants(1).Namee;
							color rgb(255,255,255)
							print " vs ";
							color convertColor(Coloring(.RightOwner))
							print using "\                                              \";.Combatants(2).Namee;
							color rgb(255,255,255)
							print using "   (####_,####)   ";.XLoc;.YLoc;
							if .Seed >= 0 and .Seed < 119 then
								print using " ###";.Seed
							else
								print "Twst"
							end if
						end if
					end with
				next Index
		end select
		color rgb(255,255,255),rgb(0,0,0)
		locate 3+NormalObjsPerPage,1
		if MaxObjs > 0 then
			print "Press ENTER to watch the selected VCR. Press ESC to return to the starmap"
			color rgb(255,192,192)
			print ""& MaxObjs;" VCRs found"
		else
			print "No VCRs were found. Press ESC to return to the starmap"
		end if
		screencopy
		do
			sleep 5
			InType = inkey
		loop until InType <> ""

		if InType = UpArrow AND SelectedIndex > 1 then
			SelectedIndex -= 1
		elseif InType = DownArrow AND SelectedIndex < MaxObjs then
			SelectedIndex += 1
		elseif InType = PageUp then
			SelectedIndex = max(SelectedIndex - (NormalObjsPerPage - 1), 1)
		elseif InType = PageDown then
			SelectedIndex = min(SelectedIndex + (NormalObjsPerPage - 1), MaxObjs)
		elseif InType = HomeKey then
			SelectedIndex = 1
		elseif InType = EndKey then
			SelectedIndex = MaxObjs
		elseif InType = EnterKey AND MaxObjs > 0 then
			watchBattle(VCRindex(SelectedIndex))
			/'
		elseif InType = chr(9) then
			ViewMode += 1
			if ViewMode > 1 then ViewMode = 0
			'/
		elseif InType = EscKey then
			exit do
		end if
	loop
end sub

function playerCode(PlrId as byte) as string
	if PlrId < 10 then
		return str(PlrId)
	else
		return chr(55+PlrId)
	end if
end function

sub playerList
	dim as byte ViewMode = 0
	do
		with GrandTotal
			.PlanetCount = 0
			.Starbases = 0
			.Ships = 0
			.Freighters = 0
			.MilitaryScore = 0
			.EconomicScore = 0
			.TotalNeu = 0
			.TotalDur = 0
			.TotalTrit = 0
			.TotalMoly = 0
			.TotalClans = 0
			.TotalMoney = 0
			.TotalSupplies = 0
		end with
		
		color rgb(255,255,255)
		windowtitle WindowStr
		cls
		color rgb(192,192,255)
		select case ViewMode
			case 0
				print "Detailed Player List for ";GameName;" (turn "& TurnNum;")"
				color rgb(255,255,255)
				print "    Empire                            Planets   Starbases   Starships     Military      Economy"
				for PID as ubyte = 1 to ParticipatingPlayers
					color convertColor(Coloring(PID))
					with PlayerSlot(PID)
						.EconomicScore = 3 * (.TotalDur + .TotalTrit + .TotalMoly) + _
							.TotalSupplies + .TotalMoney
	
						'                Empire                            Planets   Starbases   Starships     Military      Economy"
						print using "[!] \                                \    ###         ###   ### / ###   ##,###,###   ##,###,###";_
							playerCode(PID);.Race+" ("+.PlayerName+")";.PlanetCount;.Starbases;.Ships-.Freighters;.Ships;_
							.MilitaryScore;.EconomicScore
							
							GrandTotal.PlanetCount += .PlanetCount
							GrandTotal.Starbases += .Starbases
							GrandTotal.Ships += .Ships
							GrandTotal.Freighters += .Freighters
							GrandTotal.MilitaryScore += .MilitaryScore
							GrandTotal.EconomicScore += .EconomicScore
					end with
				next PID
				color rgb(255,255,255)
				print
				with GrandTotal
					print using "Grand Total                               ###         ###   ### / ###   ##,###,###   ##,###,###";_
						.PlanetCount;.Starbases;.Ships-.Freighters;.Ships;.MilitaryScore;.EconomicScore
				end with
				color rgb(192,255,192)
				print
				print word_wrap("Economic score is measured by the economic value of each planet, which is calculated using its unspent resources (excluding neutronium). This score is based on PTScore 1.4")
			case 1
				print "Resource Breakdown by Player for ";GameName;" (turn "& TurnNum;")"
				color rgb(255,255,255)
				if ViewGame.Academy then
					print "    Empire                              Duranium   Tritanium   Molybdenum   Colonists   Megacredits"
					for PID as ubyte = 1 to ParticipatingPlayers
						color convertColor(Coloring(PID))
						with PlayerSlot(PID)
							.EconomicScore = 3 * (.TotalDur + .TotalTrit + .TotalMoly) + _
								.TotalSupplies + .TotalMoney
		
							'                Empire                              Duranium   Tritanium   Molybdenum    Colonists   Megacredits"
							print using "[!] \                                \   ###,###     ###,###      ###,###   ##,###,###   ###,###,###";_
								playerCode(PID);.Race+" ("+.PlayerName+")";.TotalDur;.TotalTrit;.TotalMoly;.TotalMoney;.TotalClans
								
								GrandTotal.TotalNeu += .TotalNeu
								GrandTotal.TotalDur += .TotalDur
								GrandTotal.TotalTrit += .TotalTrit
								GrandTotal.TotalMoly += .TotalMoly
								GrandTotal.TotalClans += .TotalClans
								GrandTotal.TotalMoney += .TotalMoney
								GrandTotal.TotalSupplies += .TotalSupplies
						end with
					next PID
					color rgb(255,255,255)
					print
					with GrandTotal
						'                Empire                              Duranium   Tritanium   Molybdenum    Colonists   Megacredits"
						print using "Grand Total                              ###,###     ###,###      ###,###   ##,###,###   ###,###,###";_
							.TotalDur;.TotalTrit;.TotalMoly;.TotalClans;.TotalMoney
					end with
					color rgb(192,255,192)
					print
					print word_wrap("Only unspent resources are tallied in this list")
				else
					print "    Empire                            Neutronium   Duranium   Tritanium   Molybdenum    Colonists   Megacredits     Supplies"
					for PID as ubyte = 1 to ParticipatingPlayers
						color convertColor(Coloring(PID))
						with PlayerSlot(PID)
							.EconomicScore = 3 * (.TotalDur + .TotalTrit + .TotalMoly) + _
								.TotalSupplies + .TotalMoney
		
							'                Empire                            Neutronium   Duranium   Tritanium   Molybdenum    Colonists   Megacredits     Supplies"
							print using "[!] \                                \   ###,###    ###,###     ###,###      ###,###   ##,###,###   ###,###,###   ##,###,###";_
								playerCode(PID);.Race+" ("+.PlayerName+")";.TotalNeu;.TotalDur;.TotalTrit;.TotalMoly;.TotalClans;.TotalMoney;.TotalSupplies
								
								GrandTotal.TotalNeu += .TotalNeu
								GrandTotal.TotalDur += .TotalDur
								GrandTotal.TotalTrit += .TotalTrit
								GrandTotal.TotalMoly += .TotalMoly
								GrandTotal.TotalClans += .TotalClans
								GrandTotal.TotalMoney += .TotalMoney
								GrandTotal.TotalSupplies += .TotalSupplies
						end with
					next PID
					color rgb(255,255,255)
					print
					with GrandTotal
						print using "Grand Total                              ###,###    ###,###     ###,###      ###,###   ##,###,###   ###,###,###   ##,###,###";_
							.TotalNeu;.TotalDur;.TotalTrit;.TotalMoly;.TotalClans;.TotalMoney;.TotalSupplies
					end with
					color rgb(192,255,192)
					print
					print word_wrap("Only unspent resources on planets are tallied in this list")
				end if
			case 2
				print "Relationship Grid for ";GameName;" (turn "& TurnNum;")"
				color rgb(255,255,255)
				print "    Empire                              ";
				for HID as ubyte = 1 to ParticipatingPlayers
					color convertColor(Coloring(HID))
					print " ";playerCode(HID);
				next HID
				print
				
				for PID as ubyte = 1 to ParticipatingPlayers
					color convertColor(Coloring(PID))
					with PlayerSlot(PID)
						print using "[!] \                                \  ";_
							playerCode(PID);.Race+" ("+.PlayerName+")";
							
						for RID as ubyte = 1 to ParticipatingPlayers
							color rgb(255,255,255)
							print space(1);
							if RID = PID then
								'Relationship with yourself? Nah!
								print " ";
								
							else
								select case .Relationship(RID)
									case 0
										'None
										print "-";

									case 1
										'Send ambassador
										print "c";
										
									case 2
										'Offer safe passage
										print "S";
										
									case 3
										'Share intelligence
										print "I";
										
									case 4
										color rgb(128,255,255)
										'Full alliance!
										print "A";
										
									case -1
										color rgb(255,255,128)
										'Blocking communications
										print "B";
										
								end select
							end if
						next RID
						print
						
					end with
				next PID
				color rgb(192,255,192)
				print
				print word_wrap("Diplomacy is shown with the left player's relationship towards the right player.\n\n"+_
					"The letter code is broken down into as follows:\n"+_
					"[-] No relationship. Messages are sent the old fashioned way\n"+_
					_
					"[c] Send an ambassador, and attempt to establish open communication. Ambassadors relay messages instantly to their owner\n"+_
					"[S] The offering player will allow safe passage through mines, and his ships will not open fire upon the targeting player's ships\n"+_
					_
					"[I] In addition to safe passage, the offering player will reveal the locations (but not information) "+_
					"of their planets and ships, and give info of hostile ships and planets\n"+_
					_
					"[A] Has all of the benefits of Share Intel. Additionally, when a mutual alliance exists, detailed information of ships and "+_
					"planets are exchanged amongst the partners, and they share in the victory countdown together in Diplomatic Planets games\n"+_
					_
					"[B] The otherwise offering player blocks communuications from the other player in this "+quote("relationship")+", "+_
					"and executes any ambassaders sent from that player. Ouch!")
		end select
		color rgb(255,255,255)
		print
		print "Press TAB to cycle lists. Press ESC to return to the starmap"
		screencopy
		sleep 15
		InType = inkey
		if InType = chr(9) then
			ViewMode += 1
			if ViewMode > 2 then ViewMode = 0
		end if
	loop until InType = EscKey
end sub

sub fetchNextObj(Direction as byte)
	if SelectedObjType <> 0 then
		dim as integer OrigID = SelectedID
		dim as integer ObjLimit = LimitObjs
		dim as byte ObjFound
		if SelectedObjType = REPORT_MINE then
			ObjLimit = MetaLimit 
		end if
		
		do
			SelectedID += Direction
			if SelectedID > ObjLimit then
				SelectedID = 1
			end if
			if SelectedID < 1 then
				SelectedID = ObjLimit
			end if
			
			select case SelectedObjType
				case REPORT_PLAN
					ObjFound = (Planets(SelectedID).ObjName <> "")
				case REPORT_SHIP
					ObjFound = (Starships(SelectedID).ShipType <> 0)
				case REPORT_BASE
					ObjFound = (Planets(SelectedID).BasePresent > 0)
				case REPORT_MINE
					ObjFound = (Minefields(SelectedID).MineUnits > 0)
				case REPORT_STAR
					ObjFound = (StarClusters(SelectedID).Mass > 0)
				case REPORT_NEB
					ObjFound = (Nebulae(SelectedID).Intensity > 0)
				case REPORT_ION
					ObjFound = (IonStorms(SelectedID).Voltage > 0)
				case REPORT_WORM
					ObjFound = (Wormholes(SelectedID).Stability > 0)
				case REPORT_ARTI
					ObjFound = (Artifacts(SelectedID).Namee <> "")
				case REPORT_VCR
					ObjFound = (VCRbattles(SelectedID).LeftOwner > 0)
				case REPORT_BHOLE
					ObjFound = (BlackHoles(SelectedID).Core > 0)
			end select
			
			if ObjFound then
				syncReport(1)
				exit do
			end if
		loop until SelectedID = OrigID
	end if
end sub

sub launchConvertor(ByVal InternalPtr as any ptr = 0)
	#IFNDEF __FB_DOS__
	dim as string MassTurn
	#IFDEF __FB_WIN32__
	MassTurn = "MassTurn.exe"
	#ELSE
	MassTurn = "MassTurn"
	#ENDIF
	
	if ConvertorLock <> 0 AND ConvertorUse = 0 then
		MutexLock ConvertorLock
		ConvertorUse = 1
		
		if PruneDupes then
			exec(MassTurn,str(GameID)+" --silent --forward --skipComp --prune")
		else
			exec(MassTurn,str(GameID)+" --silent --forward --skipComp")
		end if
		InType = ""
		while inkey <> "":wend
		
		MutexUnlock ConvertorLock
		ConvertorUse = 0
	end if
	#ENDIF
end sub

sub resetViewport
	RedrawIslands = 1
	DistQuota = 84.554
	with ViewPort
		.X = 2000
		.Y = 2000
		.Zoom = 1.0
	end with
end sub
