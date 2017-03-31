.PHONY: all run clean

all: pwrite

pwrite: pwrite.c ../benchmark_osx_pwrite.h
	cc -o pwrite pwrite.c

run:
	@echo `pwd`
	@./pwrite

clean:
	rm -f pwrite
