package indexbyte

var funcRISCV64 func([]byte, byte) int

func init() {
	if cpu.RISCV64.HasV {
		funcRISCV64 = indexbyteRISCV64
		return
	}
	funcRISCV64 = indexbyteGeneric
}

func indexbyte(b []byte, x byte) int {
	return funcRISCV64(b, x)
}

//go:noescape
func indexbyteRISCV64([]byte, byte) int
