package indexbyte

import (
	"strconv"
	"testing"
)

var stagesne []stage

func init() {
	var c int
	for i := 1; i < 1e10; i *= 10 {
		data := make([]byte, i-1, i)
		data = append(data, 'X')
		if i > 1 {
			mid := i / 2
			data[mid] = 'X'
			data[mid-1] = '\\'
			if c%2 == 0 {
				data[mid-2] = '\\'
			}
		}
		stagesne = append(stagesne, stage{data: data, pos: len(data) - 1})
		c++
	}
}

func TestIndexNE(t *testing.T) {
	for _, st := range stages {
		t.Run(strconv.Itoa(len(st.data)), func(t *testing.T) {
			pos := IndexAtNE(st.data, 'X', 0)
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
	}
}

func TestIndexNE64(t *testing.T) {
	for _, st := range stages64 {
		pos := IndexAtNE(st.data, 'X', 0)
		if pos != st.pos {
			t.Errorf("got %d, want %d", pos, st.pos)
		}
	}
}

func BenchmarkIndexNE(b *testing.B) {
	for _, st := range stages {
		b.Run(strconv.Itoa(len(st.data)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.data)))
			for i := 0; i < b.N; i++ {
				IndexAtNE(st.data, 'X', 0)
			}
		})
	}
}
