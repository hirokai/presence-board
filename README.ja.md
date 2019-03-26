# 在席表

在席をオンラインで更新できるボードです。Elm 0.19で書かれています。
Firebaseのデータベースにブラウザ内のJavaScriptから直接読み書きして動作します。

MITライセンス。

**現状，Firebaseの任意の読み書き権限を必要とし，Firebaseへの接続のための情報がクライアントから見えるため，URLを一般公開しない社内用途にのみ使用してください。**

## 使用方法
1. 任意の読み書きを許可したFirebaseのRealtime Databaseを用意する。
2. `js/filebase_config.js`を以下の内容で作成（https://firebase.google.com/docs/database/web/start）。
```
var firebaseConfig = {
	apiKey: "XXXXXXX",
	authDomain: "YYYYYY.firebaseapp.com",
	databaseURL: "https://YYYYYY.firebaseio.com",
	projectId: "YYYYYY",
	storageBucket: "YYYYYY.appspot.com",
	messagingSenderId: "ZZZZZZ"
};
```
3. HTML/JSファイルをサーバーに置く場合，`hosting-firebase/public/`内のファイル一式（サブフォルダ含む）を静的ホスティングする。
4. `presence.html`をブラウザで開けば主画面（在席表）が開き，`admin.html`を開けば管理画面が開く。

## アーキテクチャ

* バックエンド： FirebaseのRealtime Database. 
  * https://github.com/firebase/quickstart-js/issues/239#issuecomment-421781605 
* フロントエンド： Elm 0.19で書かれたSingle-page App。
  * クライアントからバックエンド（Firebaseのデータベース）に直接アクセスする。
  * 自前のサーバー，ローカルなど，どこに置いても良い。

## ビルド方法

`build.sh`を実行.
必要なすべてのファイルは `hosting-firebase/public/`とサブフォルダにコピーされる。

## 開発・デバッグ

`elm-live`をインストール
```
npm i -g elm-live
```

以下のいずれかを実行
```
elm-live src/Presence.elm -s presence.html --open -- --output=js/presence.elm.min.js
```
```
elm-live src/Admin.elm -s admin.html --open -- --output=js/admin.elm.min.js
```

