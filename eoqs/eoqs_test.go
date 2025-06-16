package eoqs

import (
	"fmt"
	"testing"
)

var stages [][]byte

func init() {
	for i := 64; i < 1e10; i *= 2 {
		data := make([]byte, i)
		data[0] = '"'
		data[i-1] = '"'
		for j := 16; j < i; j += 16 {
			data[j-1] = '\\'
			data[j] = '"'
		}
		stages = append(stages, data)
	}
}

func TestEOQS(t *testing.T) {
	for i := 0; i < len(stages); i++ {
		t.Run(fmt.Sprintf("sse2/%d", len(stages[i])), func(t *testing.T) {
			p := eoqsSSE2(stages[i])
			if p != len(stages[i])-1 {
				t.Errorf("sse2 %d, want %d", p, len(stages[i])-1)
			}
		})
	}
}
