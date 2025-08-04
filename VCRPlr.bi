type TorpPiece
	Position as short
	Miss as short
end type

type FtrPiece
	Position as short
	Reverse as byte
end type

const MaxTorps = 100
const MaxFighters = 19

type CombatPiece
	PieceID as short
	Namee as string
	
	BeamCt as byte
	TubeCt as byte
	BayCt as byte
	HullID as short
	BeamID as short
	TorpID as short
	
	Shield as integer
	ShieldEnd as integer
	Damage as integer
	DamageEnd as integer
	Crew as short
	CrewEnd as short
	Mass as short
	RaceID as byte
	
	BeamKillX as byte
	BeamChargeX as byte
	TorpChargeX as byte
	TorpMissChance as byte
	CrewDefense as short
	
	TorpAmmo as short
	TorpAmmoEnd as short
	Fighters as short
	FightersEnd as short
	Temperature as short
	Starbase as byte
	
	ShipPos as short
	
	BeamBanks(99) as short
	TorpTubes(99) as short
	
	TorpShell(MaxTorps) as TorpPiece
	FtrCraft(MaxFighters) as FtrPiece
	
	Defeated as byte
end type

type VCRobj
	Seed as integer
	XLoc as short
	YLoc as short
	Battletype as byte
	LeftOwner as byte
	RightOwner as byte
	Turn as short
	InternalID as integer
	QuickDone as byte
	Combatants(2) as CombatPiece
end type

dim shared as VCRobj VCRbattles(MetaLimit), ActiveVCR, ResetVCR
const NumSeeds = 119
const DeadAmmo = -9999

dim shared as byte PlanBattle, SkipBeams
dim shared as short ActiveSeed, BattleTicks, Distance
dim shared as any ptr ShipGraphic(2)

function rollSeededDice(NumSides as short) as short
	dim as short GetResult
	dim as byte TwentySeeds(1 to NumSeeds) => _
		{9, 8, 11, 8, 5, 5, 9, 10, 15, 2, 10, 4, 14, 18, 1, 14, 15, 17, 2, 4, 10, 13, 16, 17, 11, 10, 14, _
		7, 2, 8, 13, 13, 18, 6, 13, 12, 6, 12, 6, 14, 4, 1, 20, 16, 16, 2, 8, 10, 18, _
		4, 20, 16, 17, 15, 6, 19, 16, 14, 2, 15, 11, 6, 9, 17, 15, 4, 3, 12, 16, _
		19, 12, 18, 11, 13, 13, 8, 3, 2, 15, 5, 12, 6, 10, 6, 9, 16, 20, 19, 18, 17, _
		11, 1, 4, 12, 7, 13, 15, 5, 7, 12, 3, 3, 7, 14, 10, 18, 13, 3, 16, 14, 4, 13, 9, 14, 2, 9, 7, 4, 15}
	
	dim as short HundredSeeds(1 to NumSeeds) => _
		{42, 36, 54, 39, 23, 21, 41, 45, 73, 5, 47, 14, 71, 89, 2, 70, 76, 83, 5, 16, _
		50, 64, 78, 87, 53, 47, 66, 33, 5, 37, 63, 61, 88, 29, 62, 58, 26, 61, 30, 67, 16, _
		2, 98, 78, 81, 7, 37, 46, 88, 15, 99, 77, 82, 75, 25, 96, 79, 69, 5, 71, 54, 25, _
		43, 87, 75, 17, 13, 58, 78, 96, 57, 87, 52, 63, 64, 36, 14, 5, 73, 23, 58, 29, 48, _
		27, 43, 77, 99, 95, 88, 84, 55, 2, 15, 57, 33, 61, 76, 22, 31, 61, 11, 13, 31, 70, _
		45, 92, 61, 11, 80, 71, 14, 62, 44, 70, 4, 40, 32, 18, 74}
	
	dim as byte SeventeenSeeds(1 to NumSeeds) => _
		{8, 7, 10, 7, 5, 4, 7, 8, 13, 2, 8, 3, 12, 15, 1, 12, 13, 14, 2, 3, 9, 11, 13, 15, 9, 8, 12, _
		6, 2, 7, 11, 11, 15, 5, 11, 10, 5, 11, 6, 12, 3, 1, 17, 14, 14, 2, 7, 8, 15, 3, 17, 13, 14, 13, 5, _
		16, 14, 12, 2, 12, 10, 5, 8, 15, 13, 4, 3, 10, 13, 16, 10, 15, 9, 11, 11, 7, 3, 2, 13, 5, 10, 5, 9, _
		5, 8, 13, 17, 16, 15, 14, 10, 1, 3, 10, 6, 11, 13, 4, 6, 11, 3, 3, 6, 12, 8, 16, 11, 3, 14, 12, 3, _
		11, 8, 12, 2, 7, 6, 4, 13}
	
	'Roll the dice based on the seed
	select case NumSides
		case 0
			GetResult = 0
		case 20
			GetResult = TwentySeeds(ActiveSeed)
		case 100
			GetResult = HundredSeeds(ActiveSeed)
		case 17
			GetResult = SeventeenSeeds(ActiveSeed)
	end select
	
	'Increment the seed number, and return the rolled result
	ActiveSeed = ActiveSeed mod NumSeeds + 1
	return GetResult
end function

sub skipSeeds(SkipCount as integer)
	ActiveSeed = (ActiveSeed + SkipCount - 1) mod NumSeeds + 1
end sub

sub setupBattle(ByRef BattleSetup as VCRobj)
	dim as byte PlacementMulti(1 to 2) => {-1, 1}
	dim as short ShipSize
	dim as uinteger ShipColor

	'Copy the selected battle to a working object
	ActiveVCR = BattleSetup
	BattleTicks = 0
	SkipBeams = SkipSounds
	
	'Battles start at 54000/58000 km, depending on whether a planet is involved
	PlanBattle = abs(sgn(ActiveVCR.Battletype))
	Distance = 580 - PlanBattle * 40 
	
	for PID as byte = 1 to 2
		with ActiveVCR.Combatants(PID)
			.ShipPos = Distance/2*PlacementMulti(PID)
			
			/'
			 ' Fully shielded and Horwasp ships start with their weapons ready for use;
			 ' EXCEPT if there is a Bloodfang Disruptor involved against a non-Fed ship.
			 '/
			if (.Shield >= 100 OR .RaceID = 12) AND _
				(ActiveVCR.Combatants(int(3-PID)).HullID <> 2050 OR (PID = 1 AND PlanBattle) OR .RaceID = 1) then
				for BID as byte = 1 to max(.BeamCt, .TubeCt)
					.BeamBanks(BID) = 100
					.TorpTubes(BID) = 30
				next BID
			end if
			
			for Ftr as short = 1 to max(MaxFighters,MaxTorps)
				if Ftr <= MaxFighters then
					.FtrCraft(Ftr).Position = DeadAmmo
				end if
				if Ftr <= MaxTorps then
					.TorpShell(Ftr).Position = DeadAmmo
				end if
			next Ftr
		
			line ShipGraphic(PID),(0,0)-(128,128),rgb(255,0,255),bf
			ShipSize = min(.Mass/10,128)
		
			if SkipSounds = 0 then 
				if PID = 1 then
					ShipColor = convertColor(Coloring(ActiveVCR.LeftOwner))
					
					for XID as short = 128 to 128-ceil(ShipSize/2) step -1
						line ShipGraphic(1),(XID,64)-(128-ShipSize,64-ceil(ShipSize/2)),ShipColor
						line ShipGraphic(1),(XID,64)-(128-ShipSize,64+ceil(ShipSize/2)),ShipColor
					next XID
				else
					ShipColor = convertColor(Coloring(ActiveVCR.RightOwner))
					
					if PlanBattle = 0 then
						for XID as short = 0 to ceil(ShipSize/2)
							line ShipGraphic(2),(XID,64)-(ShipSize,64-ceil(ShipSize/2)),ShipColor
							line ShipGraphic(2),(XID,64)-(ShipSize,64+ceil(ShipSize/2)),ShipColor
						next XID
					else
						ShipSize = min(ShipSize,64)
						circle ShipGraphic(2),(ShipSize,64),ShipSize,ShipColor,,,,F
						circle ShipGraphic(2),(ShipSize,64),ShipSize-2,rgb(255,0,255),,,,F
						circle ShipGraphic(2),(ShipSize,64),ShipSize-9,ShipColor,,,,F
					end if
				end if
			end if
		end with
	next PID
	
	ActiveSeed = BattleSetup.Seed + 1 'Throw in a "penalty" seed
end sub


sub damageShip(VictimID as byte, DmgBlast as short, CrewKill as short)
	dim as integer WorkShield, WorkDmg
	
	with ActiveVCR.Combatants(VictimID)
		'Damage the shields first
		WorkShield = -round(80 * DmgBlast / (.Mass + 1) + (1 - .Shield))
		
		if WorkShield < 0 then
			'Shields have been broken, taking hull damage
			.Shield = 0
			WorkDmg = round(-80 * WorkShield / (.Mass + 1) + (1 + .Damage))
			
			.Damage = WorkDmg
			WorkShield = 0
			if VictimID + PlanBattle = 3 then
				'Planets that take damage immediately lose beam power
				.BeamID = max(min(.BeamID, 10-int(.Damage/10)),1)
			end if
		end if
		
		
		if .Shield <= 0 then
			'Some crew get killed. No effect on a planet
			dim as short CrewLoss = round(CrewKill * (100 - min(.CrewDefense,100))/100)
			
			.Crew = max(0,-round(80 * CrewLoss / (.Mass + 1) - .Crew)) 
		end if
		.Shield = WorkShield
	end with
end sub

sub drawBeam(FromPosX as integer, FromPosY as integer, ToPosX as integer, ToPosY as integer, Coloring as uinteger, Pattern as uinteger = &b1110111011101110)
	if SkipBeams = 0 then
		line(CanvasScreen.Wideth/2+FromPosX,FromPosY)-(CanvasScreen.Wideth/2+ToPosX,ToPosY),Coloring,,Pattern
	end if
end sub

sub shootDownFighter(HostPiece as byte, HostBeam as byte)
	dim as short PeerPiece, ClosestFtr, ClosestDist = 999, CurrDist
	dim as uinteger OriginColor
	if HostPiece = 1 then
		OriginColor = convertColor(Coloring(ActiveVCR.LeftOwner))
	else
		OriginColor = convertColor(Coloring(ActiveVCR.RightOwner))
	end if
	PeerPiece = 3 - HostPiece
	
	with ActiveVCR
		for FID as byte = 1 to MaxFighters
			if .Combatants(PeerPiece).FtrCraft(FID).Position <> DeadAmmo then
				CurrDist = abs(.Combatants(HostPiece).ShipPos - .Combatants(PeerPiece).FtrCraft(FID).Position)
				if CurrDist < ClosestDist then
					'Closest fighter gets priority
					ClosestDist = CurrDist
					ClosestFtr = FID
				end if
			end if
		next FID
	
		if ClosestFtr > 0 then
			'Beam shoots down fighter, discharging it
			drawBeam(.Combatants(HostPiece).ShipPos,164,.Combatants(PeerPiece).FtrCraft(ClosestFtr).Position,(6.9+ClosestFtr)*10,OriginColor)
			.Combatants(HostPiece).BeamBanks(HostBeam) = 0
			.Combatants(PeerPiece).FtrCraft(ClosestFtr).Position = DeadAmmo
			
			playClip(SFX_BEAM)
		end if
	end with
end sub

sub fireBeamsAtFighters(PieceID as byte)
	dim as short ShootRoll
	
	with ActiveVCR.Combatants(PieceID) 
		if ActiveVCR.Combatants(int(3-PieceID)).BayCt <= 0 then
			'Save a little juice and just skip seeds
			skipSeeds(.BeamCt)
		else
			for BID as byte = 1 to .BeamCt
				ShootRoll = rollSeededDice(20)
				if .BeamBanks(BID) > 40 AND ShootRoll < 5 then
					shootDownFighter(PieceID, BID)
				end if
			next BID
		end if
	end with
end sub

sub fireBeamsAtRival(PieceID as byte)
	dim as short ShootRoll
	dim as uinteger OriginColor
	if PieceID = 1 then
		OriginColor = convertColor(Coloring(ActiveVCR.LeftOwner))
	else
		OriginColor = convertColor(Coloring(ActiveVCR.RightOwner))
	end if
	
	with ActiveVCR.Combatants(PieceID) 
		for BID as byte = 1 to .BeamCt
			ShootRoll = rollSeededDice(20)
			if .BeamBanks(BID) > 50 AND ShootRoll < 7 then
				dim as short CalcBlast, CalcCrewKill
				
				CalcBlast = round(.BeamBanks(BID) / 100 * Beams(.BeamID).Blast)
				CalcCrewKill = round(.BeamBanks(BID) / 100 * Beams(.BeamID).CrewKill) * .BeamKillX
				
				drawBeam(.ShipPos-abs(int(BID-.BeamCt/2)),164+BID-.BeamCt/2,ActiveVCR.Combatants(int(3-PieceID)).ShipPos,164,OriginColor)
				playClip(SFX_BEAM)
				damageShip(3-PieceID,CalcBlast,CalcCrewKill)
				.BeamBanks(BID) = 0
			end if
		next BID
	end with
end sub

sub fireBeams
	'Assymetrical, serves as a minor counter balance
	if Distance < 200 then
		fireBeamsAtRival(1)
	end if

	fireBeamsAtFighters(1)
	fireBeamsAtFighters(2)

	if Distance < 200 then
		fireBeamsAtRival(2)
	end if
end sub


sub shootTorp(HostPiece as byte, AmmoID as byte)
	playClip(SFX_TORP)
	dim as short HitRoll = rollSeededDice(100), UseID
	dim as byte HitScored = abs(sgn(HitRoll >= ActiveVCR.Combatants(int(3-HostPiece)).TorpMissChance))

	with ActiveVCR.Combatants(HostPiece)
		'Deduct from the host
		.TorpTubes(AmmoID) = 0
		.TorpAmmo -= 1
		
		UseID = .TorpAmmo mod ubound(.TorpShell) + 1
		
		'Fire it away
		with .TorpShell(UseID)
			.Position = ActiveVCR.Combatants(HostPiece).ShipPos
			.Miss = 1 - HitScored
		end with
		
		if HitScored then
			'Damage the victim, if appropriate
			damageShip(3-HostPiece,Tubes(.TorpID).Blast * 2,Tubes(.TorpID).CrewKill * 2)
		end if
	end with
end sub

sub fireTubes
	dim as byte FireRoll
	
	for PID as byte = 1 to 2
		with ActiveVCR.Combatants(PID)
			if Distance < Tubes(.TorpID).Range then
				for TID as byte = 1 to .TubeCt
					if .TorpAmmo <= 0 then
						'No ammo left, so this player ends early
						exit for
					end if
					
					'Here is where the d17s come into play
					FireRoll = rollSeededDice(17)
					if .TorpTubes(TID) > 40 OR (.TorpTubes(TID) > 30 AND FireRoll < .TorpID mod 100) then
						shootTorp(PID,TID)
					end if
					
					'Recharge the tube
					.TorpTubes(TID) += .TorpChargeX
				next TID
			end if
			
			'Visual effect
			for AID as short = 1 to MaxTorps
				if abs(.TorpShell(AID).Position) < 1000 then
					.TorpShell(AID).Position += 40 * (1.5 - PID)
					
					if .TorpShell(AID).Miss > 0 then
						.TorpShell(AID).Miss += 7
					elseif (PID = 1 AND .TorpShell(AID).Position > ActiveVCR.Combatants(2).ShipPos) OR _
						(PID = 2 AND .TorpShell(AID).Position < ActiveVCR.Combatants(1).ShipPos) then
						.TorpShell(AID).Position = DeadAmmo
					end if
				end if
			next AID
		end with
	next PID
end sub


function countFighters(PieceID as byte) as short
	dim as short FtrsFound
	for FID as byte = 1 to MaxFighters
		with ActiveVCR.Combatants(PieceID).FtrCraft(FID)
			if .Position <> DeadAmmo then
				FtrsFound += 1
			end if
		end with
	next FID
	
	return FtrsFound
end function

sub launchFighter(PieceID as byte)
	for FID as byte = 1 to MaxFighters
		with ActiveVCR.Combatants(PieceID)
			if .FtrCraft(FID).Position = DeadAmmo then
				.FtrCraft(FID).Position = .ShipPos
				.FtrCraft(FID).Reverse = 0
				.Fighters -= 1
				
				exit for
			end if
		end with
	next FID
end sub

sub prepFighterBays
	for PID as byte = 1 to 2
		with ActiveVCR.Combatants(PID)
			if .BayCt > 0 then
				dim as short LaunchRoll = rollSeededDice(20)
				
				if LaunchRoll <= .BayCt AND .Fighters > 0 then
					launchFighter(PID)
				end if
			end if 
		end with
	next PID
end sub


sub moveFighters
	dim as CombatPiece PeerPiece
	dim as uinteger OriginColor(2)
	OriginColor(1) = convertColor(Coloring(ActiveVCR.LeftOwner))
	OriginColor(2) = convertColor(Coloring(ActiveVCR.RightOwner))
	
	for FID as byte = 1 to MaxFighters
		'Left side first
		PeerPiece = ActiveVCR.Combatants(2)
		with ActiveVCR.Combatants(1)
			if .FtrCraft(FID).Position <> DeadAmmo then
				if .FtrCraft(FID).Position > PeerPiece.ShipPos + 10 then
					'Re-verse!
					.FtrCraft(FID).Reverse = 1
				end if
				
				if .FtrCraft(FID).Position < .ShipPos AND .FtrCraft(FID).Reverse then
					'Fighter returns home
					.FtrCraft(FID).Position = DeadAmmo
					.Fighters += 1
				elseif .FtrCraft(FID).Reverse then
					.FtrCraft(FID).Position -= 4
				else
					.FtrCraft(FID).Position += 4
					
					if abs(.FtrCraft(FID).Position - PeerPiece.ShipPos) < 20 then
						'Damage the opposing ship, assuming no resistance
						if PeerPiece.CrewDefense <= 100 ORELSE rollSeededDice(100) > PeerPiece.CrewDefense - 100 then
							drawBeam(.FtrCraft(FID).Position,(6.9+FID)*10,PeerPiece.ShipPos+irandom(0,4),164,OriginColor(1))
							damageShip(2,2,2)
							playClip(SFX_FIGHTER)
						end if
					end if 
				end if
				
			end if
		end with

		'Right side
		PeerPiece = ActiveVCR.Combatants(1)
		with ActiveVCR.Combatants(2)
			if .FtrCraft(FID).Position <> DeadAmmo then
				if .FtrCraft(FID).Position < PeerPiece.ShipPos - 10 then
					'Re-verse!
					.FtrCraft(FID).Reverse = 1
				end if
				
				if .FtrCraft(FID).Position > .ShipPos AND .FtrCraft(FID).Reverse then
					'Fighter returns home
					.FtrCraft(FID).Position = DeadAmmo
					.Fighters += 1
				elseif .FtrCraft(FID).Reverse then
					.FtrCraft(FID).Position += 4
				else
					.FtrCraft(FID).Position -= 4
					
					if abs(.FtrCraft(FID).Position - PeerPiece.ShipPos) < 20 then
						'Damage the opposing ship, assuming no resistance
						if PeerPiece.CrewDefense <= 100 ORELSE rollSeededDice(100) > PeerPiece.CrewDefense - 100 then
							drawBeam(.FtrCraft(FID).Position,(6.9+FID)*10,PeerPiece.ShipPos-irandom(0,4),164,OriginColor(2))
							damageShip(1,2,2)
							playClip(SFX_FIGHTER)
						end if
					end if 
				end if
			end if
		end with
	next FID
end sub

sub fighterDogfighting
	dim as short DogfightRoll
	dim as uinteger OriginColor(2)
	OriginColor(1) = convertColor(Coloring(ActiveVCR.LeftOwner))
	OriginColor(2) = convertColor(Coloring(ActiveVCR.RightOwner))
	
	with ActiveVCR
		if .Combatants(1).BayCt > 0 AND .Combatants(2).BayCt > 0 then
			'Prepare Dogfight damage
			for LFtr as byte = 1 to MaxFighters
				if .Combatants(1).FtrCraft(LFtr).Position <> DeadAmmo then
					for RFtr as byte = 1 to MaxFighters
						if .Combatants(1).FtrCraft(LFtr).Position = .Combatants(2).FtrCraft(RFtr).Position then
							DogfightRoll = rollSeededDice(100)
							playClip(SFX_FIGHTER)
							
							'Flag one of these fighters as a casualty
							if DogfightRoll >= 50 then
								drawBeam(.Combatants(1).FtrCraft(LFtr).Position,(6.9+LFtr)*10,.Combatants(2).FtrCraft(RFtr).Position,(6.9+RFtr)*10,OriginColor(1))
								.Combatants(2).FtrCraft(RFtr).Reverse = -1
							elseif .Combatants(2).FtrCraft(RFtr).Reverse <> -1 then
								/'
								 ' Left side fighters get a huge advantage,
								 ' not only because they get a 6% advantage in the d100 rolls,
								 ' but because they can still shoot even when destroyed in the very same tick.
								 '
								 ' Right side fighters get no accomodation in either instance.
								 '/
								drawBeam(.Combatants(2).FtrCraft(RFtr).Position,(6.9+RFtr)*10,.Combatants(1).FtrCraft(LFtr).Position,(6.9+LFtr)*10,OriginColor(2))
								.Combatants(1).FtrCraft(LFtr).Reverse = -1
							end if
						end if
					next RFtr
				end if
			next LFtr
			
			'Destroy casualties
			for PID as byte = 1 to 2
				for DFtr as byte = 1 to MaxFighters
					with .Combatants(PID).FtrCraft(DFtr)
						if .Reverse = -1 then
							.Position = DeadAmmo
						end if
					end with
				next DFtr
			next PID
		end if
	end with
end sub


sub rechargeBeams
	for PID as byte = 1 to 2
		with ActiveVCR.Combatants(PID)
			for BeamID as byte = 1 to .BeamCt
				if rollSeededDice(100) > 50 AND .BeamBanks(BeamID) < 100 then
					.BeamBanks(BeamID) += .BeamChargeX
				end if
			next BeamID
		end with
	next PID
end sub

function combatOver as byte
	return BattleTicks >= 2000 OR ActiveVCR.Combatants(1).Defeated OR ActiveVCR.Combatants(2).Defeated
end function

sub checkPieces
	dim as short DamageThresh(1 to 2) => {100, 100}
	
	for PID as byte = 2 to 1 step -1
		with ActiveVCR.Combatants(PID)
			if .RaceID = 2 AND PID + PlanBattle < 3 then
				'Lizard Crew Bonus
				DamageThresh(PID) = 151
			end if
			
			if .Crew <= 0 AND PlanBattle = 0 then
				'Ship has been captured
				.Defeated = 2
			end if
			
			if .Damage >= DamageThresh(PID) OR ((.Damage >= 100 OR ActiveVCR.Combatants(int(3-PID)).RaceID = 12) AND .Crew <= 0 AND PlanBattle = 0) OR _
				(PlanBattle AND combatOver AND ((.Damage >= 100 AND ShiplistObj(.HullID).HullName <> "Zilla Battlecarrier") OR .Crew <= 0)) then
				'Ship has been destroyed
				.Defeated = 1
			end if
		end with
	next PID
end sub


sub playVCRcycle
	'Pass time
	BattleTicks += 1
	
	'Move Ships
	if Distance > 30 then
		ActiveVCR.Combatants(1).ShipPos += 1
		Distance -= 1
		
		if PlanBattle = 0 then
			ActiveVCR.Combatants(2).ShipPos -= 1
			Distance -= 1
		end if
	end if
	
	fireBeams
	fireTubes
	
	prepFighterBays
	moveFighters
	fighterDogfighting
	
	rechargeBeams
	checkPieces
end sub


sub drawFighter(XPos as short, YPos as short, Direction as byte, FtrColor as uinteger)
	if Direction = 1 then
		line(XPos-1,YPos)-(XPos+1,YPos-2),FtrColor
		line(XPos-1,YPos)-(XPos+1,YPos+2),FtrColor
		line(XPos+1,YPos-2)-(XPos+1,YPos+2),FtrColor
	else
		line(XPos+1,YPos)-(XPos-1,YPos-2),FtrColor
		line(XPos+1,YPos)-(XPos-1,YPos+2),FtrColor
		line(XPos-1,YPos-2)-(XPos-1,YPos+2),FtrColor
	end if
end sub

function defeatedShip(ByVal Source as ulong, ByVal Dest as ulong, ByVal Aux as any ptr) as ulong
	if Source <> rgb(255,0,255) ANDALSO rnd < 0.33 then
		return Source
	else
		return Dest
	end if
end function

sub drawCombatObjs
	dim as uinteger PlayerColor
	dim as byte MissDir
	
	with ActiveVCR
		if .Combatants(1).Defeated = 1 then
			put (CanvasScreen.Wideth/2-128+ActiveVCR.Combatants(1).ShipPos,100), ShipGraphic(1), custom, @defeatedShip
		else
			put (CanvasScreen.Wideth/2-128+ActiveVCR.Combatants(1).ShipPos,100), ShipGraphic(1), trans
		end if
		
		if .Combatants(2).Defeated = 1 AND PlanBattle = 0 then
			put (CanvasScreen.Wideth/2+ActiveVCR.Combatants(2).ShipPos,100), ShipGraphic(2), custom, @defeatedShip
		else
			put (CanvasScreen.Wideth/2+ActiveVCR.Combatants(2).ShipPos,100), ShipGraphic(2), trans
		end if
	end with
	
	for FID as byte = 1 to MaxFighters
		with ActiveVCR.Combatants(1).FtrCraft(FID)
			PlayerColor = convertColor(Coloring(ActiveVCR.LeftOwner))

			if .Position <> DeadAmmo then
				drawFighter(CanvasScreen.Wideth/2+.Position,(6.9+FID)*10,2-.Reverse,PlayerColor)
			end if
		end with

		with ActiveVCR.Combatants(2).FtrCraft(FID)
			PlayerColor = convertColor(Coloring(ActiveVCR.RightOwner))

			if .Position <> DeadAmmo then
				drawFighter(CanvasScreen.Wideth/2+.Position,(6.9+FID)*10,1+.Reverse,PlayerColor)
			end if
		end with
	next FID
	
	for TID as byte = 1 to MaxTorps
		if TID mod 2 = 0 then
			MissDir = -1
		else
			MissDir = 1
		end if
		
		with ActiveVCR.Combatants(1).TorpShell(TID)
			PlayerColor = convertColor(Coloring(ActiveVCR.LeftOwner))

			if .Position <> DeadAmmo then
				circle(CanvasScreen.Wideth/2+.Position,164+.Miss*MissDir),2,PlayerColor,,,,F
			end if
		end with

		with ActiveVCR.Combatants(2).TorpShell(TID)
			PlayerColor = convertColor(Coloring(ActiveVCR.RightOwner))

			if .Position <> DeadAmmo then
				circle(CanvasScreen.Wideth/2+.Position,164+.Miss*MissDir),2,PlayerColor,,,,F
			end if
		end with
	next TID
end sub

sub drawOverlay
	#IFDEF RGBA_RED
	dim as integer TotalDist = Distance * 100
	dim as uinteger CombatColor
	dim as string CombatStr
	dim as short MeterWidth, WeaponY, BeamsY
	
	MeterWidth = min(CanvasScreen.Wideth/2-412,150)
	
	CombatStr = "versus"
	gfxString(CombatStr,CanvasScreen.Wideth/2-gfxLength(CombatStr,4,3,3)/2,0,4,3,3,rgb(255,255,255))
	
	if BattleTicks >= 1000 then
		dim as double TimePassed = BattleTicks/20+1e-6
		
		CombatStr = "Time: "+left(str(TimePassed),len(str(int(TimePassed)))+2)+"%"
		if BattleTicks >= 2000 then
			CombatColor = rgb(255,255,0)
		else
			CombatColor = rgb(255,255,255)
		end if
		gfxString(CombatStr,CanvasScreen.Wideth/2-gfxLength(CombatStr,4,3,3)/2,300,4,3,3,CombatColor)
	else
		TotalDist = Distance * 100
		
		CombatStr = "Distance: "+commaSep(TotalDist)+"m"
		gfxString(CombatStr,CanvasScreen.Wideth/2-gfxLength(CombatStr,4,3,3)/2,300,4,3,3,rgb(255,255,255))
	end if

	'Left side stuff
	WeaponY = 450
	BeamsY = 450
	with PlayerSlot(ActiveVCR.LeftOwner)
		CombatStr = .Race+ " ("+.PlayerName+")"
		gfxString(CombatStr,CanvasScreen.Wideth/4-gfxLength(CombatStr,4,3,3)/2,0,4,3,3,convertColor(Coloring(ActiveVCR.LeftOwner)))
	end with
	
	if ActiveVCR.Combatants(2).BayCt > 0 then
		BeamsY += 60
	end if
	if ActiveVCR.Combatants(2).TubeCt > 0 then
		BeamsY += 150
	end if

	with ActiveVCR.Combatants(1)
		CombatStr = .Namee
		gfxString(CombatStr,CanvasScreen.Wideth/4-gfxLength(CombatStr,4,3,3)/2,25,4,3,3,rgb(255,255,255))
		
		CombatStr = "Mass  : "+commaSep(.Mass)+"kT"
		gfxString(CombatStr,CanvasScreen.Wideth/2-225-MeterWidth,330,4,3,3,rgb(255,255,255))
		if .RaceID <> 12 then 
			CombatStr = "Shield: "+str(.Shield)+"%"
			gfxString(CombatStr,CanvasScreen.Wideth/2-225-MeterWidth,360,4,3,3,rgb(255,255,255))
			if .Shield > 0 then
				line(CanvasScreen.Wideth/2-50-MeterWidth,360)-(CanvasScreen.Wideth/2-51-MeterWidth+min(.Shield,MeterWidth),379),rgb(0,128,255),bf
			end if
		end if
		CombatStr = "Damage: "+str(.Damage)+"%"
		if .Damage >= 151 then
			CombatColor = rgb(255,128,0)
		elseif .Damage >= 100 then
			CombatColor = rgb(255,255,0)
		else
			CombatColor = rgb(255,255,255)
		end if
		gfxString(CombatStr,CanvasScreen.Wideth/2-225-MeterWidth,390,4,3,3,CombatColor)
		if .Damage > 0 then
			line(CanvasScreen.Wideth/2-50-MeterWidth,390)-(CanvasScreen.Wideth/2-51-MeterWidth+min(.Damage,MeterWidth),409),rgb(255,64,64),bf
		end if
		if .RaceID <> 12 then 
			CombatStr = "Crew  : "+commaSep(.Crew)
			if .Crew <= 0 then
				CombatColor = rgb(255,255,0)
			else
				CombatColor = rgb(255,255,255)
				line(CanvasScreen.Wideth/2-50-MeterWidth,420)-(CanvasScreen.Wideth/2-51-MeterWidth+min(.Crew,MeterWidth),439),rgb(128,255,0),bf
			end if
			gfxString(CombatStr,CanvasScreen.Wideth/2-225-MeterWidth,420,4,3,3,CombatColor)
		end if
		if .BayCt > 0 then
			dim as short FtrCount = .Fighters+countFighters(1)
			
			CombatStr = "Ftrs  : "+str(FtrCount)
			gfxString(CombatStr,CanvasScreen.Wideth/2-225-MeterWidth,WeaponY,4,3,3,rgb(255,255,255))
			CombatStr = "Fighter Bays x"+str(.BayCt)
			gfxString(CombatStr,CanvasScreen.Wideth/2-225-MeterWidth,WeaponY+30,4,3,3,rgb(255,255,255))
			
			if FtrCount > 0 then
				line(CanvasScreen.Wideth/2-50-MeterWidth,WeaponY)-(CanvasScreen.Wideth/2-51-MeterWidth+min(FtrCount,MeterWidth),WeaponY+19),rgb(255,255,255),bf
			end if
			
			WeaponY += 60
			BeamsY = max(WeaponY,BeamsY)
		end if
		if .TubeCt > 0 then
			CombatStr = "Torps : "+str(.TorpAmmo)
			gfxString(CombatStr,CanvasScreen.Wideth/2-225-MeterWidth,WeaponY,4,3,3,rgb(255,255,255))

			CombatStr = Tubes(.TorpID).PartName+" Tubes x"+str(.TubeCt)
			gfxString(CombatStr,CanvasScreen.Wideth/2-225-MeterWidth,WeaponY+30,4,3,3,rgb(255,255,255))
			
			if .TorpAmmo > 0 then
				line(CanvasScreen.Wideth/2-50-MeterWidth,WeaponY)-(CanvasScreen.Wideth/2-51-MeterWidth+min(.TorpAmmo,MeterWidth),WeaponY+19),rgb(255,255,255),bf
			end if
			
			for TID as byte = 1 to .TubeCt
				if .TorpTubes(TID) < 16 then
					CombatColor = rgb(255,64,64)
				elseif .TorpTubes(TID) < 31 then
					CombatColor = rgb(255,255,0)
				else
					CombatColor = rgb(0,255,0)
				end if
				
				line(CanvasScreen.Wideth/2-225-MeterWidth,WeaponY+60+TID*5)-(CanvasScreen.Wideth/2-25-MeterWidth,WeaponY+63+TID*5),rgb(64,64,64),bf
				line(CanvasScreen.Wideth/2-25-MeterWidth-.TorpTubes(TID)/41*200,WeaponY+60+TID*5)-(CanvasScreen.Wideth/2-25-MeterWidth,WeaponY+63+TID*5),CombatColor,bf
			next TID
			
			WeaponY += 150
			BeamsY = max(WeaponY,BeamsY)
		end if
		if .BeamCt > 0 then
			CombatStr = Beams(.BeamID).PartName+" Banks x"+str(.BeamCt)
			gfxString(CombatStr,CanvasScreen.Wideth/2-225-MeterWidth,BeamsY,4,3,3,rgb(255,255,255))
			
			for BID as byte = 1 to .BeamCt
				if .BeamBanks(BID) <= 40 then
					CombatColor = rgb(255,64,64)
				elseif .BeamBanks(BID) <= 50 then
					CombatColor = rgb(255,255,0)
				else
					CombatColor = rgb(0,255,0)
				end if
				
				line(CanvasScreen.Wideth/2-225-MeterWidth,BeamsY+30+BID*5)-(CanvasScreen.Wideth/2-25-MeterWidth,BeamsY+33+BID*5),rgb(64,64,64),bf
				line(CanvasScreen.Wideth/2-25-MeterWidth-.BeamBanks(BID)*2,BeamsY+30+BID*5)-(CanvasScreen.Wideth/2-25-MeterWidth,BeamsY+33+BID*5),CombatColor,bf
			next BID
		end if
	end with

	'Right side stuff
	WeaponY = 450
	with PlayerSlot(ActiveVCR.RightOwner)
		CombatStr = .Race+ " ("+.PlayerName+")"
		gfxString(CombatStr,CanvasScreen.Wideth*3/4-gfxLength(CombatStr,4,3,3)/2,0,4,3,3,convertColor(Coloring(ActiveVCR.RightOwner)))
	end with

	with ActiveVCR.Combatants(2)
		CombatStr = .Namee
		gfxString(CombatStr,CanvasScreen.Wideth*3/4-gfxLength(CombatStr,4,3,3)/2,25,4,3,3,rgb(255,255,255))
		
		CombatStr = "Mass  : "+commaSep(.Mass)+"kT"
		gfxString(CombatStr,CanvasScreen.Wideth/2+60+MeterWidth,330,4,3,3,rgb(255,255,255))
		if .RaceID <> 12 then 
			CombatStr = "Shield: "+str(.Shield)+"%"
			gfxString(CombatStr,CanvasScreen.Wideth/2+60+MeterWidth,360,4,3,3,rgb(255,255,255))
			if .Shield > 0 then
				line(CanvasScreen.Wideth/2+51+MeterWidth-min(.Shield,MeterWidth),360)-(CanvasScreen.Wideth/2+50+MeterWidth,379),rgb(0,128,255),bf
			end if
		end if
		CombatStr = "Damage: "+str(.Damage)+"%"
		if .Damage >= 151 then
			CombatColor = rgb(255,128,0)
		elseif .Damage >= 100 then
			CombatColor = rgb(255,255,0)
		else
			CombatColor = rgb(255,255,255)
		end if
		gfxString(CombatStr,CanvasScreen.Wideth/2+60+MeterWidth,390,4,3,3,CombatColor)
		if .Damage > 0 then
			line(CanvasScreen.Wideth/2+51+MeterWidth-min(.Damage,MeterWidth),390)-(CanvasScreen.Wideth/2+50+MeterWidth,409),rgb(255,64,64),bf
		end if
		if PlanBattle = 0 AND .RaceID <> 12 then
			CombatStr = "Crew  : "+commaSep(.Crew)
			if .Crew <= 0 then
				CombatColor = rgb(255,255,0)
			else
				CombatColor = rgb(255,255,255)
				line(CanvasScreen.Wideth/2+51+MeterWidth-min(.Crew,MeterWidth),420)-(CanvasScreen.Wideth/2+50+MeterWidth,439),rgb(128,255,0),bf
			end if
			gfxString(CombatStr,CanvasScreen.Wideth/2+60+MeterWidth,420,4,3,3,CombatColor)
		end if
		if .BayCt > 0 then
			dim as short FtrCount = .Fighters+countFighters(2)
			
			CombatStr = "Ftrs  : "+str(FtrCount)
			gfxString(CombatStr,CanvasScreen.Wideth/2+60+MeterWidth,WeaponY,4,3,3,rgb(255,255,255))
			CombatStr = "Fighter Bays x"+str(.BayCt)
			gfxString(CombatStr,CanvasScreen.Wideth/2+60+MeterWidth,WeaponY+30,4,3,3,rgb(255,255,255))
			
			if FtrCount > 0 then
				line(CanvasScreen.Wideth/2+51+MeterWidth-min(FtrCount,MeterWidth),WeaponY)-(CanvasScreen.Wideth/2+50+MeterWidth,WeaponY+19),rgb(255,255,255),bf
			end if
			
			WeaponY += 60
		end if
		if .TubeCt > 0 then
			CombatStr = "Torps : "+str(.TorpAmmo)
			gfxString(CombatStr,CanvasScreen.Wideth/2+60+MeterWidth,WeaponY,4,3,3,rgb(255,255,255))

			CombatStr = Tubes(.TorpID).PartName+" Tubes x"+str(.TubeCt)
			gfxString(CombatStr,CanvasScreen.Wideth/2+60+MeterWidth,WeaponY+30,4,3,3,rgb(255,255,255))
			
			if .TorpAmmo > 0 then
				line(CanvasScreen.Wideth/2+51+MeterWidth-min(.TorpAmmo,MeterWidth),WeaponY)-(CanvasScreen.Wideth/2+50+MeterWidth,WeaponY+19),rgb(255,255,255),bf
			end if
			
			for TID as byte = 1 to .TubeCt
				if .TorpTubes(TID) < 16 then
					CombatColor = rgb(255,64,64)
				elseif .TorpTubes(TID) < 31 then
					CombatColor = rgb(255,255,0)
				else
					CombatColor = rgb(0,255,0)
				end if
				
				line(CanvasScreen.Wideth/2+60+MeterWidth,WeaponY+60+TID*5)-(CanvasScreen.Wideth/2+260+MeterWidth,WeaponY+63+TID*5),rgb(64,64,64),bf
				line(CanvasScreen.Wideth/2+60+MeterWidth,WeaponY+60+TID*5)-(CanvasScreen.Wideth/2+60+MeterWidth+.TorpTubes(TID)/41*200,WeaponY+63+TID*5),CombatColor,bf
			next TID
			
			WeaponY += 150
		end if
		if .BeamCt > 0 then
			CombatStr = Beams(.BeamID).PartName+" Banks x"+str(.BeamCt)
			gfxString(CombatStr,CanvasScreen.Wideth/2+60+MeterWidth,BeamsY,4,3,3,rgb(255,255,255))
			
			for BID as byte = 1 to .BeamCt
				if .BeamBanks(BID) <= 40 then
					CombatColor = rgb(255,64,64)
				elseif .BeamBanks(BID) <= 50 then
					CombatColor = rgb(255,255,0)
				else
					CombatColor = rgb(0,255,0)
				end if
				
				line(CanvasScreen.Wideth/2+60+MeterWidth,BeamsY+30+BID*5)-(CanvasScreen.Wideth/2+260+MeterWidth,BeamsY+33+BID*5),rgb(64,64,64),bf
				line(CanvasScreen.Wideth/2+60+MeterWidth,BeamsY+30+BID*5)-(CanvasScreen.Wideth/2+60+MeterWidth+.BeamBanks(BID)*2,BeamsY+33+BID*5),CombatColor,bf
			next BID
		end if
	end with
	#ENDIF
end sub

function quickBattle(ByRef ActiveBattle as VCRobj, SeedOverride as short = 0) as short
	dim as byte VCRspeed = DefaultVCRspeed
	dim as short OutcomeCode = 0
	
	SkipSounds = 1
	setupBattle(ActiveBattle)
	if SeedOverride > 0 then
		ActiveSeed = SeedOverride
	end if
	if ActiveSeed < 0 then
		return -1 'Twister Battles are NYI
	end if
	
	do
		playVCRcycle
	loop until combatOver
	
	if SeedOverride = 0 then
		ActiveBattle.QuickDone = 1
	end if
	for PID as byte = 1 to 2
		with ActiveVCR.Combatants(PID)
			if SeedOverride = 0 then	
				ActiveBattle.Combatants(PID).ShieldEnd = .Shield
				ActiveBattle.Combatants(PID).DamageEnd = .Damage
				ActiveBattle.Combatants(PID).CrewEnd = .Crew
				ActiveBattle.Combatants(PID).TorpAmmoEnd = .TorpAmmo
				ActiveBattle.Combatants(PID).FightersEnd = .Fighters + countFighters(PID)
			end if
			
			if .Defeated = 1 then
				OutcomeCode += 2^((PID-1)*2)
			elseif .Defeated = 2 then
				OutcomeCode += 2^(1+(PID-1)*2)
			end if
		end with
	next PID
	
	return OutcomeCode
end function

sub watchBattle(ByRef ActiveBattle as VCRobj)
	dim as byte VCRspeed = DefaultVCRspeed, BaseSeed, QuickFinish
	dim as short DestroyedCt(2), CapturedCt(2), QuickCode
	dim as double OddsChance
	dim as string OddsDisp
	dim as short MeterWidth
	
	MeterWidth = min(CanvasScreen.Wideth/2-412,150)
	
	SkipSounds = 0
	setupBattle(ActiveBattle)
	BaseSeed = ActiveBattle.Seed
	if BaseSeed <= 0 then
		exit sub 'Twister Battles are NYI
	end if
	
	do
		cls
		playVCRcycle
		
		drawCombatObjs
		drawOverlay
		if QuickFinish = 0 then
			screencopy
			sleep (10-VCRspeed)*25,1
			InType = inkey
		end if
		
		if lcase(InType) = "f" then
			QuickFinish = 1
			SkipSounds = 1
		elseif InType >= "1" AND InType <= "9" then
			'Adjust playback speed
			VCRspeed = valint(InType)
		elseif InType = chr(32) then
			'Pause playback
			while inkey <> "":wend
			sleep
		elseif InType = EscKey then
			'Exit VCR early
			exit do
		end if
	loop until combatOver
	if QuickFinish then
		SkipSounds = 0
		drawCombatObjs
		drawOverlay
		screencopy
	end if
	
	if ActiveVCR.Combatants(1).Defeated = 1 then
		playClip(SFX_EXPLODE)
		DestroyedCt(1) += 1
	elseif ActiveVCR.Combatants(1).Defeated = 2 then
		CapturedCt(1) += 1
	end if
	if ActiveVCR.Combatants(2).Defeated = 1 AND PlanBattle = 0 then
		DestroyedCt(2) += 1
		playClip(SFX_EXPLODE)
	elseif ActiveVCR.Combatants(2).Defeated > 0 then
		CapturedCt(2) += 1
	end if
	
	/'
	 ' Combat concluded
	 '
	 ' Process the rest of the starting seeds (building probabilities),
	 ' and allow any key to return to starmap
	 '/
	if InType <> EscKey then
		dim as string OutcomeStr
		if ActiveVCR.Combatants(1).Defeated = 1 AND ActiveVCR.Combatants(2).Defeated = 1 AND PlanBattle = 0 then
			OutcomeStr = "Both combatants destroyed!"
		elseif ActiveVCR.Combatants(1).Defeated = 2 AND ActiveVCR.Combatants(2).Defeated = 2 then
			OutcomeStr = "Both combatants captured!"
		elseif ActiveVCR.Combatants(1).Defeated = 2 AND ActiveVCR.Combatants(2).Defeated = 1 then
			OutcomeStr = "LEFT SIDE captured + RIGHT SIDE destroyed!"
		elseif ActiveVCR.Combatants(1).Defeated = 1 AND ActiveVCR.Combatants(2).Defeated > 0 then
			OutcomeStr = "LEFT SIDE destroyed + RIGHT SIDE captured!"
		elseif ActiveVCR.Combatants(1).Defeated = 1 then
			OutcomeStr = "RIGHT SIDE wins!"
		elseif ActiveVCR.Combatants(2).Defeated = 1 AND PlanBattle = 0 then
			OutcomeStr = "LEFT SIDE wins!"
		elseif ActiveVCR.Combatants(1).Defeated = 2 then
			OutcomeStr = "RIGHT SIDE wins by capture!"
		elseif ActiveVCR.Combatants(2).Defeated > 0 then
			OutcomeStr = "LEFT SIDE wins by capture!"
		else
			OutcomeStr = "Draw! Battle Time expired!"
		end if
		
		gfxString(OutcomeStr,CanvasScreen.Wideth/2-gfxLength(OutcomeStr,4,3,3)/2,270,4,3,3,rgb(255,255,255))
		screencopy
		
		for WhatifSeed as short = 1 to 118
			if WhatifSeed <> BaseSeed then
				QuickCode = quickBattle(ActiveBattle, WhatifSeed)
				
				if (QuickCode AND (1 SHL 0)) then
					DestroyedCt(1) += 1
				elseif (QuickCode AND (1 SHL 1)) then
					CapturedCt(1) += 1
				end if
				
				if (QuickCode AND (1 SHL 2)) then
					if PlanBattle = 0 then
						DestroyedCt(2) += 1
					else
						CapturedCt(2) += 1
					end if
				elseif (QuickCode AND (1 SHL 3)) then
					CapturedCt(2) += 1
				end if
			end if
		next WhatifSeed
		
		if DestroyedCt(1) > 0 then
			OddsChance = DestroyedCt(1)/118*100+1e-6
			OddsDisp = left(str(OddsChance),len(str(int(OddsChance)))+2)+"%"
			
			gfxString("Dead: "+OddsDisp,CanvasScreen.Wideth/2-400-MeterWidth,390,4,3,3,rgb(255,255,255))
		end if
		if CapturedCt(1) > 0 then
			OddsChance = CapturedCt(1)/118*100+1e-6
			OddsDisp = left(str(OddsChance),len(str(int(OddsChance)))+2)+"%"
			
			gfxString("Capt: "+OddsDisp,CanvasScreen.Wideth/2-400-MeterWidth,420,4,3,3,rgb(255,255,255))
		end if
		
		if DestroyedCt(2) > 0 then
			OddsChance = DestroyedCt(2)/118*100+1e-6
			OddsDisp = left(str(OddsChance),len(str(int(OddsChance)))+2)+"%"
			
			gfxString("Dead: "+OddsDisp,CanvasScreen.Wideth/2+250+MeterWidth,390,4,3,3,rgb(255,255,255))
		end if
		if CapturedCt(2) > 0 then
			OddsChance = CapturedCt(2)/118*100+1e-6
			OddsDisp = left(str(OddsChance),len(str(int(OddsChance)))+2)+"%"
			
			gfxString("Capt: "+OddsDisp,CanvasScreen.Wideth/2+250+MeterWidth,420,4,3,3,rgb(255,255,255))
		end if
		if BattleTicks >= 2000 AND DestroyedCt(1) + CapturedCt(1) + DestroyedCt(2) + CapturedCt(2) = 0 then
			dim as string CombatStr = "Time: 100.0%"
			gfxString(CombatStr,CanvasScreen.Wideth/2-gfxLength(CombatStr,4,3,3)/2,300,4,3,3,rgb(255,128,0))
		end if
		
		screencopy
		while inkey <> "":wend
		sleep
		while inkey <> "":wend
	end if
	InType = ""
end sub
