package skipline

import (
	"strconv"
	"testing"
)

type stage struct {
	data  []byte
	pos   int
	posnl int
}

var stages []stage

func init() {
	var c int
	for i := 1; i < 1e10; i *= 10 {
		data := make([]byte, i-1, i)
		nl := 1
		switch c % 3 {
		case 0:
			data = append(data, '\n')
		case 1:
			data = append(data, '\r')
		case 2:
			data = append(data, '\n')
			data[len(data)-2] = '\r'
			nl = 2
		}
		stages = append(stages, stage{
			data:  data,
			pos:   len(data) - nl,
			posnl: len(data),
		})
		c++
	}
}

func TestIndex(t *testing.T) {
	for _, st := range stages {
		t.Run(strconv.Itoa(len(st.data)), func(t *testing.T) {
			pos := Index(st.data)
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
	}
}

func TestIndex2(t *testing.T) {
	for _, st := range stages {
		t.Run(strconv.Itoa(len(st.data)), func(t *testing.T) {
			pos, posnl := Index2(st.data)
			if pos != st.pos || posnl != st.posnl {
				t.Errorf("got %d/%d, want %d/%d", pos, st.pos, posnl, st.posnl)
			}
		})
	}
}

func BenchmarkIndex(b *testing.B) {
	for _, st := range stages {
		b.Run(strconv.Itoa(len(st.data)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.data)))
			for i := 0; i < b.N; i++ {
				Index(st.data)
			}
		})
	}
}

func BenchmarkIndex2(b *testing.B) {
	for _, st := range stages {
		b.Run(strconv.Itoa(len(st.data)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.data)))
			for i := 0; i < b.N; i++ {
				Index2(st.data)
			}
		})
	}
}
