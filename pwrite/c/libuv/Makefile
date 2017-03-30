.PHONY: all run clean

all: pwrite

pwrite: pwrite.c ../benchmark_osx_pwrite.h
	cc `pkg-config --cflags --libs libuv` -o pwrite pwrite.c

run:
	@echo `pwd`
	@./pwrite

clean:
	rm -f pwrite
