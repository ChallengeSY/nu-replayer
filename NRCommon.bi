#IFNDEF __NR_COMMON__
#DEFINE __NR_COMMON__
const LimitObjs = 1999 'Defines the maximum number of planets or ships
const DataFormat = 44682

function findReplace(BaseTxt as string, InChar as string, OutChar as string) as string
	'Automatically replaces characters as appropriate.
	dim as string WorkTxt = BaseTxt
	dim as integer SeekChar
	do
		SeekChar = instr(SeekChar+1, WorkTxt, InChar)
		if SeekChar > 0 then
			WorkTxt = left(WorkTxt,SeekChar-1) + OutChar + right(WorkTxt,len(WorkTxt)-SeekChar-len(InChar)+1)
			SeekChar = SeekChar - len(InChar) + len(OutChar)
		end if 
	loop until SeekChar = 0
	return WorkTxt
end function
#ENDIF
