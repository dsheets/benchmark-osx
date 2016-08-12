.PHONY: all run clean

all: readdir

readdir: readdir.go
	go build
	mv ioutil.ReadDir readdir

run:
	./readdir

clean:
	rm -f readdir
