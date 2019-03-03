dim fp()
redim fp(wsh.arguments.count - 1)
for i = 0 to UBound(fp)
	set fp(i) = createobject("adodb.stream")
	with fp(i)
		.mode=3
		.type=2
		.open
		.loadfromfile wsh.arguments(i)
	end with
next

set sa=createobject("adodb.stream")
with sa
	.mode=3
	.type=2
	.open
	do until fp(0).eos
		tn=0
		cn=0
		for i=0 to UBound(fp)
			if not fp(i).eos then
				tn=tn + 1
				a=fp(i).readtext(1)
				if len(a)=0 then exit do
				cn=cn+ascb(a)
			end if
		next
		cn=int(cn/tn)
		sa.writetext chrb(cn)
	loop

	for i=0 to UBound(fp)
		fp(i).close
	next

	.position = 2
	set sb = createobject("adodb.stream")
	with sb
		.mode = 3
		.type = 1
		.open
		sa.copyto sb
		.savetofile wsh.arguments(0), 2
		.close
	end with
	.close
end with