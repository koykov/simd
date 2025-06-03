package indexbyte

var funcneRISCV64 func([]byte, byte) int

func init() {
	if cpu.RISCV64.HasV {
		funcneRISCV64 = indexbyteneRISCV64
		return
	}
	funcneRISCV64 = indexbyteneGeneric
}

func indexbytene(b []byte, x byte) int {
	return funcneRISCV64(b, x)
}

//go:noescape
func indexbyteneRISCV64([]byte, byte) int
