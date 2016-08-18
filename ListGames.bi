#include "WordWrap.bi"
#include "vbcompat.bi"
#include "NRCommon.bi"

'#DEFINE __VERBOSE_OUTPUT__

function listGames as integer
	dim as string ImportFile, ExportFile, FinalExport, InStream, GameName, GameDate, GameType, NuYear
	dim as integer GameID, TurnNum, YearNum
	
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
	loop until left(InStream,2) = "[{" OR left(InStream,2) = "{"
	close #1
	
	open ExportFile for output as #2
	print #2, quote("ID")+","+quote("Name")+","+quote("Desc")+","+quote("Turn")
	for DID as integer = 1 to len(InStream)
		if mid(InStream,DID,15) = quote("success")+":false" then
			close #2
			kill(ExportFile)
			return 1
		end if
		if mid(InStream,DID,6) = quote("name") then
			for GameLen as short = 2 to 500
				GameName = mid(InStream,DID+8,GameLen)
				if right(GameName,1) = chr(34) then
					GameName = findReplace(left(GameName,GameLen-1),",","&")
					exit for
				end if
			next GameLen
			
			if GameName = chr(34)+"&" then
				GameName = "{Unidentified Game}"
			end if
		end if
		if mid(InStream,DID,18) = quote("shortdescription") then
			for GameLen as short = 1 to 500
				GameType = mid(InStream,DID+20,GameLen)
				if right(GameType,1) = chr(34) then
					GameType = left(GameType,GameLen-1)
					exit for
				end if
			next GameLen
		end if
		if mid(InStream,DID,6) = quote("turn") then
			TurnNum = valint(mid(InStream,DID+7,4))
		end if
		if mid(InStream,DID,13) = quote("datecreated") then
			GameDate = mid(InStream,DID+15,12)
			
			if right(GameDate,1) = chr(32) then
				GameDate = left(GameDate,len(GameDate)-1)
			elseif mid(GameDate,len(GameDate)-1,1) = chr(32) then
				GameDate = left(GameDate,len(GameDate)-2)
			end if
			
			YearNum = (valint(right(GameDate,4)) - 2011) * 12
			YearNum += valint(left(GameDate,2))
			
			NuYear = string(4-len(str(YearNum)),"0")+str(YearNum)
		end if
		if mid(InStream,DID,4) = quote("id") then
			GameID = valint(mid(InStream,DID+5,7))
		end if
		if mid(InStream,DID,1) = "}" then
			if right(GameName,6) = "Sector" OR right(GameName,6) = "System" then
				GameName = GameName + space(1) + str(NuYear)
			end if
			print #2, ""& GameID;",";quote(GameName);",";quote(GameType);","& TurnNum
		end if
	next
	close #2
	
	#IFDEF __VERBOSE_OUTPUT__
	print "All done."
	#ENDIF
	
	kill(FinalExport)
	name(ExportFile,FinalExport)
	return 0
end function
