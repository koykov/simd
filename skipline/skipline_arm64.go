package skipline

var funcARM64 func([]byte) int

func init() {
	if cpu.ARM64.HasASIMD {
		funcARM64 = skiplineNEON
		return
	}
	funcARM64 = skiplineGeneric
}

func skipline(b []byte) int {
	return funcARM64(b)
}

//go:noescape
func skiplineNEON([]byte)
