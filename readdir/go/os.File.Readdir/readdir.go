package main

import (
	"fmt"
	"os"
	"github.com/aristanetworks/goarista/monotime"
)

var expected_length = 4096

func run() uint64 {
	start := monotime.Now()
	
	dir, err := os.Open("../../bigdir")
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	}

	files, err := dir.Readdir(0)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	}

	err = dir.Close()
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	}

	end := monotime.Now()
	if len(files) != expected_length && len(files) != expected_length + 2 {
		fmt.Printf("expected %d files but only found %d\n",
			expected_length, len(files))
		os.Exit(1)
	}
	return (end - start)
}

func main() {
	for i := 0; i < 10; i++ {
		ns := run()
		ms := float64(ns)/1000000.
		fmt.Printf("%f\n", ms)
	}
}
