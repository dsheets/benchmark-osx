.PHONY: all run clean

all:
	ocamlbuild -use-ocamlfind readdir.native
	mv readdir.native readdir

run:
	./readdir

clean:
	ocamlbuild -clean
