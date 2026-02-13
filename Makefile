.PHONY: build clean compress

build:
	nix-shell --run "tsc"

compress:
	nix-shell --run "oxipng -o 4 -i 0 --strip safe -r ."

clean:
	rm -f app.js
