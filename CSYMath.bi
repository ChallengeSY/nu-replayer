#IFNDEF __CSY_MATH_BI__
#DEFINE __CSY_MATH_BI__
const pi = 3.14159265358979323846

function ceil(Byval Param1 as double) as longint
	'Always rounds up
	return int(Param1 + .999999999)
end function

function remainder(Byval Param1 as double, Byval Param2 as double) as double
	'Returns the remainder of a division.
	if Param2 = 0 then
		return 1e+300
	else
		return Param1-(int(Param1/Param2)*Param2)
	end if
end function

function extended_log(Byval Param1 as double, Byval Param2 as double) as double
	'Allows logarithms of any base to be used.
	return (log(Param1)/log(Param2))
end function

function commaSep(InValue as longint) as string
	dim as string FullStr
	dim as byte ExtraCommas
	
	FullStr = str(InValue)
	if InValue >= 1000 then
		for KID as ubyte = 1 to len(str(InValue))
			if remainder(KID,3) = remainder(len(str(InValue)),3) AND KID <= len(str(InValue)) - 3 then
				FullStr = left(FullStr,KID+ExtraCommas)+","+right(FullStr,len(FullStr)-KID-ExtraCommas)
				ExtraCommas += 1
			end if
		next KID
	end if
	
	return FullStr
end function

function degtorad(Amount as double) as double
	return Amount*pi/180
end function
function radtodeg(Amount as double) as double
	return Amount*180/pi
end function

function irandom(Minimum as integer, Maximum as integer) as integer
	return int(rnd * ((Maximum - Minimum) + 1 - 1e-100)) + Minimum
end function

#IFNDEF max
function max(ValueA as double, ValueB as double) as double
	return iif(ValueA > ValueB,ValueA,ValueB) 
end function

function min(ValueA as double, ValueB as double) as double
	return iif(ValueA > ValueB,ValueB,ValueA) 
end function
#ENDIF

function convert_ip(InIP as integer) as string
	dim as string LongString, ShortString(4), OutString
	LongString = str(hex(InIP,8))

	for ID as ubyte = 1 to 4
		ShortString(ID) = mid(LongString,ID*2-1,2)
		if ID > 1 then 
			OutString += "."
		end if
		OutString += str(valint("&h"+ShortString(ID)))
	next ID
	
	return OutString
end function
#ENDIF