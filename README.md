# JavaScript勉強会 #lodashによる関数型プログラミング

関数型の側面からlodashを学び、日々のJavaScriptコーディングを楽にするための資料です。

以下の手順で動作環境を構築することで、簡単に動作確認が出来ます。本プロジェクトではBabelによる変換を行っているので、ES2015形式で書くことが出来ます。

```
$ git clone https://github.com/KeitaMoromizato/js-study-fp-in-lodash
$ npm install
$ grunt watch
# => index.jsを変更すると自動的に実行されます。
```

以下のlodashドキュメントも参考にしながら進めましょう。

https://lodash.com/docs

## アジェンダ
* 副作用のある関数
* 関数の一般化
* lodashとは
* 配列向け関数群
* Object向けの関数群
* ES2015とchain

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
そして、その一般化された関数群を集めたライブラリが**lodash**である。lodashを使うメリットは、一般化された関数群によってコード量が減るだけでなく、**そこで使う関数群がテスト済みである** ということが重要。

## lodashとは
オブジェクトや配列の操作を行う一般化された関数群が含まれたライブラリ。似たようなライブラリに`Underscore.js`があり、lodashの方が後発。備わっている関数はほとんど同じもので、統合されるとかされないとか噂もある。

一番大きな違いはlodashは必要な関数だけrequire出来ること。あと若干早いらしい。

```
const map = require('lodash.map');
```

ただ、慣れないうちはとりあえず全部requireして良いと思う。使用する場合は以下のように`_`にバインドするのが慣習。これはunderscore.jsがその名の通り`_`をブラウザ上の`window`オブジェクトに展開していた事から。ほぼ互換性のあるライブラリのため同じ感覚で使える方が良い。また、もっと元を辿れば関数型言語では`_`が仮引数を表す値として言語仕様となっていること(だと思う)。

```
const _ = require('lodash');

const test = [2, 8, 10];

_.map(array,  (num) => { return num * 2; });
// => [4, 16, 20]
```

## 配列向けの関数群
__以下では配列とCollection(配列ライクなオブジェクト)をまとめて配列と表記しています。__

lodashのリファレンスではしっかりと区別されているので、正確なものが知りたい方はそちらを参照してください。まずはlodashを使ってもらってメリットを感じて欲しいということ、実際使ってみてあまり意識したことが無いという2つの理由から、ここでは同一のものとして扱っています。

### forEach(each)
単純なループです。forを使ったループはバグを生みやすいため、基本的にはこちらを使いたい。一応JavaScriptのArrayオブジェクトにも`Array#forEach`というメソッドがあるが、これはES5の機能。古いブラウザだと動かない可能性あり。

```
_.forEach([1, 2], (n) => {
  console.log(n);
});
// => 1 2
```

### map
先ほど説明した`map`と同じです。配列の各要素に対して何かしらの演算をした結果を配列で返します。例えばオブジェクトの配列からあるキーを取り出したいときに使えます。

```
const result = _.map([1, 2], (n) => {
  return n * 2;
});
// => result = [2, 4]

const users = [
  {id: 1, name: 'hoge'},
  {id: 2, name: 'huga'}
];

const IDs = _.map(users, (user) => {
  return user.id;
});
// => IDs = [1, 2]

// オブジェクトからキーを取得する場合は以下のようにも書ける
const IDs = _.map(users, 'id');
```

### filter
配列からある条件に当てはまるものを取り除きます。第２引数で渡した関数がtrueを返した要素のみの配列を新しく作成します。この関数は**非破壊的** なので、引数で渡した配列は変更されません。

```
const even = _.filter([1, 3, 4, 8, 10], (num) => {
  return num % 2 === 0;
});
// => even = [4, 8, 10]
```

### reduce
配列の各要素に対して、再帰的な演算をした結果を返します。よく分からないと思うので使って慣れて下さい。。。合計の演算や`map`で実現できない処理(ex. 一部の要素の場合は値を返さない、など)に使えます。

```
const sum = _.reduce([1, 2, 3], (result, n) => {
  return result + n;
});
// => sum = 6
```

### uniq
その名の通りUniqueな要素のみ残した配列を返します。例えばオブジェクトから`map`でIDの配列を作成、その重複を省くときに使います。

```
const result = _.uniq([1, 3, 4, 1]);
// => result = [1, 3, 4]
```

### union
複数の配列を、`uniq`したうえで連結します。

```
const result = _.union([1, 3], [4, 1]);
// => result = [1, 3, 4]
```

### find
配列の中から要素を取り出します。

```
const users = [
  {id: 1, name: 'hoge'},
  {id: 2, name: 'huga'}
];

const user = _.find(users, (user) => {
  return user.name === 'hoge';
});
// => user = {id: 1, name: 'hoge'}
```

## Object向けの関数群
以下に示す関数群は全て **非破壊的** な関数です。lodashは基本的に非破壊的なものが多いですが、まれに引数で渡したものを書きかえてしまうものがあるので注意して下さい。出来る限り、非破壊的な関数を使う方向に寄せたほうが良いと思います。

### assign
オブジェクトに新しいKeyを追加します。keyが重複している場合は後で指定したほうで上書きされます。

```
const base = {
  id: 1,
  name: 'hoge'
};

const ext = _.assign(base, {
  role: 'admin'
});
// => {id: 1, name: 'hoge', role: 'admin'}
```

### pick
pickオブジェクトから指定したkeyのみ取り出します。これは関数の引数にObjectを渡した時、validなものだけ抜き出す用途で使ったりします(O/R MapperにそのままObjectを渡すときなど)。

```
const base = {
  id: 1,
  name: 'hoge',
  role: 'admin'
};

const ext = _.pick(base, ['name', 'role']);
// => {name: 'hoge', role: 'admin'}
```

### omit
omitは逆に、指定したkeyを除いたオブジェクトを返します。

```
const base = {
  id: 1,
  name: 'hoge',
  role: 'admin'
};

const ext = _.omit(base, ['name', 'role']);
// => {id: 1}
```

## ES2015とchain
この章はおまけです。chainを使わなくても問題は無いですが、使い方が分かるとスマートに書けることが多いです。
`_()`を使うと、メソッドチェーンで複数の関数を使うことが出来ます。`_()`に渡したオブジェクトが次のメソッドに渡され(よって第１引数にターゲットを指定する必要が無い)、`value()`で最終結果を返します。
これがES2015のArrowFunctionの短縮記法と相性が良く、ほぼ他の関数型言語と同じような感覚で書けるようになっています。

```
const users = [
  {
    name: "hoge",
    age: 10
  },
  {
    name: "huga",
    age: 30
  },
  {
    name: 'piyo',
    age: 21
  }
];

const result = _(users).filter(user => user.age >= 20).map(user => user.name).value();
// => result = ['hoge', 'piyo']
```
