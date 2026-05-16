#IFNDEF __FORCE_OFFLINE__
#include "NRArena.bi"

sub fetchArenaFiles
	if OfflineMode then
		for CheckTurn as short = 9999 to 1 step -1
			if FileExists("games/"+str(FeaturedArena)+"/"+str(CheckTurn)+"/Score.csv") then
				TurnNum = CheckTurn
				GameID = FeaturedArena
				exit for
			end if
		next CheckTurn
	else
		dim as integer PreviousArena
		
		if multikey(SC_CONTROL) then
			PreviousArena = FeaturedArena
			FeaturedArena = 0
		end if
		
		if FeaturedArena = 0 then
			do
				line(CanvasScreen.Wideth/2+10,250)-(CanvasScreen.Wideth-6,274),rgb(0,0,0),bf
				gfxstring("Enter Game ID: "+str(FeaturedArena),CanvasScreen.Wideth/2+10,250,5,4,2,rgb(255,255,0))
		
				if InType = EscKey then
					if FeaturedArena > 0 then
						FeaturedArena = 0
					else
						GameID = 0
						exit sub
					end if
				elseif InType >= "0" AND InType <= "9" then
					FeaturedArena = FeaturedArena * 10 + valint(InType)
				elseif InType = chr(8) then
					FeaturedArena = int(FeaturedArena / 10)
				end if
		
				screencopy
				sleep 15
				InType = inkey
			loop until InType = EnterKey
		end if
		
		if FeaturedArena > 0 then
			if getArenaTurn ANDALSO (FileExists("games/"+str(FeaturedArena)+"/"+str(TurnNum)+"/Score.csv") ORELSE _
				((FileExists("raw/"+str(FeaturedArena)+"/player0-turn"+str(TurnNum)+".trn") ORELSE downloadTurns(FeaturedArena, TurnNum)) ANDALSO _
				loadTurn(FeaturedArena, TurnNum, 0, 1) = 0)) then
				GameID = FeaturedArena
			else
				TurnNum = 0
				while inkey <> "":wend
				
				for TID as short = 9999 to 1 step -1
					if FileExists("games/"+str(FeaturedArena)+"/"+str(TID)+"/Score.csv") then
						createMeter(0, "Fall back to existing CSV data? (Y/N)")
						ErrorMsg = ""
						screencopy
						do
							sleep
							InType = inkey
							if left(InType,1) <> chr(255) then
								InType = lcase(InType)
							end if
							if InType = "y" then
								GameID = FeaturedArena
								TurnNum = TID
								exit do
							elseif InType = "n" OR InType = EscKey then
								exit do
							end if
						loop
						
						exit for
					end if
				next TID
			end if
		end if
		
		if FeaturedArena = 0 then 
			FeaturedArena = PreviousArena
		end if
	end if
end sub
#ENDIF
