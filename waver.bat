@echo off
setlocal enabledelayedexpansion

set sp=5000

set /a t1=sp/2
set f1=256
set f2=287
set f3=323
set f4=342
set f5=384
set f6=431
set f7=483
set f0=0

call :comp "%~f1" >"%~dpn1_hex.txt"
cscript /nologo hex.vbs "%~dpn1_hex.txt" "%~dpn1.bin"
del "%~dpn0.sw?"
goto :eof

:comp
set n=0
(more <"%~1" & echo $)>"%~dpn0.sw0"
for /f %%a in ('find /c "$" ^<"%~dpn0.sw0"') do set tot=%%a
set cnt=0
for /f "usebackq delims=" %%l in ("%~dpn0.sw0") do (
	set l=%%l
	if not "!l:~,1!"=="$" (
		set /a n+=1
		set l!n!=!l!
		for /l %%n in (0,1,7) do (
			if not "!l!"=="!l:%%n=!" set ml=!n!
		)
	) else (
		set /a cnt+=1
		echo !cnt! / !tot! >&2
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
			set /a tw=t1/64
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
								for /l %%a in (1,1,!t!) do echo 128
							) else (
								for /l %%a in (2,1,!tw!) do echo 128
								for /l %%a in (!tw!,1,!t!) do (
									set /a "e=((%%a*2*feq/sp) %% 2)*128+64"
									echo !e!
								)
							)
							REM muz end
							set x=%%x
							set s=0
							set k=256
							set t=!t1!
							set ts=!t1!
							set /a tw=t1/64
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
goto :eof
