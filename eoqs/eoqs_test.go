package eoqs

import "testing"

var stages [][]byte

func init() {
	for i := 64; i < 1e10; i *= 2 {
		data := make([]byte, i)
		data[0] = '"'
		data[i-1] = '"'
		for j := 0; j < i; j += 16 {
			data[j-1] = '\\'
			data[j] = '"'
		}
		stages = append(stages, data)
	}
}

func TestEOQS(t *testing.T) {
	for i := 0; i < len(stages); i++ {
		t.Run("sse2", func(t *testing.T) {
			p := eoqsSSE2(stages[i])
			if p != len(stages[i]) {
				t.Errorf("eoqsSSE2(%d) = %d, want %d", i, p, i)
			}
		})
	}
}
