'' .zip unpacking using libzip
#include once "zip.bi"
Dim Shared As String extraDirs 

Sub createParentDirs(ByVal file As ZString Ptr)
	'' Given a path like this:
	''	foo/bar/baz/file.ext
	'' Do these mkdir()'s:
	''	foo
	''	foo/bar
	''	foo/bar/baz
	Dim As UByte Ptr p = file
	Do
		Select Case (*p)
			Case Asc("/")
			*p = 0
			MkDir(*file)
			*p = Asc("/")
			Case 0
			Exit Do
		End Select
		p += 1
	Loop
End Sub

'' Asks libzip for information on file number 'i' in the .zip file,
'' and then extracts it, while creating directories as needed.
Function unpackZipFile(ByVal zip As zip_t Ptr, ByVal i As Integer) As Integer
	#define BUFFER_SIZE (1024 * 512)
	Static As UByte chunk(0 To (BUFFER_SIZE - 1))
	#define buffer (@chunk(0))

	'' Retrieve the filename.
	Dim As String filename = *zip_get_name(zip, i, 0)
	/'
	Print "file: " & filename & ", ";

	'' Retrieve the file size via a zip_stat().
	Dim As zip_stat stat
	If (zip_stat_index(zip, i, 0, @stat)) Then
		Print "zip_stat() failed"
		Return
	End If

	If ((stat.valid And ZIP_STAT_SIZE) = 0) Then
		Print "could not retrieve file size from zip_stat()"
		Return
	End If

	Print stat.size & " bytes"
	'/

	'' Create directories if needed
	createParentDirs(extraDirs+filename)

	'' Write out the file
	Dim As Integer fo = FreeFile()
	If (Open(extraDirs+filename, For Binary, Access Write, As #fo)) Then
		' could not open output file"
		Return 1
	End If

	'' Input for the file comes from libzip
	Dim As zip_file_t Ptr fi = zip_fopen_index(zip, i, 0)
	Do
		'' Write out the file content as returned by zip_fread(), which
		'' also does the decoding and everything.
		'' zip_fread() fills our buffer
		Dim As Integer bytes = _
			zip_fread(fi, buffer, BUFFER_SIZE)
		If (bytes < 0) Then
			'zip_fread() failed"
			Return 2
		End If

		'' EOF?
		If (bytes = 0) Then
			Exit Do
		End If

		'' Write <bytes> amount of bytes of the file
		If (Put(#fo, , *buffer, bytes)) Then
			'file output failed"
			Return 3
		End If
	Loop

	'' Done
	zip_fclose(fi)
	Close #fo
	Return 0
End Function

Function unpackZipPackage(ByRef archive As String, ByVal displayMeter As Single = -1) As Integer
	Dim As Integer errorCount = 0
	
	For charID As short = Len(archive) To 1 Step -1
		If Mid(archive,charID,1) = "/" Then
			extraDirs = left(archive,charID)
			Exit For
		End If
	Next 
	
	Dim As zip_t Ptr zip = zip_open(archive, ZIP_CHECKCONS, NULL)
	If (zip = NULL) Then
		Return 2
	End If

	'' For each file in the .zip... (really nice API, thanks libzip)
	For i As Integer = 0 To (zip_get_num_entries(zip, 0) - 1)
		#ifdef BROWSER_LONG
		If displayMeter >= 0 Then
			createMeter(displayMeter,"Extracting files... ("+commaSep(i)+" / "+commaSep(zip_get_num_entries(zip, 0))+" done)",0,abs(CanvasScreen.Height < 768))
			Screencopy
		End If
		#endif
		If unpackZipFile(zip, i) Then
			errorCount += 1
		End If
	Next

	zip_close(zip)
	If errorCount > 0 Then
		Return 1
	End If
	Return 0
End Function
