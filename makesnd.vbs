Dim fp, bin(), Len, cnt, i, flen, l, j, fso
Set fso = CreateObject("scripting.filesystemobject")
Len     = 0

For i = 0 To wscript.arguments.Count - 2
	Set fp = fso.OpenTextFile(wscript.arguments(i + 1))
	flen      = 0

	Do until fp.AtEndOfStream
		l    = Split(fp.ReadLine()," ")
		flen = flen + Int(l(0))
	Loop

	If Len < flen Then Len = flen
	fp.close
Next

ReDim bin(Len - 1)

For i = 0 To Len - 1
	bin(i) = 0
Next

For i = 0 To wscript.arguments.Count - 2
	Set fp = fso.OpenTextFile(wscript.arguments(i + 1))
	flen           = 0

	Do until fp.AtEndOfStream
		l = Split(fp.ReadLine()," ")

		For j = flen To flen + Int(l(0)) - 1
			bin(j) = bin(j) + Int(l(1))
		Next

		flen = flen + Int(l(0))
	Loop

	For j = flen To Len - 1
		bin(j) = bin(j) + 128
	Next
	fp.close
Next

For i = 0 To Len - 1
	bin(i) = Int(bin(i)/(wscript.arguments.Count - 1))
Next

writebinary wscript.arguments(0),bin

Sub WriteBinary(FileName, Buf)
	Dim I
	Dim aBuf
	Dim Size
	Dim bStream
	Size = UBound(Buf)
	ReDim aBuf(Size \ 2)

	For I = 0 To Size - 1 Step 2
		aBuf(I \ 2) = ChrW(Buf(I + 1) * 256 + Buf(I))
	Next

	If I = Size Then aBuf(I \ 2) = ChrW(Buf(I))
	aBuf         = Join(aBuf, "")
	Set bStream  = CreateObject("ADODB.Stream")
	bStream.Type = 1: bStream.Open

	With CreateObject("ADODB.Stream")
		.Type = 2
		.Open
		.WriteText aBuf
		.Position = 2
		.CopyTo bStream
		.Close
	End With

	bStream.SaveToFile FileName, 2: bStream.Close
	Set bStream = Nothing
End Sub
