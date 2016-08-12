package main

import (
	"fmt"
	"os"
	"io/ioutil"
	"github.com/aristanetworks/goarista/monotime"
)

var expected_length = 4096

func run() uint64 {
	start := monotime.Now()
	files, err := ioutil.ReadDir("../../bigdir")
	end := monotime.Now()
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)		
	}
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
