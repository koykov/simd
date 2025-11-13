package indexbyte

import (
	"strconv"
	"testing"
)

type stage struct {
	data []byte
	pos  int
}

var (
	stages   []stage
	stages64 []stage
)

func init() {
	for i := 1; i < 1e10; i *= 10 {
		data := make([]byte, i-1, i)
		data = append(data, 'X')
		stages = append(stages, stage{data: data, pos: len(data) - 1})
	}
	for i := 0; i < 64; i++ {
		data := make([]byte, 64)
		data[i] = 'X'
		stages64 = append(stages64, stage{data: data, pos: i})
	}
}

func TestIndex(t *testing.T) {
	for _, st := range stages {
		t.Run(strconv.Itoa(len(st.data)), func(t *testing.T) {
			pos := IndexAt(st.data, 'X', 0)
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
	}
}

func TestIndex64(t *testing.T) {
	for _, st := range stages64 {
		pos := IndexAt(st.data, 'X', 0)
		if pos != st.pos {
			t.Errorf("got %d, want %d", pos, st.pos)
		}
	}
}

func BenchmarkIndex(b *testing.B) {
	for _, st := range stages {
		b.Run(strconv.Itoa(len(st.data)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.data)))
			for i := 0; i < b.N; i++ {
				IndexAt(st.data, 'X', 0)
			}
		})
	}
}
