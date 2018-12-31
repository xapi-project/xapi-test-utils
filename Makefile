PROFILE=release

.PHONY: build install uninstall clean reindent

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

reindent:
	git ls-files '**/*.ml' | xargs ocp-indent --inplace

