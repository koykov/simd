package memcpy64

// Copy copies contents of src to dst.
// !CAUTION: length of dst must be greater of equal to length of src. You must ensure that.
func Copy(dst, src []uint64) {
	memcpy64(dst, src)
}

func memcpy64Generic(dst, src []uint64) {
	copy(dst, src)
}
