package indextoken

import "golang.org/x/sys/cpu"

var funcPPC64LE func([]byte) int

func init() {
	if cpu.PPC64.HasVMX && cpu.PPC64.HasVSX {
		funcPPC64LE = indextokenPPC64LE
		return
	}
	funcPPC64LE = indextokenGeneric
}

func indextoken(b []byte) int {
	return funcPPC64LE(b)
}

//go:noescape
func indextokenPPC64LE([]byte) int
