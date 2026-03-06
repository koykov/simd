package memcpy64

func Copy(dst, src []uint64) {
	memcpy64(dst, src)
}

func memcpy64Generic(dst, src []uint64) {
	copy(dst, src)
}
