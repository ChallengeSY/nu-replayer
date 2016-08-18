#include "WordWrap.bi"
#include "vbcompat.bi"
dim as string LoadFile, InStream
dim as short ActualTurn, ErrorsFound
dim as short ExpectedGameNum, ActualGameNum

if Command(1) = "" then
	print "USAGE: ./TestTurn {GAMEID}"
	end
else
	ErrorsFound = 0
end if

for ExpectedTurn as short = 1 to 999
	for PID as ubyte = 1 to 30
		ActualTurn = 0
		LoadFile = "raw/"+Command(1)+"/player"+str(PID)+"-turn"+str(ExpectedTurn)+".trn"
		if FileExists(LoadFile) then
			open LoadFile for input as #1
			line input #1, InStream
			close #1
			
			for DID as integer = 1 to len(InStream)
				if mid(InStream,DID,7) = quote("turn")+":" then
					ActualTurn = valint(mid(InStream,DID+7,4))
					exit for
				end if
			next DID
			
			if ActualTurn <> ExpectedTurn then
				ErrorsFound += 1
			end if
		elseif PID = 1 then
			exit for,for
		end if
	next PID
next ExpectedTurn

print "Found "& ErrorsFound;" errors handling game ";Command(1)