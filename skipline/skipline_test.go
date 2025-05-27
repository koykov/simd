package skipline

import (
	"strconv"
	"testing"
)

type stage struct {
	data []byte
	pos  int
}

var stages []stage

func init() {
	for i := 1; i < 1e10; i *= 10 {
		data := make([]byte, i)
		data = append(data, '\n')
		stages = append(stages, stage{data: data, pos: len(data) - 1})
	}
}

func TestSkipLine(t *testing.T) {
	for _, st := range stages {
		t.Run(strconv.Itoa(len(st.data)), func(t *testing.T) {
			pos := skipline(st.data)
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
	}
}

func BenchmarkSkipLine(b *testing.B) {
	for _, st := range stages {
		b.Run(strconv.Itoa(len(st.data)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.data)))
			for i := 0; i < b.N; i++ {
				skipline(st.data)
			}
		})
	}
}
