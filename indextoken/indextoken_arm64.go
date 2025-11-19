package indextoken

import "golang.org/x/sys/cpu"

var funcARM64 func([]byte) int

func init() {
	if cpu.ARM64.HasASIMD {
		funcARM64 = indextokenNEON
		return
	}
	funcARM64 = indextokenGeneric
}

func indextoken(b []byte) int {
	return funcARM64(b, x)
}

//go:noescape
func indextokenNEON([]byte)
