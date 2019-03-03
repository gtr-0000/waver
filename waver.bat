@echo off

setlocal enabledelayedexpansion

set sp=11025

set /a t1=sp

REM ����������Ƶ��
set f1=256
set f2=287
set f3=323
set f4=342
set f5=384
set f6=431
set f7=483
set f0=0

set snd=
for %%o in (%*) do (
	echo "%%~o"
	REM ���ɲ��Σ�hex�ļ���ʽ��
	REM �ж��У�ÿһ������������ a b ����ʾ�� a ���ַ���Ϊ b ���ַ�
	call :compile "%%~fo" >"%%~dpno.hex"
	REM ת��
	hex2snd.vbs "%%~dpno.hex" "%%~dpno.snd"
	del "%%~dpno.hex"
	set snd=!snd! "%%~dpno.snd"
)

REM ���
mergesnd.vbs !snd!

REM ��ô�С
for %%a in ("%~dpn1.snd") do set szsnd=%%~za

REM ���wavͷ
(
	REM ��Դ�����ļ���־��RIFF��
	echo 1 82
	echo 1 73
	echo 2 70
	REM ���¸���ַ��ʼ���ļ�β�����ֽ���
	set /a szcnt=szsnd+36
	call :hexout !szcnt!
	REM WAV�ļ���־��WAVE��
	echo 1 87
	echo 1 65
	echo 1 86
	echo 1 69
	REM ���θ�ʽ��־��fmt �������һλ�ո�
	echo 1 102
	echo 1 109
	echo 1 116
	echo 1 32
	REM �����ֽڣ�һ��Ϊ00000010H��
	echo 1 16
	echo 3 0
	REM ��ʽ���ֵࣨΪ1ʱ����ʾ����Ϊ����PCM���룩
	echo 1 1
	echo 1 0
	REM ͨ������������Ϊ1
	echo 1 1
	echo 1 0
	REM ����Ƶ��
	call :hexout !sp!
	REM �������ݴ������ʣ�ÿ��ƽ���ֽ�����
	call :hexout !sp!
	REM DATA���ݿ鳤�ȣ��ֽڡ�
	echo 1 1
	echo 1 0
	REM PCMλ��
	echo 1 8
	echo 1 0
	REM ���ݱ�־����data��
	echo 1 100
	echo 1 97
	echo 1 116
	echo 1 97
	REM DATA�����ݳ����ֽ�
	call :hexout !szsnd!
	REM DATA���ݿ�
) > "%~dpn1_head.hex"

hex2snd.vbs "%~dpn1_head.hex" "%~dpn1.head"

REM �ϲ���Ʒ
copy /b "%~dpn1.head" + "%~dpn1.snd" "%~dpn1.wav" >nul
for %%o in (%*) do del "%%~dpno.snd"
del "%~dpn1_head.hex" "%~dpn1.head"
goto :eof

:compile
(more <"%~1" & echo $)>"%~dpn0.tmp"

set $n=0
REM ����Ҫ�������������
for /f "usebackq delims=" %%l in ("%~dpn0.tmp") do (
	set l=%%l
	if not "!l:~,1!"=="$" (
		set /a n+=1
		set l!n!=!l!
		REM ��ȡ����������
		for /l %%n in (0,1,7) do if not "!l!"=="!l:%%n=!" set ml=!n!
	) else (
		if !n! neq 0 (
			REM ��ȡ���������еĳ��ȵ� len
			REM ��for��ת����!ml!��%%m
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
			REM ��ȡ���������еĳ��ȵ� len ���
			for %%m in (!ml!) do for /l %%x in (0,1,!len!) do (
				set c=!l%%m:~%%x,1!
				REM ��������
				if "0" leq "!c!" if "!c!" leq "7" set /a $n+=1
			)
		)
	)
)
REM ����Ҫ������������� ���

set $c=0
set n=0

for /f "usebackq delims=" %%l in ("%~dpn0.tmp") do (
	set l=%%l
	if not "!l:~,1!"=="$" (
		set /a n+=1
		set l!n!=!l!
		REM ��ȡ����������
		for /l %%n in (0,1,7) do if not "!l!"=="!l:%%n=!" set ml=!n!
	) else (
		REM ������
		if !n! neq 0 (
			REM ��ȡ���������еĳ��ȵ� len
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
			REM ��ȡ���������еĳ��ȵ� len ���

			REM s��ʾ��ǰģʽ
			REM 	0:%%x������ǰ��
			REM 	1:%%x����������
			REM 	2:%%x����һ����������֮ǰ(��˼����Ҫ�Ͽ촦��������)
			set s=0
			REM k������
			set k=256
			REM tʱ��
			set t=!t1!
			REM ts����ʱ��
			set ts=!t1!
			REM �������(ÿ��������һС��ʱ���ǲ�������)
			set /a tw=t1/16
			REM ��for��ת����!ml!��%%m
			for %%m in (!ml!) do (
				REM ע�⣬lenû�м�һ������Ϊ����������ȡ���մ�������־
				for /l %%x in (0,1,!len!) do (
					REM �����ַ�
					set c=!l%%m:~%%x,1!
					if "!s!"=="1" (
						if "!c!"=="-" set /a t+=t1
						REM ����
						if "!c!"=="." set /a ts/=2,t+=ts
						REM ����#,b,+,0-7ʱ����Ӧ������һ������֮ǰ
						if "!c!"=="#" set s=2
						if "!c!"=="b" set s=2
						if "!c!"=="+" set s=2
						REM �������ȡ���մ�����ʾ���һ����������
						if "!c!"=="" set s=2
						if "0" leq "!c!" if "!c!" leq "7" set s=2
						if "!s!"=="2" (
							set /a $c+=1
							title !$c!/!$n! "%~1"

							REM ����������mx��������λ��
							for %%x in (!mx!) do (
								for /l %%l in (1,1,!n!) do (
									set cn=!l%%l:~%%x,1!
									REM ���ߵͰ˶ȣ�8/16/32..����������������
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
								REM ��ֹ��
								echo !t! 128
							) else (
								REM ���ɷ���
								if !tw! gtr 0 echo !tw! 128

								REM x��������
								set /a t0=t-tw,x=t0*feq/sp
								for /l %%x in (1,1,!x!) do (
									REM �������
									set /a "e=(%%x %% 2)*128+64,t2=%%x*sp/feq - (%%x-1)*sp/feq"
									if !t2! gtr 0 echo !t2! !e!
								)
								REM ���Ϸ������һ��
								set /a "e=((x+1)%% 2)*128+64,t2=t0-x*sp/feq"
								if !t2! gtr 0 echo !t2! !e!
							)
							REM �������� ���
							set s=0
							set k=256
							set t=!t1!
							set ts=!t1!
							set /a tw=t1/16
						)
					)
					if "!s!"=="0" (
						REM ����������
						if "!c!"=="#" set /a k=k*f4/f3
						if "!c!"=="b" set /a k=k*f3/f4
						REM ��������tw��Ϊ0
						if "!c!"=="+" set tw=0
						REM ���������mx��������λ��
						if "0" leq "!c!" if "!c!" leq "7" set /a feq=f!c!*k/256,s=1,mx=%%x
					)
				)
			)
		)
		REM ������ ���
		set n=0
	)
)
del "%~dpn0.tmp"
goto :eof

:hexout
REM ��С�˷�ʽ���32λ����
set /a "x1=%~1 & 0xFF, x2=(%~1 >> 8) & 0xFF, x3=(%~1 >> 16) & 0xFF, x4=(%~1 >> 24) & 0xFF
echo 1 !x1!
echo 1 !x2!
echo 1 !x3!
echo 1 !x4!
goto :eof