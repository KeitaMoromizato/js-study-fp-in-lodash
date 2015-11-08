# JavaScript勉強会 #lodashによる関数型プログラミング

## アジェンダ
* 副作用のある関数
* 関数の一般化

## 副作用のある関数
「与えられた引数による演算結果を返す」以外の処理をする関数を「副作用のある関数」と呼ぶ。副作用のない関数は「純粋関数」と呼ぶ。

```
関数型言語界隈の人に言わせると怪しい表現だが、初心者はこれくらいの認識でいい。本当は参照透過性とか、高階関数とか難しそうな言葉が出てくるが、とりあえず雰囲気がわかれば良い。
```

### 同じ引数で戻り値が変わってしまう関数
関数(メソッド)は、与えられた引数が同じであれば同じ結果を返す方が望ましい。

以下の関数は内部的に`new Date()`を実行して実行時の現在時刻を取得しているため、引数に対して戻り値が一意にならない。この関数は汎用性がなく、テストも難しい。

```
// 副作用のある関数
function dateFormatter(target) {
  const diffMin = (new Date() - target) / 1000;

  if (diffMin < 60) return `${diffMin}秒`;
  if (diffMin < 60 * 60) return `${diffMin / 60}分`;
  // ...
};
```

これを副作用のない形に書き直すとこうなる。引数に渡した2つの値でのみ戻り値は決定され、いつどのタイミングで呼び出しても結果は変わらない。

```
// 副作用のある関数
function dateFormatter(base, target) {
  const diffMin = (base - target) / 1000;

  if (diffMin < 60) return `${diffMin}秒`;
  if (diffMin < 60 * 60) return `${diffMin / 60}分`;
  // ...
};
```

### 演算結果を返す以外の処理を行う関数
関数は引数に渡した値を元に演算結果を返す、ということ以外の処理を行わないことが望ましい。

次の関数は関数内部でメールを送信する処理を行っており、送信が失敗するとどうなるのか、送信が出来ないテスト環境だとどうなるのか考慮することが難しい。(= 引数が正しくても動作が変わる可能性がある)

```
function regist(userName, mailAddress) {
  const user = new User(username);

  sendRegistMail(mailAddress);

  return user;
};
```

これを(出来るだけ)副作用のない形に書き直すとこうなる。メールの送信/失敗を引数で渡したmailerモジュールで定義出来るため、若干副作用は解消される。関数型言語だとタプルというものを使って表現したいけどJavaScriptだと難しい(気になる人だけ調べたら良い)。

```
function regist(userName, mailAddress, mailer) {
  const user = new User(username);

  mailer.sendRegistMail(mailAddress);

  return user;
};
```

### 破壊的メソッド
メソッド呼び出しによりそのオブジェクトの構造を変えてしまうメソッドのこと。呼び出すたびに戻り値が変更されてしまうため、これも副作用のある関数。
JavaScriptのstring型にはこの手のメソッドが多く、使い慣れていないと詰まるかも。

```
var test = [1, 3, 5];

var len = test.push(7);
// => 4

var len2 = test.push(8);
// => 5
```

中には破壊的でないメソッドもあるので書き方によっては副作用のない形でコーディング出来る。

```
var test = [1, 3, 5];

var len = test.concat([7]);
// => [1, 3, 5, 7]

var len2 = test.push([8]);
// => [1, 3, 5, 8]
```

## 関数の一般化
関数を出来るだけ副作用のない形に書いていくと、関数が一般化(共通化)出来ることがある。

次の例は、副作用のない関数`twice`と`half`。これらは副小夜のない関数であり、よく似ている(for文内の処理が違うだけ)。これを一般化するにはどうしたらいいのか？

```
const test = [2, 8, 10];

function twice(array) {
  let result = [];
  for (let i = 0; i < array.length; i++) {
    result.push(array[i] * 2);
  }

  return result;
}

twice(test);
// => [4, 16, 20]

function half(array) {
  let result = [];
  for (let i = 0; i < array.length; i++) {
    result.push(array[i] / 2);
  }

  return result;
}

half(test);
// => [1, 4, 5]
```

上記の2関数の違いはfor文内部のロジックのみであり、そのロジックとは「number型に何かしらの演算を行い、number型の結果を得る」ことである。これはつまり「number型の引数を1つ受け取り、number型の値を返す」関数と見ることが出来る。

`map`という関数で一般化すると以下のように書ける。

```
function map(array, f) {
  let result = [];
  for (let i = 0; i < array.length; i++) {
    result.push(f(array[i]));
  }

  return result;
}

const test = [2, 8, 10];

function twice(array) {
  return map(array, (num) => { return num * 2; });
}

twice(test);
// => [4, 16, 20]

function half(array) {
  return map(array, (num) => { return num / 2; });
}

half(test);
// => [1, 4, 5]
```

関数を一般化することで以下のメリットがある
* 重複したコードが無くなり、バグが出にくくなる(for文の式って間違いやすい。。。)
* 似たような関数を作るのが簡単。arrayの各値を10倍する関数とか。

また、JavaScriptは動的型付けなので基本的に別の型でも応用が効く

```
const test = ['hoge', 'huga'];

function toUpper(array) {
  return map(array, (str) => { return str.toUpperCase(); });
}
toUpper(test);
// => ['HOGE', 'HUGA'];
```

このように一般化された関数の応用範囲は広い。
そして、その一般化された関数群を集めたライブラリが**lodash**である。
