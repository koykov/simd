package indextoken

var funcRISCV64 func([]byte) int

func init() {
	if cpu.RISCV64.HasV {
		funcRISCV64 = indextokenRISCV64
		return
	}
	funcRISCV64 = indextokenGeneric
}

func indextoken(b []byte) int {
	return funcRISCV64(b)
}

//go:noescape
func indextokenRISCV64([]byte) int
