# Braph
## What is it?
自作コンパイル言語Braphです。  
Braph -> 字句解析 -> LR(1)構文解析 -> 意味解析+コード出力 の流れでコンパイルします。

## 使い方
XcodeでBuildして使ってください。入力モードになるので、好き勝手入力してみましょう。

```
let a = 10;
return a;
```

Ctrl+dで終了します。その時それまでのLLVM-IRを吐き出します。

# 文法
## コード生成できるもの
### 代入

```
let a = 10;
```

### 変数を利用したreturn

```
return a;
```

## コード生成できないもの
### 四則演算を利用したもの

```
let b = 5 + 2;
1 + 2;
b + 2;
```
