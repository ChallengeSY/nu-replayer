#include "WordWrap.bi"
#include "vbcompat.bi"
#include "NRCommon.bi"

'#DEFINE __VERBOSE_OUTPUT__

function listGames as integer
	dim as string ImportFile, ExportFile, FinalExport, InStream, GameName, GameDate, GameType, NuYear
	dim as integer GameID, TurnNum, YearNum, SeekChar(2)
	
	ImportFile = "raw/listgames.txt"
	ExportFile = "games/ListPrelim.csv"
	FinalExport = "games/List.csv"
	
	open ImportFile for input as #1
	do
		if eof(1) then
			close #1
			return 1
			exit do
		end if
		line input #1, InStream
	loop until left(InStream,2) = "[{" OR left(InStream,1) = "{"
	close #1
	
	open ExportFile for output as #2
	print #2, quote("ID")+","+quote("Name")+","+quote("Desc")+","+quote("Turn")
	if instr(InStream,quote("success")+":false") = 0 then
		do
			SeekChar(0) = instr(SeekChar(0)+1,InStream,quote("name")+":")
			if SeekChar(0) > 0 then
				SeekChar(1) = SeekChar(0)
				SeekChar(2) = instr(SeekChar(1)+8,InStream,quote(",")+"desc")
				GameName = mid(InStream, SeekChar(1)+8, SeekChar(2)-SeekChar(1)-8)
				GameName = findReplace(GameName,"\"+chr(34),"''")
				GameName = findReplace(GameName,"\/","/")
				if GameName = "" then
					GameName = "{Unidentified Game}"
				end if
				
				SeekChar(1) = instr(SeekChar(0),InStream,quote("shortdescription")+":")
				SeekChar(2) = instr(SeekChar(1)+20,InStream,chr(34))
				GameType = mid(InStream, SeekChar(1)+20, SeekChar(2)-SeekChar(1)-20)

				SeekChar(1) = instr(SeekChar(0),InStream,quote("turn")+":")
				TurnNum = valint(mid(InStream,SeekChar(1)+7,4))

				SeekChar(1) = instr(SeekChar(0),InStream,quote("datecreated")+":")
				GameDate = mid(InStream,SeekChar(1)+15,12)
				
				if right(GameDate,1) = chr(32) then
					GameDate = left(GameDate,len(GameDate)-1)
				elseif mid(GameDate,len(GameDate)-1,1) = chr(32) then
					GameDate = left(GameDate,len(GameDate)-2)
				end if
				
				YearNum = (valint(right(GameDate,4)) - 2011) * 12
				YearNum += valint(left(GameDate,2))
				
				NuYear = string(4-len(str(YearNum)),"0")+str(YearNum)

				SeekChar(1) = instr(SeekChar(0),InStream,quote("id")+":")
				GameID = valint(mid(InStream,SeekChar(1)+5,7))
				
				if right(GameName,6) = "Sector" OR right(GameName,6) = "System" then
					GameName = GameName + space(1) + str(NuYear)
				end if
				print #2, ""& GameID;",";quote(GameName);",";quote(GameType);","& TurnNum
			end if
		loop until SeekChar(0) = 0
	end if
	close #2
	
	#IFDEF __VERBOSE_OUTPUT__
	print "All done."
	#ENDIF
	
	kill(FinalExport)
	name(ExportFile,FinalExport)
	return 0
end function
