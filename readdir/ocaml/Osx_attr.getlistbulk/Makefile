.PHONY: all run clean

all:
	ocamlbuild -use-ocamlfind -pkgs osx-attr readdir.native
	mv readdir.native readdir

run:
	./readdir

clean:
	ocamlbuild -clean
