package skipline

var funcRISCV64 func([]byte) int

func init() {
	if cpu.RISCV64.HasV {
		funcRISCV64 = skiplineRISCV64
		return
	}
	funcRISCV64 = skiplineGeneric
}

func hamming(b []byte) int {
	return funcRISCV64(a, b)
}

//go:noescape
func skiplineRISCV64(b []byte) int
