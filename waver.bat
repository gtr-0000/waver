@echo off
setlocal enabledelayedexpansion

set t1=11025
set f1=256
set f2=287
set f3=323
set f4=342
set f5=384
set f6=431
set f7=483
set f0=0

call :comp 1.txt > 2.txt
goto :eof

:comp
set n=0
for /l "usebackq delims=" %%l in ("%~1") do (
	if not "%%l"=="$" (
		set /a n+=1
		set l=%%l
		set l!n!=%%l
		for /l %%n in (0,1,7) do (
			if not "!l!"=="!l:~%%n=!" set ml=%%n
		)
	) else (
		call :gen
		set n=0
	)
)
goto :eof

:gen
if !n! neq 0 (
	call :getlen l!ml! len
	set x=0
	set s=0
	set k=256
	set t=!t1!
	set ts=!t1!
	set /a tw=t1/128
	for %%m in (!m1!) do (
		for /l %%x in (0,1,!len!) do (
			set c=!l%%m:~%%x,1!
			if "!s!"=="1" (
				if "!c!"=="#" set s=2
				if "!c!"=="b" set s=2
				if "!c!"=="+" set s=2
				if "0" leq "!c!" if "!c!" leq "7" set s=2
				if "!s!"=="2" (
					call :muz
					set x=%%x
					set s=0
					set k=256
					set t=!t1!
					set ts=!t1!
					set /a tw=t1/128
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
goto :eof

:muz
for %%x in (!Mx!) do (
	for %%l in (1,1,!n!) do (
		set c=!l%%l:~%%x,1!
		if "!c!"=="." (
			if %%l lss !m1! (
				set /a feq*=2
			) else (
				set /a feq/=2
			)
		)
		if "!c!"=="-" set /a t/=2
		if "!c!"=="/" set /a t=t*2/3
		if "!c!"=="T" set /a t=t*2/3
		if "!c!"=="\" set /a t=t*2/3
	)
)
if "!feq!"=="0" (
	for /l %%a in (1,1,!t!) do echo 128
) else (
	for /l %%a in (2,1,!tw!) do echo 128
	for /l %%a in (!tw!,1,!t!) do (
		set /a "e=((%%a*2*feq/22050) %% 2)*128+64"
		echo !e!
	)
)
goto :eof