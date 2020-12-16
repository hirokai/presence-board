# Presence board

Shows presence in the office. Written in Elm.

MIT license.

## Build

```
npm install
build.sh
```

All files are copied in `hosting-firebase/public/` and subfolders.

## Install

* Back end: A Firebase account with full read/write permission.
  * https://github.com/firebase/quickstart-js/issues/239#issuecomment-421781605 
* Front end: single-page app writted in Elm (HTML and compiled JavaScript files).
  * Any static file hosting works.

The main board is on `presence.html`
The admin page is on `admin.html`.

`js/filebase_config.js` should be set as follows. (https://firebase.google.com/docs/database/web/start). `firebaseConfig` is used by `js/admin.js` and `js/presence.js`.
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

## Deploy to Firebase Hosting
```
cd hosting-firebase
firebase login
firebase deploy
```


## How to debug

Install `elm-live`
```
npm i -g elm-live
```

Then run either of the following.
```
elm-live src/Presence.elm -s presence.html --open -- --output=js/presence.elm.min.js
```
```
elm-live src/Admin.elm -s admin.html --open -- --output=js/admin.elm.min.js
```

