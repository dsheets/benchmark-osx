.PHONY: all run clean

all:
	$(MAKE) -C ocaml
	$(MAKE) -C c
	$(MAKE) -C go

run: bigdir
	$(MAKE) -C ocaml run
	$(MAKE) -C c run
	$(MAKE) -C go run

bigdir:
	mkdir bigdir
	for i in `seq 1 4096`; \
		do touch bigdir/file-`printf %04d $$i`; \
	done

clean:
	$(MAKE) -C ocaml clean
	$(MAKE) -C c clean
	$(MAKE) -C go clean
