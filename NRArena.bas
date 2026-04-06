#IFNDEF __FORCE_OFFLINE__
#include "NRArena.bi"

sub fetchArenaFiles
	dim as integer ActiveTurn = getArenaTurn
	
	if FileExists("games/"+str(FeaturedArena)+"/"+str(ActiveTurn)+"/Score.csv") ORELSE _
		((FileExists("raw/"+str(FeaturedArena)+"/player0-turn"+str(ActiveTurn)+".trn") ORELSE downloadLastTurns(FeaturedArena, 1) <> 0) ANDALSO _
		loadTurn(FeaturedArena, ActiveTurn, 0, 1) = 0) then
		GameID = FeaturedArena
		TurnNum = ActiveTurn
	end if
end sub
#ENDIF
