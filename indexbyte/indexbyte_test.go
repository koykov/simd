package indexbyte

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
		data := make([]byte, i-1, i)
		data = append(data, 'X')
		stages = append(stages, stage{data: data, pos: len(data) - 1})
	}
}

func indextest(b []byte, x byte, fn func([]byte, byte) int) (i int) {
	n := len(b)
	if n < 64 {
		return indexbyteGeneric(b, x)
	}
	n64 := n - n%64
	if i = fn(b[:n64], x); i >= 0 {
		return i
	}
	if i = indexbyteGeneric(b[n64:], x); i >= 0 {
		return n64 + i
	}
	return -1
}

func TestIndex(t *testing.T) {
	for _, st := range stages {
		t.Run(strconv.Itoa(len(st.data)), func(t *testing.T) {
			t.Run("generic", func(t *testing.T) {
				pos := indexbyteGeneric(st.data, 'X')
				if pos != st.pos {
					t.Errorf("got %d, want %d", pos, st.pos)
				}
			})
		})
		t.Run("sse2", func(t *testing.T) {
			pos := indextest(st.data, 'X', indexbyteSSE2)
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
		t.Run("sse2", func(t *testing.T) {
			pos := indextest(st.data, 'X', indexbyteAVX2)
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
	}
}

func BenchmarkIndex(b *testing.B) {
	for _, st := range stages {
		b.Run(strconv.Itoa(len(st.data)), func(b *testing.B) {
			b.Run("generic", func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.data)))
				for i := 0; i < b.N; i++ {
					indexbyteGeneric(st.data, 'X')
				}
			})
			b.Run("sse2", func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.data)))
				for i := 0; i < b.N; i++ {
					indextest(st.data, 'X', indexbyteSSE2)
				}
			})
			b.Run("avx2", func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.data)))
				for i := 0; i < b.N; i++ {
					indextest(st.data, 'X', indexbyteAVX2)
				}
			})
		})
	}
}
