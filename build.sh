#!/usr/bin/env sh

mkdir -p hosting-firebase/public/

# Compile js
node node_modules/@babel/cli/bin/babel.js js/presence.js --out-file js/presence.min.js
node node_modules/@babel/cli/bin/babel.js js/admin.js --out-file js/admin.min.js

# Compile and minify Presence.elm
npx elm make --optimize src/Presence.elm --output=js-elm/presence.elm.js
node node_modules/google-closure-compiler/index.js --js=js-elm/presence.elm.js --js_output_file=js-elm/presence.elm.min.js

# Compile and minify Admin.elm
npx elm make --optimize src/Admin.elm --output=js-elm/admin.elm.js
node node_modules/google-closure-compiler/index.js --js=js-elm/admin.elm.js --js_output_file=js-elm/admin.elm.min.js

# lodash custom build.
# npx lodash -p --output lib/lodash.custom.min.js include=map,orderBy,filter,find

# Copy compiled files into public folder for deploy.
cp -r js hosting-firebase/public/
cp -r js-elm hosting-firebase/public/
cp -r lib hosting-firebase/public/
cp presence.html hosting-firebase/public/
cp admin.html hosting-firebase/public/
