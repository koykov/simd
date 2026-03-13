//go:build amd64

package memcpy64

import (
	"math"
	"strconv"
	"testing"

	"golang.org/x/sys/cpu"
)

type bstage struct {
	dst, src []byte
}

var bstages []bstage

func init() {
	for i := 1; i < 1e10; i *= 10 {
		src := make([]byte, i-1)
		for j := 0; j < len(src)-1; j++ {
			src[j] = math.MaxUint8
		}
		dst := make([]byte, i)
		bstages = append(bstages, bstage{dst: dst, src: src})
	}
}

func btestfn(t *testing.T, fn func([]uint64, []uint64)) {
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

func bbenchfn(b *testing.B, fn func([]uint64, []uint64)) {
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

func TestMemcpy64Bytes(t *testing.T) {
	t.Run("generic", func(t *testing.T) { btestfn(t, memcpy64Generic) })
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { btestfn(t, memcpyAVX512) })
	}
}

func BenchmarkMemcpy64Bytes(b *testing.B) {
	b.Run("generic", func(b *testing.B) { bbenchfn(b, memcpy64Generic) })
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512VL {
		b.Run("avx512", func(b *testing.B) { bbenchfn(b, memcpyAVX512) })
	}
}
