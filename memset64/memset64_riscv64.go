package memset64

var funcRISCV64 func([]uint64, uint64)

func init() {
	if cpu.RISCV64.HasV {
		funcRISCV64 = memsetRISCV64
		return
	}
	funcRISCV64 = memset64Generic
}

func memset64(data []uint64, value uint64) {
	funcRISCV64(data, value)
}

//go:noescape
func memsetRISCV64([]uint64, uint64)
