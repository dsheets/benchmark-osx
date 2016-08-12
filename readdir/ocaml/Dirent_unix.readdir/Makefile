.PHONY: all run clean

all:
	ocamlbuild -use-ocamlfind -pkgs unix-dirent.unix readdir.native
	mv readdir.native readdir

run:
	./readdir

clean:
	ocamlbuild -clean
