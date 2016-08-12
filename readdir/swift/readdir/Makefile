.PHONY: all run clean

all: readdir

run:
	./readdir

readdir: main.swift ../timer.swift
	xcrun -sdk macosx swiftc -o readdir ../timer.swift main.swift

clean:
	rm -f readdir
