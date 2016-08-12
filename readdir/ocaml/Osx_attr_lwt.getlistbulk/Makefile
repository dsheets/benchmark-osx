.PHONY: all run clean

all:
	ocamlbuild -use-ocamlfind -pkgs osx-attr.lwt \
		-I lib readdir.native
	mv readdir.native readdir

run:
	./readdir

clean:
	ocamlbuild -clean
