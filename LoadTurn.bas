declare sub loadTurnKB(KBCount as integer, Players as ubyte)
declare sub loadTurnUI(Players as ubyte)
declare sub loadTurnTerritory(AmtDone as short)
#include "LoadTurn.bi"
#DEFINE __DEDICATED__
if Command(1) <> "" AND Command(2) <> "" then
	loadTurn(valint(Command(1)),valint(Command(2)))
end if

sub loadTurnKB(MBCount as integer, Players as ubyte)
	'Intentionally null
end sub

sub loadTurnUI(Players as ubyte)
	if Command(3) = "" AND Players > 0 then
		print ".";
	end if
end sub

sub loadTurnTerritory(AmtDone as short)
	if remainder(AmtDone,16) = 0 then
		print ".";
	end if
end sub
