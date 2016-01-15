
default: build

help:
	@echo "make help  	- this help message"
	@echo "make build   - build the syntax extension"
	@echo "make test    - run the tests"
	@echo "make code    - show the processed code of the tests"
	@echo "make tree    - show the syntax tree of the tests"
	@echo "make clean   - remove the binaries and build artifacts"

build:
	ocamlbuild -package compiler-libs.bytecomp src/ppx_rule.native

test: build
	ocamlopt -ppx ./ppx_rule.native ./tests/test_ppx_rule.ml -o ./test_ppx_rule.native

code: build
	ocamlc -dsource -ppx ./ppx_rule.native ./tests/test_ppx_rule.ml

tree: build
	ocamlc -dparsetree -ppx ./ppx_rule.native ./tests/test_ppx_rule.ml

clean:
	ocamlbuild -clean
	rm -rf *.native

