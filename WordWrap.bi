#IFNDEF __WORDWRAP_BI__
#DEFINE __WORDWRAP_BI__
#include "CSYMath.bi"
function quote(InParam as string) as string
	return chr(34)+InParam+chr(34)
end function

function word_wrap(Text as string) as string
	dim as ushort RefChar, RaisedChar, TotalRaised, Cap
	dim as string OutText = Text
	Cap = loWord(width)
	for WID as ushort = 1 to len(Text)
		if mid(Text,WID,1) = chr(32) then
			RefChar = WID
		end if
		if mid(Text,WID,2) = "\n" then
			RefChar = WID
			if RefChar > 0 then
				RaisedChar = Cap - remainder(RefChar+TotalRaised,Cap) - 1
			else
				RaisedChar = 0
			end if
			
			OutText = left(OutText,RefChar+TotalRaised-1)+space(RaisedChar)+right(OutText,len(OutText)-TotalRaised-RefChar+1)
			TotalRaised += RaisedChar
			RefChar = 0
		elseif remainder(WID+TotalRaised,Cap) = 0 then
			if RefChar > 0 then
				RaisedChar = Cap - remainder(RefChar+TotalRaised,Cap)
			else
				RaisedChar = 0
			end if
			if RaisedChar = Cap then
				RaisedChar = 0
			end if

			OutText = left(OutText,RefChar+TotalRaised-1)+space(RaisedChar)+right(OutText,len(OutText)-TotalRaised-RefChar+1)
			TotalRaised += RaisedChar
			RefChar = 0
		end if
	next WID
	for WID as ushort = 1 to len(OutText)
		if mid(OutText,WID,2) = "\n" then
			OutText = left(OutText,WID-1) + "  " + right(OutText,len(OutText)-WID-1)
		end if
	next WID
	
	return OutText
end function
#ENDIF