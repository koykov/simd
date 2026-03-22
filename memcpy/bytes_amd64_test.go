//go:build amd64

package memcpy

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

func TestCopy(t *testing.T) {
	t.Run("generic", func(t *testing.T) { btestfn(t, memcpy64Generic) })
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { btestfn(t, memcpyAVX512) })
		t.Run("integrity", func(t *testing.T) {
			sz := 10 * 1024 * 1024
			data := make([]byte, sz)
			for i := 0; i < sz; i++ {
				data[i] = byte(i % 256)
			}
			chunksz := 1024 * 1024
			for offset := 0; offset < sz; offset += chunksz {
				copysz := chunksz
				if offset+chunksz > sz {
					copysz = sz - offset
				}

				buf := make([]byte, copysz)
				copy(buf, data[offset:offset+copysz])
				for i := 0; i < copysz; i++ {
					if buf[i] != data[offset+i] {
						t.Errorf("Data mismatch at offset %d/%d: got %d, want %d",
							i, offset+i, buf[i], data[offset+i])
						break
					}
				}
			}
		})
	}
}

func BenchmarkCopy(b *testing.B) {
	b.Run("generic", func(b *testing.B) { bbenchfn(b, memcpy64Generic) })
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512VL {
		b.Run("avx512", func(b *testing.B) { bbenchfn(b, memcpyAVX512) })
	}
}
