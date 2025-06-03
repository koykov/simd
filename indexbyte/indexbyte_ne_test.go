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

func indexnetest(b []byte, x byte, fn func([]byte, byte) int) (i int) {
	n := len(b)
	if n < 128 {
		return indexbyteneGeneric(b, x)
	}
	n64 := n - n%64
	if i = fn(b[:n64], x); i >= 0 {
		return i
	}
	if i = indexbyteneGeneric(b[n64:], x); i >= 0 {
		return n64 + i
	}
	return -1
}

func TestIndexNE(t *testing.T) {
	for _, st := range stages {
		t.Run(strconv.Itoa(len(st.data)), func(t *testing.T) {
			t.Run("generic", func(t *testing.T) {
				pos := indexbyteGeneric(st.data, 'X')
				if pos != st.pos {
					t.Errorf("got %d, want %d", pos, st.pos)
				}
			})
			t.Run("sse2", func(t *testing.T) {
				pos := indexnetest(st.data, 'X', indexbyteneSSE2)
				if pos != st.pos {
					t.Errorf("got %d, want %d", pos, st.pos)
				}
			})
			t.Run("avx2", func(t *testing.T) {
				pos := indexnetest(st.data, 'X', indexbyteneAVX2)
				if pos != st.pos {
					t.Errorf("got %d, want %d", pos, st.pos)
				}
			})
			t.Run("avx512", func(t *testing.T) {
				pos := indexnetest(st.data, 'X', indexbyteneAVX512)
				if pos != st.pos {
					t.Errorf("got %d, want %d", pos, st.pos)
				}
			})
		})
	}
}

func TestIndexNE64(t *testing.T) {
	for _, st := range stages64 {
		t.Run("generic", func(t *testing.T) {
			pos := indexbyteneGeneric(st.data, 'X')
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
		t.Run("sse2", func(t *testing.T) {
			pos := indexnetest(st.data, 'X', indexbyteneSSE2)
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
		t.Run("avx2", func(t *testing.T) {
			pos := indexnetest(st.data, 'X', indexbyteneAVX2)
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
		t.Run("avx512", func(t *testing.T) {
			pos := indexnetest(st.data, 'X', indexbyteneAVX512)
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		})
	}
}

func BenchmarkIndexNE(b *testing.B) {
	for _, st := range stages {
		b.Run(strconv.Itoa(len(st.data)), func(b *testing.B) {
			b.Run("generic", func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.data)))
				for i := 0; i < b.N; i++ {
					indexbyteneGeneric(st.data, 'X')
				}
			})
			b.Run("sse2", func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.data)))
				for i := 0; i < b.N; i++ {
					indexnetest(st.data, 'X', indexbyteneSSE2)
				}
			})
			b.Run("avx2", func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.data)))
				for i := 0; i < b.N; i++ {
					indexnetest(st.data, 'X', indexbyteneAVX2)
				}
			})
			b.Run("avx512", func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.data)))
				for i := 0; i < b.N; i++ {
					indexnetest(st.data, 'X', indexbyteneAVX512)
				}
			})
		})
	}
}
