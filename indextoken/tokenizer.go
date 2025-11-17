package indextoken

import "unsafe"

type byteseq interface {
	~string | ~[]byte
}

type Tokenizer[T byteseq] int

func (t *Tokenizer[T]) Next(b T) T {
	sh := *(*sheader)(unsafe.Pointer(&b))
	h := header{data: sh.data, len: sh.len, cap: sh.len}
	p := *(*[]byte)(unsafe.Pointer(&h))
	i := IndexAt(p, int(*t))
	if i < 0 {
		i = len(p)
	}
	s := p[*t:i]
	r := *(*T)(unsafe.Pointer(&s))
	return r
}

type sheader struct {
	data uintptr
	len  int
}

type header struct {
	data     uintptr
	len, cap int
}
