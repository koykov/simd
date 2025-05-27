package hamming64

var funcRISCV64 func([]uint64, []uint64) int

func init() {
	if cpu.RISCV64.HasV && cpu.RISCV64.HasZbb {
		funcRISCV64 = hammingRISCV64
		return
	}
	funcRISCV64 = hammingGeneric
}

func hamming(a, b []uint64) int {
	return funcRISCV64(a, b)
}

//go:noescape
func hammingRISCV64(a, b []uint64) int
