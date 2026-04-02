package xorkey

import (
	"bytes"
	"strconv"
	"testing"

	"golang.org/x/sys/cpu"
)

type stage struct {
	data     []byte
	r32, r64 []byte
}

var (
	stages   []stage
	k32, k64 = []byte("LfnboP5fe869pbsHlYtkl5zYapd8YFT6"), []byte("rofuo4ceDEv1wKgt0HrLp0TeXDhWQZqANeRaa7xqseV5OtBSprp5qclBGDCHhGf0")
)

func init() {
	source := [][]byte{
		[]byte("qwe"),
		[]byte("foobar"),
		[]byte("Lorem ipsum dolor sit amet..."),
		[]byte("Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
		[]byte("Aliquam blandit mauris mauris, eget bibendum lacus tempus non. Duis orci leo, sagittis sed lorem eu, pulvinar elementum leo."),
		[]byte("Nunc lacinia, purus finibus consectetur ullamcorper, nisi elit laoreet augue, vitae tincidunt tellus velit sit amet arcu. Quisque sit amet viverra ligula. Praesent sagittis, sapien ut rutrum porttitor, dolor ligula accumsan velit, ut lacinia tellus tellus nec tortor. Aliquam blandit mauris mauris, eget bibendum lacus tempus non. Duis orci leo, sagittis sed lorem eu, pulvinar elementum leo."),
	}
	for i := 0; i < 12; i++ {
		src := source[len(source)-1]
		source = append(source, append(src, src...))
	}

	for i := 0; i < len(source); i++ {
		n := len(source[i])
		buf := make([]byte, n*2)
		r32, r64 := buf[:n], buf[n:]
		copy(r32, source[i])
		copy(r64, source[i])
		encodeGeneric(r32, k32)
		encodeGeneric(r64, k64)
		stg := stage{
			data: source[i],
			r32:  r32,
			r64:  r64,
		}
		stages = append(stages, stg)
	}
}

func TestEncode(t *testing.T) {
	testfn32 := func(t *testing.T, fn func([]byte, []byte)) {
		for i := 0; i < len(stages); i++ {
			stg := &stages[i]
			t.Run(strconv.Itoa(len(stg.data)), func(t *testing.T) {
				t.Run("32", func(t *testing.T) {
					dst := make([]byte, len(stg.data))
					copy(dst, stg.data)
					fn(dst, k32)
					if !bytes.Equal(dst, stg.r32) {
						t.Fail()
					}
				})
			})
		}
	}
	t.Run("generic", func(t *testing.T) { testfn32(t, encodeGeneric) })
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn32(t, encode32AVX2) })
	}
}

func BenchmarkEncode(b *testing.B) {
	benchfn32 := func(b *testing.B, fn func([]byte, []byte)) {
		for i := 0; i < len(stages); i++ {
			stg := &stages[i]
			b.Run(strconv.Itoa(len(stg.data)), func(b *testing.B) {
				b.Run("32", func(b *testing.B) {
					dst := make([]byte, len(stg.data))
					copy(dst, stg.data)
					b.ResetTimer()
					b.ReportAllocs()
					b.SetBytes(int64(len(stg.data)))
					for j := 0; j < b.N; j++ {
						fn(dst, k32)
					}
				})
			})
		}
	}
	b.Run("generic", func(b *testing.B) { benchfn32(b, encodeGeneric) })
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn32(b, encode32AVX2) })
	}
}
