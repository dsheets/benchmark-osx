.PHONY: all run clean

all:
	ocamlbuild -use-ocamlfind -pkgs unix-dirent.lwt readdir.native
	mv readdir.native readdir

run:
	./readdir

clean:
	ocamlbuild -clean
