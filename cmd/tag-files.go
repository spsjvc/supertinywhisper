package main

import (
	"fmt"
	"io"
	"os"
)

func processText(text string) string {
	return text
}

func main() {
	input, err := io.ReadAll(os.Stdin)

	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading stdin: %v\n", err)
		os.Exit(1)
	}

	fmt.Print(processText(string(input)))
}
