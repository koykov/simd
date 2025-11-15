package indextoken

import (
	"strconv"
	"testing"

	"golang.org/x/sys/cpu"
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
		data = append(data, '.')
		stages = append(stages, stage{data: data, pos: len(data) - 1})
	}
	for i := 0; i < 64; i++ {
		data := make([]byte, 64)
		data[i] = '.'
		stages64 = append(stages64, stage{data: data, pos: i})
	}
}

func TestIndex(t *testing.T) {
	testfn := func(t *testing.T, fn func([]byte) int) {
		for _, st := range stages {
			t.Run(strconv.Itoa(len(st.data)), func(t *testing.T) {
				pos := fn(st.data)
				if pos != st.pos {
					t.Errorf("got %d, want %d", pos, st.pos)
				}
			})
		}
	}
	t.Run("generic", func(t *testing.T) { testfn(t, indextokenGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, indextokenSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, indextokenAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { testfn(t, indextokenAVX512) })
	}
}

func TestIndex64(t *testing.T) {
	testfn := func(t *testing.T, fn func([]byte) int) {
		for _, st := range stages64 {
			pos := Index(st.data)
			if pos != st.pos {
				t.Errorf("got %d, want %d", pos, st.pos)
			}
		}
	}
	t.Run("generic", func(t *testing.T) { testfn(t, indextokenGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, indextokenSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, indextokenAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { testfn(t, indextokenAVX512) })
	}
}

func BenchmarkIndex(b *testing.B) {
	benchfn := func(b *testing.B, fn func([]byte) int) {
		for _, st := range stages {
			b.Run(strconv.Itoa(len(st.data)), func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.data)))
				for i := 0; i < b.N; i++ {
					fn(st.data)
				}
			})
		}
	}
	b.Run("generic", func(b *testing.B) { benchfn(b, indextokenGeneric) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, indextokenSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, indextokenAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		b.Run("avx512", func(b *testing.B) { benchfn(b, indextokenAVX512) })
	}
}
