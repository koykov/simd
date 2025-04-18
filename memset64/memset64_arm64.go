package memset64

var funcARM64 func([]uint64, uint64)

func init() {
	if cpu.ARM64.HasASIMD {
		funcARM64 = memsetNEON
		return
	}
	funcARM64 = memset64Generic
}

func memset64(data []uint64, value uint64) {
	funcARM64(data, value)
}

//go:noescape
func memsetNEON([]uint64, uint64)
