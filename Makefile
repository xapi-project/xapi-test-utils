PROFILE=release

.PHONY: build install uninstall clean format

build:
	dune build @install --profile=$(PROFILE)

release:
	dune build @install

install:
	dune install

uninstall:
	dune uninstall

clean:
	dune clean

format:
	dune build @fmt --auto-promote
