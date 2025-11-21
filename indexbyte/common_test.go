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
	stagesne []stage
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

func testfn(t *testing.T, fn func([]byte, byte) int) {
	for i := 0; i < len(stages); i++ {
		st := &stages[i]
		t.Run(strconv.Itoa(len(st.data)), func(t *testing.T) {
			pos := fn(st.data, 'X')
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
	}
}

func testfn64(t *testing.T, fn func([]byte, byte) int) {
	for i := 0; i < len(stages64); i++ {
		st := &stages64[i]
		t.Run(strconv.Itoa(len(st.data)), func(t *testing.T) {
			pos := fn(st.data, 'X')
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
	}
}

func benchfn(b *testing.B, fn func([]byte, byte) int) {
	for i := 0; i < len(stages); i++ {
		st := &stages[i]
		b.Run(strconv.Itoa(len(st.data)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.data)))
			for i := 0; i < b.N; i++ {
				fn(st.data, 'X')
			}
		})
	}
}
