package indextoken

import (
	"math"
	"unsafe"
)

const (
	flagKeepSQB   = uint64(1) << 63
	flagKeepAt    = uint64(1) << 62
	maskKeepFlags = uint64(math.MaxUint64) ^ (flagKeepSQB | flagKeepAt)
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

func (t *Tokenizer[T]) KeepAt() *Tokenizer[T] {
	t.off = t.off | flagKeepAt
	return t
}

func (t *Tokenizer[T]) Next(b T) (r T) {
	sh := *(*sheader)(unsafe.Pointer(&b))
	h := header{data: sh.data, len: sh.len, cap: sh.len}
	p := *(*[]byte)(unsafe.Pointer(&h))
	var i int
	for i != -1 {
		off := t.offm()
		if off >= uint64(len(b)) {
			return
		}
		i = IndexAt(p, int(off))
		if i < 0 {
			i = len(p)
		}
		s := p[off:i]
		if t.sqb() && off > 0 && b[off-1] == '[' && i < len(b) && b[i] == ']' {
			if s = p[off-1 : i+1]; len(s) == 2 {
				s = s[:0]
			}
		}
		if t.at() && off > 0 && b[off-1] == '@' {
			// todo implement me
		}
		t.offs(i + 1)
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
	return t.off & maskKeepFlags
}

func (t *Tokenizer[T]) offs(v int) {
	flag := t.off & flagKeepSQB
	t.off = uint64(v) | flag
}

func (t *Tokenizer[T]) sqb() bool {
	return t.off&flagKeepSQB != 0
}

func (t *Tokenizer[T]) at() bool {
	return t.off&flagKeepAt != 0
}

type sheader struct {
	data uintptr
	len  int
}

type header struct {
	data     uintptr
	len, cap int
}
