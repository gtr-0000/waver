set fp=createobject("scripting.filesystemobject").opentextfile(wsh.arguments(0))
set sa=createobject("adodb.stream")
with sa
	.mode = 3
	.type = 2
	.open
	do until fp.atendofstream
		.writetext chrb(cdbl(fp.readline()))
	loop
	.position = 2
	set sb = createobject("adodb.stream")
	with sb
		.mode = 3
		.type = 1
		.open
		sa.copyto sb
		.savetofile wsh.arguments(1), 2
		.close
	end with
	.close
end with
fp.close