#include "WordWrap.bi"
#include "vbcompat.bi"
#include "NRCommon.bi"

'#DEFINE __VERBOSE_OUTPUT__

sub listGamesUI(FinID as integer)
	createMeter(1, "Converting game list... (ID "+commaSep(FinID)+" done so far)")
	screencopy
end sub

function listGames as integer
	dim as string ImportFile, FailFile, ExportFile, FinalExport, InStream, GameName, GameDate, GameType, NuYear
	dim as integer GameID, TurnNum, YearNum, SeekChar, ByteMax
	
	ImportFile = "raw/listgames.txt"
	FailFile = "raw/listgamesFail.txt"
	ExportFile = "games/ListPrelim.csv"
	FinalExport = "games/List.csv"
	
	ByteMax = FileLen(ImportFile)
	
	open ImportFile for input as #1
	do
		if eof(1) then
			close #1
			InStream = quote("success")+":false"
			exit do
		end if
		line input #1, InStream
	loop until left(InStream,2) = "[{" OR left(InStream,1) = "{"
	close #1
	
	open ExportFile for output as #2
	print #2, quote("ID")+","+quote("Name")+","+quote("Desc")+","+quote("Turn")
	if instr(InStream,quote("success")+":false") then
		'If failed attempt detected, do not proceed any further
		kill(FailFile)
		name(ImportFile,FailFile)
		close #2
		return 1
	else
		do
			SeekChar = instr(SeekChar+1,InStream,quote("name")+":")
			
			if SeekChar > 0 then
				GameName = getJsonStr(InStream,"name",SeekChar)
				GameName = findReplace(GameName,"\"+chr(34),"''")
				GameName = findReplace(GameName,"\/","/")
				if GameName = "" then
					GameName = "{Unidentified Game}"
				end if
				
				GameType = getJsonStr(InStream,"shortdescription",SeekChar)
				TurnNum = getJsonVal(InStream,"turn",SeekChar)
				GameDate = getJsonStr(InStream,"datecreated",SeekChar)
				
				YearNum = (valint(mid(GameDate, instr(4, GameDate, "\/")+2, 4)) - 2011) * 12
				YearNum += valint(left(GameDate,2))
				NuYear = string(4-len(str(YearNum)),"0")+str(YearNum)
				
				GameID = getJsonVal(InStream,"id",SeekChar)
				
				if right(GameName,6) = "Sector" OR right(GameName,6) = "System" then
					GameName = GameName + space(1) + str(NuYear)
				end if
				print #2, ""& GameID;",";quote(GameName);",";quote(GameType);","& TurnNum
				listGamesUI(GameID)
			end if
		loop until SeekChar = 0
	end if
	close #2
	
	#IFDEF __VERBOSE_OUTPUT__
	print "All done."
	#ENDIF
	
	kill(FinalExport)
	name(ExportFile,FinalExport)
	return 0
end function
