# waver
waver是一个将简谱转化为wav文件的工具。
支持休止符，附点，升/降调，三连音的处理。
你可以将多个简谱放在一起生成(类似于背景伴奏)。
## 注意保护你的耳朵!

##### 用法：
waver "文件1" "文件2" "文件3" ...

##### 简谱分析规则

音符: `1` `2` `3` `4` `5` `6` `7`

休止符: `0`

八度高音: 在音符上方加 `.`

```
.
1
```

八度低音: 在音符下方加 `.`

```
1
.
```

时值减半: 在音符下方加 `-`

```
1
-
```

时值增加: 在音符右方加 `-`

```
1 - 2 - 3 - - -
```

附点: 在音符右方加 `.`

```
1.
```

升/降调: 在音符左方加 `#`/`b`

```
#4 b7
```

连音: 在音符左方加 `~`

```
3 ~3
   -
   -
```
三连音: 在音符上方加 `/T\`

```
/T\ /T\ /T\ /T\
123 345 432 321
--- --- --- ---
```
分行(可当注释)：以`$`开头的行

```
1 2 3 4 5 - - -
$
5 4 3 2 1 - - -
$
2 3 4 5 6 - - -
$
6 5 4 3 2 - - -
$ example
```