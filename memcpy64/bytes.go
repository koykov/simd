package memcpy64

import "unsafe"

// CopyBytes copies src to dst.
// !CAUTION: length of dst must be greater of equal to length of src. You must ensure that.
func CopyBytes(dst, src []byte) {
	const blocksz = 32
	n := len(src)
	if n == 0 {
		return
	}
	if n >= blocksz {
		n64 := (n - n%blocksz) / 8
		type sh struct {
			p    uintptr
			l, c int
		}
		hsrc := sh{p: uintptr(unsafe.Pointer(&src[0])), l: n64, c: n64}
		psrc64 := *(*[]uint64)(unsafe.Pointer(&hsrc))
		hdst := sh{p: uintptr(unsafe.Pointer(&dst[0])), l: n64, c: n64}
		pdst64 := *(*[]uint64)(unsafe.Pointer(&hdst))
		memcpy64(pdst64, psrc64)
		src = src[n64*8:]
		dst = dst[n64*8:]
		n = len(src)
	}
	copy(dst, src)
}
