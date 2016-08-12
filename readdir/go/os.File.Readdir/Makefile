.PHONY: all run clean

all: readdir

readdir: readdir.go
	go build
	mv os.File.Readdir readdir

run:
	./readdir

clean:
	rm -f readdir
