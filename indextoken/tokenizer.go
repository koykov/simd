package indextoken

import (
	"math"
	"unsafe"
)

const (
	flagKeepSQB = uint64(1) << 63
	maskKeepSQB = uint64(math.MaxUint64) ^ flagKeepSQB
)

type byteseq interface {
	~string | ~[]byte
}

type Tokenizer[T byteseq] struct {
	off uint64
}

func (t *Tokenizer[T]) KeepSquareBrackets() *Tokenizer[T] {
	t.off = t.off | flagKeepSQB
	return t
}

func (t *Tokenizer[T]) Next(b T) (r T) {
	sh := *(*sheader)(unsafe.Pointer(&b))
	h := header{data: sh.data, len: sh.len, cap: sh.len}
	p := *(*[]byte)(unsafe.Pointer(&h))
	var i int
	for i != -1 {
		if t.offm() >= uint64(len(b)) {
			return
		}
		i = IndexAt(p, int(t.offm()))
		if i < 0 {
			i = len(p)
		}
		s := p[t.offm():i]
		t.offinc(i + 1)
		if len(s) == 0 {
			continue
		}
		r = *(*T)(unsafe.Pointer(&s))
		return
	}
	return
}

func (t *Tokenizer[T]) Reset() {
	t.off = 0
}

func (t *Tokenizer[T]) offm() uint64 {
	return t.off & maskKeepSQB
}

func (t *Tokenizer[T]) offinc(d int) {
	off := t.offm()
	flag := t.off & flagKeepSQB
	off += uint64(d)
	t.off = off | flag
}

type sheader struct {
	data uintptr
	len  int
}

type header struct {
	data     uintptr
	len, cap int
}
