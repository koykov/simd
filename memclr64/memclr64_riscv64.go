package memclr64

var funcRISCV64 func([]uint64)

func init() {
	if cpu.RISCV64.HasV {
		funcRISCV64 = popcnt64RISCV64
		return
	}
	funcRISCV64 = memclr64Generic
}

func memclr64(data []uint64) {
	funcRISCV64(data)
}

//go:noescape
func memclrRISCV64([]uint64)
