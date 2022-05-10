#IFNDEF __NR_COMMON__
#DEFINE __NR_COMMON__ 'Protects Nu Replayer from having this duplicated
const LimitObjs = 1999 'Defines the maximum number of planets or ships
const DataFormat = 44682

function findReplace(BaseTxt as string, InChar as string, OutChar as string) as string
	'Automatically replaces characters as appropriate.
	dim as string WorkTxt = BaseTxt
	if len(InChar) = len(OutChar) then
		for LID as ushort = 1 to len(WorkTxt)
			if mid(WorkTxt,LID,len(InChar)) = InChar then
				WorkTxt = left(WorkTxt,LID-1) + OutChar + right(WorkTxt,len(WorkTxt)-LID)
				continue for
			end if
		next LID
	end if
	return WorkTxt
end function
#ENDIF