package bitwise64

import (
	"math/bits"
	"strconv"
	"testing"
)

type stage struct {
	a, b []uint64
	res  int
}

type stageBytes struct {
	a, b []byte
	res  int
}

func testfn(t *testing.T, stages []stage, fn func([]uint64, []uint64)) {
	for i := 0; i < len(stages); i++ {
		st := &stages[i]
		t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
			cpy := make([]uint64, len(st.a))
			copy(cpy, st.a)
			fn(cpy, st.b)
			var res int
			for j := 0; j < len(cpy); j++ {
				res += bits.OnesCount64(cpy[j])
			}
			if res != st.res {
				t.Errorf("got %v, want %v", res, st.res)
			}
		})
	}
}

func testfnBytes(t *testing.T, stages []stageBytes, fn func([]byte, []byte)) {
	for i := 0; i < len(stages); i++ {
		st := &stages[i]
		t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
			cpy := make([]byte, len(st.a))
			copy(cpy, st.a)
			fn(cpy, st.b)
			var res int
			for j := 0; j < len(cpy); j++ {
				res += bits.OnesCount8(cpy[j])
			}
			if res != st.res {
				t.Errorf("got %v, want %v", res, st.res)
			}
		})
	}
}

func benchfn(b *testing.B, stages []stage, fn func([]uint64, []uint64)) {
	for i := 0; i < len(stages); i++ {
		st := &stages[i]
		b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
			b.SetBytes(int64(len(st.a)) * 2 * 8)
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				fn(st.a, st.b)
			}
		})
	}
}

func benchfnBytes(b *testing.B, stages []stageBytes, fn func([]byte, []byte)) {
	for i := 0; i < len(stages); i++ {
		st := &stages[i]
		b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
			b.SetBytes(int64(len(st.a)) * 2)
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				fn(st.a, st.b)
			}
		})
	}
}
