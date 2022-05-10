#include "vbcompat.bi"
#include "fbgfx.bi"
#include "CSYMath.bi"
using FB

declare sub loadTurnTerritory(AmtDone as short)
declare sub loadTurnUI(Players as ubyte)
declare sub loadTurnKB(KBCount as integer, Players as ubyte)

#include "LoadTurn.bi"
dim shared as integer MinTurn, MaxTurn, GameNum, TurnNum, TurnsDone, TurnsMax, TargetA, TargetB, TurnDirection
dim shared as string ProgressMeter, GamePath

GameNum = valint(Command(1))
MinTurn = valint(Command(2))
MaxTurn = valint(Command(3))

if GameNum = 0 OR MinTurn = 0 OR MaxTurn = 0 OR MinTurn > MaxTurn then
	open "stdout.txt" for output as #1
	print #1, "Usage:"
	print #1, "MassTurn {GAMENUM} {MINTURN} {MAXTURN} [optional switches]"
	print #1, ""
	print #1, "Optional switches (may be provided in any order):"
	print #1, "--forward: Make the mass converter go forwards, instead of the default backwards"
	print #1, "--skipComp: Make the mass converter skip completed turns"
	print #1, "--skipPart: Make the mass converter skip partially completed turns. Supercedes --skipComp if present"
	close #1
else
	kill("stdout.txt")
	
	open "stdout.txt" for output as #1
	if cmdLine("--forward") then
		print #1, "--forward supplied"
		
		TargetA = MinTurn
		TargetB = MaxTurn
		TurnDirection = 1
	else
		TargetA = MaxTurn
		TargetB = MinTurn
		TurnDirection = -1
	end if
	
	if cmdLine("--skipComp") then
		print #1, "--skipComp supplied"
	end if

	if cmdLine("--skipPart") then
		print #1, "--skipPart supplied"
	end if
	close #1
	
	screenres 320,30,24,2,GFX_NO_SWITCH OR GFX_ALPHA_PRIMITIVES
	screenset 0,1
	windowtitle "Processing Game "+str(GameNum)+"..."
	for TurnNum = TargetA to TargetB step TurnDirection
		GamePath = "games/"+str(GameNum)+"/"+str(TurnNum)+"/"
		
		cls
		if ((FileExists(GamePath+"Score.csv") = 0 OR FileExists(GamePath+"Ion Storms.csv") = 0) AND FileExists(GamePath+"Working") = 0) OR _
			(FileDateTime(GamePath+"Ion Storms.csv") < DataFormat AND FileExists(GamePath+"Working") = 0) OR _
			(FileExists(GamePath+"Working") AND cmdLine("--skipPart") = 0) OR _
			(cmdLine("--skipComp") OR cmdLine("--skipPart")) = 0 then
			
			/'
			 ' Process the turn if any of the following are satisfied:
			 '   The score or starbase files do not exist
			 '   The starbase file is outdated
			 '   The turn is in process (indicated by a WORKING file) and --skipPart is not supplied
			 '   Neither --skipComp nor --skipPart command options are supplied (default)
			 '/
			
			if cmdLine("--forward") then
				TurnsDone = TurnNum - MinTurn
			else
				TurnsDone = MaxTurn - TurnNum
			end if
			TurnsMax = MaxTurn - MinTurn + 1
			line(0,20)-(319,29),rgb(255,255,255),b
			line(1,21)-(1+TurnsDone/TurnsMax*317,28),rgb(255-TurnsDone/TurnsMax*255,TurnsDone/TurnsMax*255,0),bf
			ProgressMeter = "Processing turn "+str(TurnNum)+"..."
			draw string (162-len(ProgressMeter)*4,22), ProgressMeter
			loadTurn(GameNum,TurnNum,0)
		end if
	next
end if

sub loadTurnTerritory(AmtDone as short)
	cls
	line(0,10)-(319,19),rgb(255,255,255),b
	line(1,11)-(1+AmtDone/767*317,18),rgb(255-AmtDone/767*255,AmtDone/767*255,0),bf

	ProgressMeter = str(int(AmtDone/767*100))+"% territory done"
	draw string (162-len(ProgressMeter)*4,12), ProgressMeter
	screencopy
	sleep 15
end sub

sub loadTurnUI(Players as ubyte)
	dim as ubyte Detected
	for PID as ubyte = 1 to 30
		if FileExists("raw/"+str(GameNum)+"/player"+str(PID)+"-turn"+str(TurnNum)+".trn") = 0 AND _
			FileExists("raw/"+str(GameNum)+"/"+str(TurnNum)+"/loadturn"+str(PID)) = 0 AND _
			FileExists("raw/"+str(GameNum)+"/"+str(TurnNum)+"/loadturn"+str(PID)+".txt") = 0 then
			Detected = PID - 1
			exit for
		end if
	next PID
	
	line(0,10)-(319,19),rgb(0,0,0),bf
	line(0,10)-(319,19),rgb(255,255,255),b
	line(1,11)-(1+Players/Detected*317,18),rgb(255-Players/Detected*255,Players/Detected*255,0),bf
	ProgressMeter = str(Players)+" / "+str(Detected)+" players done"
	draw string (162-len(ProgressMeter)*4,12), ProgressMeter
	screencopy
	sleep 15
end sub

sub loadTurnKB(KBCount as integer, Players as ubyte)
	dim as integer FileSize
	if timer > KBUpdate + 2 then
		KBUpdate = timer
		FileSize = int(FileLen("raw/"+str(GameNum)+"/player"+str(Players)+"-turn"+str(TurnNum)+".trn")/1e3)
		line(0,1)-(319,9),rgb(0,0,0),bf
		if FileSize > 0 then
			draw string (0,1), str(KBCount)+"/"+str(FileSize)+" KB done for player "+str(Players)
		else
			draw string (0,1), str(KBCount)+"/??? KB done for player "+str(Players)
		end if
		screencopy
		
		if inkey = chr(255,107) then
			kill("games/"+str(GameNum)+"/"+str(TurnNum)+"/Working")
			end 1
		end if
	end if
end sub
