//go:build amd64

package memcpy

import (
	"math"
	"strconv"
	"testing"

	"golang.org/x/sys/cpu"
)

type stage struct {
	dst, src []uint64
}

var stages []stage

func init() {
	for i := 10; i < 1e9; i *= 10 {
		src := make([]uint64, i-1)
		for j := 0; j < len(src)-1; j++ {
			src[j] = math.MaxUint64
		}
		dst := make([]uint64, i)
		stages = append(stages, stage{dst: dst, src: src})
	}
}

func testfn(t *testing.T, fn func([]uint64, []uint64)) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		t.Run(strconv.Itoa(len(st.dst)), func(t *testing.T) {
			fn(st.dst, st.src)
			for j := 0; j < len(st.src); j++ {
				if st.dst[j] != st.src[j] {
					t.Errorf("mismatch found, position %d", j)
				}
			}
		})
	}
}

func benchfn(b *testing.B, fn func([]uint64, []uint64)) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		b.Run(strconv.Itoa(len(st.dst)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.dst) * 8))
			for j := 0; j < b.N; j++ {
				fn(st.dst, st.src)
			}
		})
	}
}

func TestCopy64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, memcpy64Generic) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, memcpySSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, memcpyAVX2) })
	}
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfn(t, memcpyAVX512) })
	}
}

func BenchmarkCopy64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, memcpy64Generic) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, memcpySSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, memcpyAVX2) })
	}
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfn(b, memcpyAVX512) })
	}
}
