declare sub printGfx(Plot as string, TLX as uinteger, TLY as uinteger, Size as ubyte, Coloring as uinteger)

#DEFINE RGBA_RED 0
#DEFINE RGBA_GREEN 1
#DEFINE RGBA_BLUE 2
#DEFINE RGBA_ALPHA 3

function retrivePrimary(IColor as uinteger, Spectrum as ubyte) as ubyte
	select case Spectrum
		case RGBA_RED
			return cuint(IColor) Shr 16 And 255
		case RGBA_GREEN
			return cuint(IColor) Shr  8 And 255
		case RGBA_BLUE
			return cuint(IColor)        And 255
		case RGBA_ALPHA
			return cuint(IColor) Shr 24
	end select
end function

function gradColoring(ColoringA as uinteger, ColoringB as uinteger, Transition as double) as uinteger
	return rgba(retrivePrimary(ColoringA,RGBA_RED)*(1-Transition) + retrivePrimary(ColoringB,RGBA_RED)*Transition,_
		retrivePrimary(ColoringA,RGBA_GREEN)*(1-Transition) + retrivePrimary(ColoringB,RGBA_GREEN)*Transition,_
		retrivePrimary(ColoringA,RGBA_BLUE)*(1-Transition) + retrivePrimary(ColoringB,RGBA_BLUE)*Transition,_
		retrivePrimary(ColoringA,RGBA_ALPHA)*(1-Transition) + retrivePrimary(ColoringB,RGBA_ALPHA)*Transition)
end function

sub gfxString(Text as string, TLX as uinteger, TLY as uinteger, BSize as ubyte, LSize as ubyte, Kerning as ubyte, ColoringA as uinteger, ColoringB as uinteger = 0)
	dim as ushort ChrID, AddedSpacing = 0, DeltaLen
	dim as uinteger ApplyColor
	dim as double Progress
	dim as string PrintChr
	
	for ChrID = 1 to len(Text)
		PrintChr = mid(Text,ChrID,1)
		Progress = (ChrID-1)/(len(Text)-1)
		if ColoringB = 0 then
			ApplyColor = ColoringA
		else
			ApplyColor = gradColoring(ColoringA, ColoringB, Progress)
		end if
		
		if lcase(PrintChr) = PrintChr AND (PrintChr < "0" OR PrintChr > "9") AND PrintChr <> "(" AND PrintChr <> ")" then
			printGfx(PrintChr,TLX+((LSize*3)+Kerning)*(ChrID-1)+AddedSpacing,TLY+(5*(BSize-LSize)),LSize,ApplyColor)
		else
			printGfx(PrintChr,TLX+((LSize*3)+Kerning)*(ChrID-1)+AddedSpacing,TLY,BSize,ApplyColor)
			AddedSpacing += (BSize-LSize)*3
		end if
	next
end sub

function gfxLength(Text as string, BSize as ubyte, LSize as ubyte, Kerning as ubyte) as integer
	dim as integer ChrID, Padding = -Kerning
	dim as string PrintChr
	for ChrID = 1 to len(Text)
		PrintChr = mid(Text,ChrID,1)
		if lcase(PrintChr) = PrintChr AND (PrintChr < "0" OR PrintChr > "9") then
			Padding += (LSize*3)+Kerning
		else
			Padding += (BSize*3)+Kerning
		end if
	next ChrID
	
	return Padding
end function

sub printGfx(Plot as string, TLX as uinteger, TLY as uinteger, Size as ubyte, Coloring as uinteger)
	Plot = lcase(Plot)
	select case Plot
		case "a"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*2)-1,TLY+(Size*3)-1),Coloring,bf
		case "b"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*1))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*3))-(TLX+(Size*3)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*2)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*2),TLY+(Size*0)+Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*0)+Pint),Coloring
					
				if Pint < Size/2 then
					line(TLX+(Size*2),TLY+(Size*2)+Pint)-_
						(TLX+(Size*3)-1-Pint,TLY+(Size*2)+Pint),Coloring
				else
					line(TLX+(Size*2),TLY+(Size*2)+Pint)-_
						(TLX+(Size*2)+Pint,TLY+(Size*2)+Pint),Coloring
				end if
				
				line(TLX+(Size*2),TLY+(Size*5)-1-Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*5)-1-Pint),Coloring
			next
		case "c"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "d"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*1))-(TLX+(Size*3)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*2),TLY+(Size*0)+Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*0)+Pint),Coloring
				
				line(TLX+(Size*1)+Pint,TLY+(Size*1)+Pint)-_
					(TLX+(Size*2)-1,TLY+(Size*1)+Pint),Coloring
					
				line(TLX+(Size*1)+Pint,TLY+(Size*4)-1-Pint)-_
					(TLX+(Size*2)-1,TLY+(Size*4)-1-Pint),Coloring
					
				line(TLX+(Size*2),TLY+(Size*5)-1-Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*5)-1-Pint),Coloring
			next
		case "e"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "f"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
		case "g"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
		case "h"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*2)-1,TLY+(Size*3)-1),Coloring,bf
		case "i"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "j"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
		case "k"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*2),TLY+(Size*3)+Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*3)+Pint),Coloring
				
				line(TLX+(Size*1)+Pint,TLY+(Size*4)+Pint)-_
					(TLX+(Size*2)-1,TLY+(Size*4)+Pint),Coloring
					
				line(TLX+(Size*1)+Pint,TLY+(Size*2)-1-Pint)-_
					(TLX+(Size*2)-1,TLY+(Size*2)-1-Pint),Coloring
					
				line(TLX+(Size*2),TLY+(Size*3)-1-Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*3)-1-Pint),Coloring
			next
		case "l"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "m"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			for Pint as ubyte = 0 to Size - 1
				if Pint < Size/2 then
					line(TLX+(Size*1)+Pint,TLY+(Size*0)+1+Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*2)+Pint),Coloring
				else
					line(TLX+(Size*1)+Pint,TLY+(Size*1)-Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*3)-1-Pint),Coloring
				end if
			next
		case "n"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*1)+Pint,TLY+(Size*0.75)+1+Pint)-_
					(TLX+(Size*1)+Pint,TLY+(Size*2.75)+Pint),Coloring
			next
		case "o", "0"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
		case "p"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*2)-1,TLY+(Size*3)-1),Coloring,bf
		case "q"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*3))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
		case "r"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*2),TLY+(Size*3)+Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*3)+Pint),Coloring
				
				line(TLX+(Size*1)+Pint,TLY+(Size*4)+Pint)-_
					(TLX+(Size*2)-1,TLY+(Size*4)+Pint),Coloring
			next
		case "s", "5"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*1))-(TLX+(Size*1)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*3))-(TLX+(Size*3)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "t"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
		case "u"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
		case "v"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				if Pint < Size - 1 then
					line(TLX+(Size*0)+Pint+1,TLY+(Size*4)+Pint)-_
						(TLX+(Size*1)-1,TLY+(Size*4)+Pint),Coloring
				end if
				
				if Pint < Size/2 then
					line(TLX+(Size*1)+Pint,TLY+(Size*3.5)-0.5+Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*4)-1),Coloring
				else
					line(TLX+(Size*1)+Pint,TLY+(Size*4.5)-1.5-Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*4)-1),Coloring
				end if
				
				if Pint > 0 then
					line(TLX+(Size*2),TLY+(Size*5)-1-Pint)-_
						(TLX+(Size*2)+Pint-1,TLY+(Size*5)-1-Pint),Coloring
				end if
			next
		case "w"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			'line(TLX+(Size*1),TLY+(Size*3))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf

			for Pint as ubyte = 0 to Size - 1
				if Pint >= Size/2 then
					line(TLX+(Size*1)+Pint,TLY+(Size*2)+1+Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*4)+Pint-1),Coloring
				else
					line(TLX+(Size*1)+Pint,TLY+(Size*3)-Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*5)-2-Pint),Coloring
				end if
			next
		case "x"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*2)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*3))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*3))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				if Pint < Size/2 then
					line(TLX+(Size*1)+Pint,TLY+(Size*1.5)-0.5+Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*2)-1),Coloring

					line(TLX+(Size*2),TLY+(Size*2)+Pint)-_
						(TLX+(Size*2.5)-Pint,TLY+(Size*2)+Pint),Coloring
						
					line(TLX+(Size*1)+Pint,TLY+(Size*3))-_
						(TLX+(Size*1)+Pint,TLY+(Size*3.5)-1-Pint),Coloring

					line(TLX+(Size*0.5)-0.5+Pint,TLY+(Size*2)+Pint)-_
						(TLX+(Size*1)-1,TLY+(Size*2)+Pint),Coloring
				else
					line(TLX+(Size*1)+Pint,TLY+(Size*2.5)-1.5-Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*2)-1),Coloring

					line(TLX+(Size*2),TLY+(Size*2)+Pint)-_
						(TLX+(Size*1.5)+1+Pint,TLY+(Size*2)+Pint),Coloring
						
					line(TLX+(Size*1)+Pint,TLY+(Size*3))-_
						(TLX+(Size*1)+Pint,TLY+(Size*2.5)+Pint),Coloring

					line(TLX+(Size*1.5)-1.5-Pint,TLY+(Size*2)+Pint)-_
						(TLX+(Size*1)-1,TLY+(Size*2)+Pint),Coloring
				end if
			next
		case "y"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*0)+Pint,TLY+(Size*2)+Pint)-_
					(TLX+(Size*1)-1,TLY+(Size*2)+Pint),Coloring
				
				if Pint < Size/2 then
					line(TLX+(Size*1)+Pint,TLY+(Size*1.5)-0.5+Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*2)-1),Coloring
				else
					line(TLX+(Size*1)+Pint,TLY+(Size*2.5)-1.5-Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*2)-1),Coloring
				end if
				
				line(TLX+(Size*2),TLY+(Size*3)-1-Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*3)-1-Pint),Coloring
			next
		case "z"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*0)+Pint,TLY+(Size*4)-1)-_
					(TLX+(Size*2)+Pint,TLY+(Size*1)),Coloring
			next
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "1"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "2"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*1))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*3))-(TLX+(Size*1)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "3"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*1))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*3))-(TLX+(Size*3)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "4"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*3))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
		case "6"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*3))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
		case "^"
			for Pint as ubyte = 0 to Size
				line(TLX+(Size*0)+Pint,TLY+(Size*1)-Pint)-(TLX+(Size*1)-1+Pint,TLY+(Size*2)-1-Pint),Coloring,bf
				line(TLX+(Size*2)-Pint,TLY+(Size*1)-Pint)-(TLX+(Size*3)-1-Pint,TLY+(Size*2)-1-Pint),Coloring,bf
			next
		case "7"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*1))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "8"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*1))-(TLX+(Size*1)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*1))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*3))-(TLX+(Size*1)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*3))-(TLX+(Size*3)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "*"
			for Pint as ubyte = 0 to Size
				line(TLX+(Size*0)+Pint,TLY+(Size*0)+Pint)-(TLX+(Size*1)-1+Pint,TLY+(Size*1)-1+Pint),Coloring,bf
				line(TLX+(Size*2)-Pint,TLY+(Size*0)+Pint)-(TLX+(Size*3)-1-Pint,TLY+(Size*1)-1+Pint),Coloring,bf
				line(TLX+(Size*0)+Pint,TLY+(Size*2)-Pint)-(TLX+(Size*1)-1+Pint,TLY+(Size*3)-1-Pint),Coloring,bf
				line(TLX+(Size*2)-Pint,TLY+(Size*2)-Pint)-(TLX+(Size*3)-1-Pint,TLY+(Size*3)-1-Pint),Coloring,bf
			next
		case "9"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*1))-(TLX+(Size*1)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*1))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*3))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "("
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*2),TLY+(Size*3)+Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*3)+Pint),Coloring
				
				line(TLX+(Size*1)+Pint,TLY+(Size*4)+Pint)-_
					(TLX+(Size*2)-1,TLY+(Size*4)+Pint),Coloring
					
				line(TLX+(Size*1)+Pint,TLY+(Size*1)-1-Pint)-_
					(TLX+(Size*2)-1,TLY+(Size*1)-1-Pint),Coloring
					
				line(TLX+(Size*2),TLY+(Size*2)-1-Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*2)-1-Pint),Coloring
			next
		case ")"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*1),TLY+(Size*0)+Pint)-_
					(TLX+(Size*1)+Pint,TLY+(Size*0)+Pint),Coloring
				
				line(TLX+(Size*0)+Pint,TLY+(Size*1)+Pint)-_
					(TLX+(Size*1)-1,TLY+(Size*1)+Pint),Coloring
					
				line(TLX+(Size*0)+Pint,TLY+(Size*4)-1-Pint)-_
					(TLX+(Size*1)-1,TLY+(Size*4)-1-Pint),Coloring
					
				line(TLX+(Size*1),TLY+(Size*5)-1-Pint)-_
					(TLX+(Size*1)+Pint,TLY+(Size*5)-1-Pint),Coloring
			next
		case "["
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "]"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
		case "."
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
		case ":"
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*3))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
		case ";"
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*3))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
		case "!"
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
		case "?"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*1))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*2)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
		case "/", "%"
			if Plot = "%" then
				line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*1)-1),Coloring,bf
				line(TLX+(Size*2),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			end if
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*0)+Pint,TLY+(Size*5)-1)-_
					(TLX+(Size*2)+Pint,TLY+(Size*0)),Coloring
			next
		case "\"
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*2)+Pint,TLY+(Size*5)-1)-_
					(TLX+(Size*0)+Pint,TLY+(Size*0)),Coloring
			next
		case "-"
			line(TLX+(Size*0),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
		case "_"
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
		case "+"
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*3))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
		case "="
			line(TLX+(Size*0),TLY+(Size*1))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*3))-(TLX+(Size*3)-1,TLY+(Size*4)-1),Coloring,bf
		case "'"
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*2)-1),Coloring,bf
		case chr(34)
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
		case ","
			line(TLX+(Size*1),TLY+(Size*3))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
		case "<"
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*2))-(TLX+(Size*1)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*3))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*2),TLY+(Size*3)+Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*3)+Pint),Coloring
				
				line(TLX+(Size*1)+Pint,TLY+(Size*4)+Pint)-_
					(TLX+(Size*2)-1,TLY+(Size*4)+Pint),Coloring
					
				line(TLX+(Size*1)+Pint,TLY+(Size*1)-1-Pint)-_
					(TLX+(Size*2)-1,TLY+(Size*1)-1-Pint),Coloring
					
				line(TLX+(Size*2),TLY+(Size*2)-1-Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*2)-1-Pint),Coloring
				
				line(TLX+(Size*0)+Pint,TLY+(Size*3)+Pint)-_
					(TLX+(Size*1)-1,TLY+(Size*3)+Pint),Coloring
					
				line(TLX+(Size*0)+Pint,TLY+(Size*2)-1-Pint)-_
					(TLX+(Size*1)-1,TLY+(Size*2)-1-Pint),Coloring

				if Pint < Size/2 then
					line(TLX+(Size*1),TLY+(Size*2)+Pint)-_
						(TLX+(Size*2)-1-Pint,TLY+(Size*2)+Pint),Coloring
				else
					line(TLX+(Size*1),TLY+(Size*2)+Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*2)+Pint),Coloring
				end if
			next
		case ">"
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*3))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			
			for Pint as ubyte = 0 to Size - 1
				line(TLX+(Size*1),TLY+(Size*0)+Pint)-_
					(TLX+(Size*1)+Pint,TLY+(Size*0)+Pint),Coloring
				
				line(TLX+(Size*0)+Pint,TLY+(Size*1)+Pint)-_
					(TLX+(Size*1)-1,TLY+(Size*1)+Pint),Coloring
					
				line(TLX+(Size*0)+Pint,TLY+(Size*4)-1-Pint)-_
					(TLX+(Size*1)-1,TLY+(Size*4)-1-Pint),Coloring
					
				line(TLX+(Size*1),TLY+(Size*5)-1-Pint)-_
					(TLX+(Size*1)+Pint,TLY+(Size*5)-1-Pint),Coloring

				line(TLX+(Size*2),TLY+(Size*1)+Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*1)+Pint),Coloring

				line(TLX+(Size*2),TLY+(Size*4)-1-Pint)-_
					(TLX+(Size*2)+Pint,TLY+(Size*4)-1-Pint),Coloring

				if Pint < Size/2 then
					line(TLX+(Size*2)-1,TLY+(Size*2)+Pint)-_
						(TLX+(Size*1)+Pint,TLY+(Size*2)+Pint),Coloring
				else
					line(TLX+(Size*2)-1,TLY+(Size*2)+Pint)-_
						(TLX+(Size*2)-1-Pint,TLY+(Size*2)+Pint),Coloring
				end if
			next
		case chr(219)
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
	end select
end sub
/'
			line(TLX+(Size*0),TLY+(Size*0))-(TLX+(Size*1)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*0))-(TLX+(Size*2)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*0))-(TLX+(Size*3)-1,TLY+(Size*1)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*1))-(TLX+(Size*1)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*1))-(TLX+(Size*2)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*1))-(TLX+(Size*3)-1,TLY+(Size*2)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*2))-(TLX+(Size*1)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*2))-(TLX+(Size*2)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*2))-(TLX+(Size*3)-1,TLY+(Size*3)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*3))-(TLX+(Size*1)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*3))-(TLX+(Size*2)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*3))-(TLX+(Size*3)-1,TLY+(Size*4)-1),Coloring,bf
			line(TLX+(Size*0),TLY+(Size*4))-(TLX+(Size*1)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*1),TLY+(Size*4))-(TLX+(Size*2)-1,TLY+(Size*5)-1),Coloring,bf
			line(TLX+(Size*2),TLY+(Size*4))-(TLX+(Size*3)-1,TLY+(Size*5)-1),Coloring,bf
'/