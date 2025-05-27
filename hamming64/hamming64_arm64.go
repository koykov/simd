package hamming64

var funcARM64 func([]uint64, []uint64) int

func init() {
	if cpu.ARM64.HasASIMD {
		funcARM64 = hammingNEON
		return
	}
	funcARM64 = hammingGeneric
}

func hamming(a, b []uint64) int {
	return funcARM64(a, b)
}

//go:noescape
func hammingNEON([]uint64)
