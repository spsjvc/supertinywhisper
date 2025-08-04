package main

import (
	"testing"
)

func TestProcessText(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "simple",
			input:    "hello world",
			expected: "hello world",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := processText(tt.input)

			if result != tt.expected {
				t.Errorf("processText() = %q, want %q", result, tt.expected)
			}
		})
	}
}
