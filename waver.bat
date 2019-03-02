@echo off

setlocal enabledelayedexpansion

set sp=11025

set /a t1=sp/2
set f1=256
set f2=287
set f3=323
set f4=342
set f5=384
set f6=431
set f7=483
set f0=0

set body=
for %%o in (%*) do (
	echo "%%~o" : 
	call :comp "%%~fo" >"%%~dpno_body.txt"
	hex.vbs "%%~dpno_body.txt" "%%~dpno.body"
	del "%%~dpno_body.txt"
	set body=!body! "%%~dpno.body"
)
merge.vbs !body!

for %%a in ("%~dpn1.body") do set szbody=%%~za

(
	REM 资源交换文件标志（RIFF）
	echo 1 82
	echo 1 73
	echo 2 70
	REM 从下个地址开始到文件尾的总字节数
	set /a szcont=szbody+36
	call :hexout !szcont!
	REM WAV文件标志（WAVE）
	echo 1 87
	echo 1 65
	echo 1 86
	echo 1 69
	REM 波形格式标志（fmt ），最后一位空格。
	echo 1 102
	echo 1 109
	echo 1 116
	echo 1 32
	REM 过滤字节（一般为00000010H）
	echo 1 16
	echo 3 0
	REM 格式种类（值为1时，表示数据为线性PCM编码）
	echo 1 1
	echo 1 0
	REM 通道数，单声道为1
	echo 1 1
	echo 1 0
	REM 采样频率
	call :hexout !sp!
	REM 波形数据传输速率（每秒平均字节数）
	call :hexout !sp!
	REM DATA数据块长度，字节。
	echo 1 0
	echo 1 0
	REM PCM位宽
	echo 1 8
	echo 1 0
	REM 数据标志符（data）
	echo 1 100
	echo 1 97
	echo 1 116
	echo 1 97
	REM DATA总数据长度字节
	call :hexout !szbody!
	REM DATA数据块
) > "%~dpn1_head.txt"
cscript /nologo hex.vbs "%~dpn1_head.txt" "%~dpn1.head"
copy "%~dpn1.head" + "%~dpn1.body" "%~dpn1.wav" >nul
for %%o in (%*) do del "%%~dpno.body"
del "%~dpn1_head.txt" "%~dpn1.head" 
goto :eof

:comp
(more <"%~1" & echo $)>"%~dpn0.tmp"
for /f %%a in ('find /c "$" ^<"%~dpn0.tmp"') do set $n=%%a
set $c=0
set n=0
for /f "usebackq delims=" %%l in ("%~dpn0.tmp") do (
	set l=%%l
	if not "!l:~,1!"=="$" (
		set /a n+=1
		set l!n!=!l!
		for /l %%n in (0,1,7) do (
			if not "!l!"=="!l:%%n=!" set ml=!n!
		)
	) else (
		set /a $c+=1
		echo !$c! / !$n! >&2
		REM gen
		if !n! neq 0 (
			REM strlen
			for %%m in (!ml!) do set "$=!l%%m!#"
			set len=0
			for %%a in (4096 2048 1024 512 256 128 64 32 16) do (
				if not "!$:~%%a!"=="" (
					set /a len+=%%a
					set $=!$:~%%a!
				)
			)
			set $=!$!fedcba9876543210
			set /a len+=0x!$:~16,1!
			REM strlen end
			set x=0
			set s=0
			set k=256
			set t=!t1!
			set ts=!t1!
			set /a tw=t1/16
			for %%m in (!ml!) do (
				for /l %%x in (0,1,!len!) do (
					set c=!l%%m:~%%x,1!
					if "!s!"=="1" (
						if "!c!"=="-" set /a t+=t1
						if "!c!"=="." set /a ts/=2,t+=ts
						if "!c!"=="#" set s=2
						if "!c!"=="b" set s=2
						if "!c!"=="+" set s=2
						if "!c!"=="" set s=2
						if "0" leq "!c!" if "!c!" leq "7" set s=2
						if "!s!"=="2" (
							REM muz
							for %%x in (!Mx!) do (
								for /l %%l in (1,1,!n!) do (
									set cn=!l%%l:~%%x,1!
									if "!cn!"=="." (
										if %%l lss !ml! (
											set /a feq*=2
										) else (
											set /a feq/=2
										)
									)
									if "!cn!"=="-" set /a t/=2
									if "!cn!"=="/" set /a t=t*2/3
									if "!cn!"=="T" set /a t=t*2/3
									if "!cn!"=="\" set /a t=t*2/3
								)
							)
							if "!feq!"=="0" (
								echo !t! 128
							) else (
								if !tw! gtr 0 echo !tw! 128
								set /a t0=t-tw,x=t0*2*feq/sp
								for /l %%x in (1,1,!x!) do (
									set /a "e=(%%x %% 2)*128+64,t2=%%x*sp/2/feq - (%%x-1)*sp/2/feq"
									if !t2! gtr 0 echo !t2! !e!
								)
								set /a "e=((x+1)%% 2)*128+64,t2=t0-x*sp/2/feq"
								if !t2! gtr 0 echo !t2! !e!
							)
							REM muz end
							set x=%%x
							set s=0
							set k=256
							set t=!t1!
							set ts=!t1!
							set /a tw=t1/16
						)
					)
					if "!s!"=="0" (
						if "!c!"=="#" set /a k=k*f4/f3
						if "!c!"=="b" set /a k=k*f3/f4
						if "!c!"=="+" set tw=1
						if "0" leq "!c!" if "!c!" leq "7" set /a feq=f!c!*k/256,s=1,mx=%%x
					)
				)
			)
		)
		REM gen end
		set n=0
	)
)
del "%~dpn0.tmp"
goto :eof

:hexout
set /a "x1=%~1 & 0xFF, x2=(%~1 >> 8) & 0xFF, x3=(%~1 >> 16) & 0xFF, x4=(%~1 >> 24) & 0xFF
echo 1 !x1!
echo 1 !x2!
echo 1 !x3!
echo 1 !x4!
goto :eof