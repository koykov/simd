package indextoken

import "unsafe"

type byteseq interface {
	~string | ~[]byte
}

type Tokenizer[T byteseq] struct {
	off int
}

func (t *Tokenizer[T]) Next(b T) (r T) {
	sh := *(*sheader)(unsafe.Pointer(&b))
	h := header{data: sh.data, len: sh.len, cap: sh.len}
	p := *(*[]byte)(unsafe.Pointer(&h))
	var i int
	for i != -1 {
		if t.off >= len(b) {
			return
		}
		i = IndexAt(p, t.off)
		if i < 0 {
			i = len(p)
		}
		s := p[t.off:i]
		t.off = i + 1
		if len(s) == 0 {
			continue
		}
		r = *(*T)(unsafe.Pointer(&s))
		return
	}
	return
}

type sheader struct {
	data uintptr
	len  int
}

type header struct {
	data     uintptr
	len, cap int
}
