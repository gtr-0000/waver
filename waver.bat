@echo off

setlocal enabledelayedexpansion

set sp=11025

set /a t1=sp

REM 各个音符的频率
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
	REM 生成波形，hex文件格式：
	REM 有多行，每一行有两个数字 a b ，表示有 a 个字符码为 b 的字符
	call :compile "%%~fo" >"%%~dpno.hex"
	REM 转换
	hex2snd.vbs "%%~dpno.hex" "%%~dpno.snd"
	del "%%~dpno.hex"
	set snd=!snd! "%%~dpno.snd"
)

REM 混合
mergesnd.vbs !snd!

REM 获得大小
for %%a in ("%~dpn1.snd") do set szsnd=%%~za

REM 输出wav头
(
	REM 资源交换文件标志（RIFF）
	echo 1 82
	echo 1 73
	echo 2 70
	REM 从下个地址开始到文件尾的总字节数
	set /a szcnt=szsnd+36
	call :hexout !szcnt!
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
	echo 1 1
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
	call :hexout !szsnd!
	REM DATA数据块
) > "%~dpn1_head.hex"

hex2snd.vbs "%~dpn1_head.hex" "%~dpn1.head"

REM 合并成品
copy /b "%~dpn1.head" + "%~dpn1.snd" "%~dpn1.wav" >nul
for %%o in (%*) do del "%%~dpno.snd"
del "%~dpn1_head.hex" "%~dpn1.head"
goto :eof

:compile
(more <"%~1" & echo $)>"%~dpn0.tmp"

set $n=0
REM 计算要处理的音符数量
for /f "usebackq delims=" %%l in ("%~dpn0.tmp") do (
	set l=%%l
	if not "!l:~,1!"=="$" (
		set /a n+=1
		set l!n!=!l!
		REM 获取有音符的行
		for /l %%n in (0,1,7) do if not "!l!"=="!l:%%n=!" set ml=!n!
	) else (
		if !n! neq 0 (
			REM 获取有音符的行的长度到 len
			REM 用for中转变量!ml!到%%m
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
			REM 获取有音符的行的长度到 len 完成
			for %%m in (!ml!) do for /l %%x in (0,1,!len!) do (
				set c=!l%%m:~%%x,1!
				REM 音符计数
				if "0" leq "!c!" if "!c!" leq "7" set /a $n+=1
			)
		)
	)
)
REM 计算要处理的音符数量 完成

set $c=0
set n=0

for /f "usebackq delims=" %%l in ("%~dpn0.tmp") do (
	set l=%%l
	if not "!l:~,1!"=="$" (
		set /a n+=1
		set l!n!=!l!
		REM 获取有音符的行
		for /l %%n in (0,1,7) do if not "!l!"=="!l:%%n=!" set ml=!n!
	) else (
		REM 处理行
		if !n! neq 0 (
			REM 获取有音符的行的长度到 len
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
			REM 获取有音符的行的长度到 len 完成

			REM s表示当前模式
			REM 	0:%%x在音符前面
			REM 	1:%%x在音符后面
			REM 	2:%%x在下一个音符区域之前(意思就是要赶快处理音符了)
			set s=0
			REM k升降调
			set k=256
			REM t时长
			set t=!t1!
			REM ts附点时长
			set ts=!t1!
			REM 音符间隔(每个音符有一小段时间是不发音的)
			set /a tw=t1/16
			REM 用for中转变量!ml!到%%m
			for %%m in (!ml!) do (
				REM 注意，len没有减一，这是为了在最后面获取到空串，做标志
				for /l %%x in (0,1,!len!) do (
					REM 处理字符
					set c=!l%%m:~%%x,1!
					if "!s!"=="1" (
						if "!c!"=="-" set /a t+=t1
						REM 附点
						if "!c!"=="." set /a ts/=2,t+=ts
						REM 遇到#,b,+,0-7时表明应该是下一个音符之前
						if "!c!"=="#" set s=2
						if "!c!"=="b" set s=2
						if "!c!"=="+" set s=2
						REM 在最后会获取到空串，表示最后一个音符处理
						if "!c!"=="" set s=2
						if "0" leq "!c!" if "!c!" leq "7" set s=2
						if "!s!"=="2" (
							set /a $c+=1
							title !$c!/!$n! "%~1"

							REM 处理音符，mx是音符的位置
							for %%x in (!mx!) do (
								for /l %%l in (1,1,!n!) do (
									set cn=!l%%l:~%%x,1!
									REM 检查高低八度，8/16/32..分音符，三连音等
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
								REM 休止符
								echo !t! 128
							) else (
								REM 生成方波
								if !tw! gtr 0 echo !tw! 128

								REM x方波段数
								set /a t0=t-tw,x=t0*feq/sp
								for /l %%x in (1,1,!x!) do (
									REM 输出方波
									set /a "e=(%%x %% 2)*128+64,t2=%%x*sp/feq - (%%x-1)*sp/feq"
									if !t2! gtr 0 echo !t2! !e!
								)
								REM 补上方波最后一段
								set /a "e=((x+1)%% 2)*128+64,t2=t0-x*sp/feq"
								if !t2! gtr 0 echo !t2! !e!
							)
							REM 处理音符 完成
							set s=0
							set k=256
							set t=!t1!
							set ts=!t1!
							set /a tw=t1/16
						)
					)
					if "!s!"=="0" (
						REM 升调，降调
						if "!c!"=="#" set /a k=k*f4/f3
						if "!c!"=="b" set /a k=k*f3/f4
						REM 连音，把tw设为0
						if "!c!"=="+" set tw=0
						REM 获得音符，mx保存音符位置
						if "0" leq "!c!" if "!c!" leq "7" set /a feq=f!c!*k/256,s=1,mx=%%x
					)
				)
			)
		)
		REM 处理行 完成
		set n=0
	)
)
del "%~dpn0.tmp"
goto :eof

:hexout
REM 以小端方式输出32位整数
set /a "x1=%~1 & 0xFF, x2=(%~1 >> 8) & 0xFF, x3=(%~1 >> 16) & 0xFF, x4=(%~1 >> 24) & 0xFF
echo 1 !x1!
echo 1 !x2!
echo 1 !x3!
echo 1 !x4!
goto :eof