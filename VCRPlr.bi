type TorpPiece
	Position as short
	Hit as byte
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
	Damage as integer
	Crew as short
	Mass as short
	RaceID as byte
	
	BeamKillX as byte
	BeamChargeX as byte
	TorpChargeX as byte
	TorpMissChance as byte
	CrewDefense as short
	
	TorpAmmo as short
	Fighters as short
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
	Seed as short
	XLoc as short
	YLoc as short
	Battletype as byte
	LeftOwner as byte
	RightOwner as byte
	Turn as short
	InternalID as integer
	Combatants(2) as CombatPiece
end type

dim shared as VCRobj VCRbattles(MetaLimit), ActiveVCR, ResetVCR
const NumSeeds = 119
const DeadAmmo = -9999

dim shared as byte PlanBattle
dim shared as short ActiveSeed, BattleTicks, Distance

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
	ActiveSeed = ActiveSeed mod NumSeeds + SkipCount
end sub

sub setupBattle(ByRef BattleSetup as VCRobj)
	dim as byte PlacementMulti(1 to 2) => {-1, 1}

	'Copy the selected battle to a working object
	ActiveVCR = BattleSetup
	
	'Battles start at 54000/58000 km, depending on whether a planet is involved
	PlanBattle = abs(sgn(BattleSetup.Battletype))
	Distance = 580 - PlanBattle * 40 
	
	BattleSetup.Combatants(1).ShipPos = -Distance/2
	BattleSetup.Combatants(2).ShipPos = Distance/2
	
	for PID as byte = 1 to 2
		with BattleSetup.Combatants(PID)
			.ShipPos = Distance/2*PlacementMulti(PID)
			
			'Fully shielded and Horwasp ships start (nearly) fully charged
			if .Shield >= 100 OR .RaceID = 12 then
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
		end with
	next PID
	
	ActiveSeed = BattleSetup.Seed
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
			dim as short CrewLoss = round(CrewKill * (1 - min((100 - .CrewDefense),100)/100))
			
			.Crew = max(0,-round(80 * CrewLoss / (.Mass + 1) - .Crew)) 
		end if
		.Shield = WorkShield
	end with
end sub


sub shootDownFighter(HostPiece as byte, HostBeam as byte)
	dim as short ClosestFtr, ClosestDist = 999, CurrDist
	
	with ActiveVCR
		for FID as byte = 1 to MaxFighters
			CurrDist = abs(.Combatants(HostPiece).ShipPos - .Combatants(int(3-HostPiece)).FtrCraft(FID).Position)
			if CurrDist < ClosestDist then
				'Closest fighter gets priority
				ClosestDist = CurrDist
				ClosestFtr = FID
			end if
		next FID
	
		if ClosestFtr > 0 then
			'Beam shoots down fighter, discharging it
			.Combatants(HostPiece).BeamBanks(HostBeam) = 0
			.Combatants(int(3-HostPiece)).FtrCraft(ClosestFtr).Position = DeadAmmo
			
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
	
	with ActiveVCR.Combatants(PieceID) 
		for BID as byte = 1 to .BeamCt
			ShootRoll = rollSeededDice(20)
			if .BeamBanks(BID) > 50 AND ShootRoll < 7 then
				dim as short CalcBlast, CalcCrewKill
				
				CalcBlast = round(.BeamBanks(BID) / 100 * Beams(.BeamID).Blast)
				CalcCrewKill = round(.BeamBanks(BID) / 100 * Beams(.BeamID).CrewKill) * .BeamKillX
				
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
			.Hit = HitScored
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
					.TorpShell(AID).Position += 20 * (1.5 - PID)
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
						'Damage the opposing ship
						if PeerPiece.CrewDefense <= 100 ORELSE rollSeededDice(100) > PeerPiece.CrewDefense - 100 then
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
						'Damage the opposing ship
						if PeerPiece.CrewDefense <= 100 ORELSE rollSeededDice(100) > PeerPiece.CrewDefense - 100 then
							damageShip(2,2,2)
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
								.Combatants(2).FtrCraft(RFtr).Reverse = -1
							elseif .Combatants(2).FtrCraft(RFtr).Reverse = 0 then
								/'
								 ' Left side fighters get a huge advantage,
								 ' because they can still shoot even when destroyed in the very same tick.
								 '
								 ' This does not hold true to right side fighters.
								 '/
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
					.BeamBanks(BeamID) += 1
				end if 
			next BeamID 
		end with
	next PID
end sub

sub checkPieces
	dim as short DamageThresh(1 to 2) => {100, 100}
	
	for PID as byte = 1 to 2
		with ActiveVCR.Combatants(PID)
			if .RaceID = 2 AND PID + PlanBattle < 3 then
				'Lizard Crew Bonus
				DamageThresh(PID) = 151
			end if
			
			if .Crew <= 0 AND PlanBattle = 0 then
				'Ship has been captured
				.Defeated = 2
			end if
			
			if .Damage >= DamageThresh(PID) OR (.Damage >= 100 AND .Crew <= 0) OR _
				(PlanBattle AND (.Damage >= 100 OR .Crew <= 0)) then
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

function combatOver as byte
	return BattleTicks >= 2000 OR ActiveVCR.Combatants(1).Defeated OR ActiveVCR.Combatants(2).Defeated
end function


sub watchBattle(ByRef ActiveBattle as VCRobj)
	dim as byte VCRspeed = 5
	
	setupBattle(ActiveBattle)
	
	do
		cls
		playVCRcycle
		screencopy
		sleep (11-VCRspeed)*30,1
		InType = inkey
		
		if InType >= "1" AND InType <= "9" then
			'Adjust playback speed
			VCRspeed = valint(InType)
		elseif InType = chr(32) then
			'Pause playback
			sleep
		elseif InType = EscKey then
			'Exit VCR early
			exit do
		end if
	loop until combatOver
	
	'Combat concluded, allow any key to return to starmap
	if InType <> EscKey then
		screencopy
		sleep
	end if
	InType = ""
end sub
