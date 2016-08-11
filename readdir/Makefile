.PHONY: all run

all:
	ocamlbuild -use-ocamlfind readdir.native

run: all bigdir
	./readdir.native

bigdir:
	mkdir bigdir
	for i in `seq 1 4096`; \
		do touch bigdir/file-`printf %04d $$i`; \
	done
