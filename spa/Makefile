.PHONY: build clean

build:
	nix-shell --run "tsc"
	sed "/__JS_PLACEHOLDER__/r app.js" index_TEMPLATE.html | sed "/__JS_PLACEHOLDER__/d" > index.html
	sed "/__JS_PLACEHOLDER__/r app.js" index_flex_TEMPLATE.html | sed "/__JS_PLACEHOLDER__/d" > index_flex.html
	rm -f app.js

clean:
	rm -f app.js index.html index_flex.html
