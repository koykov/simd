package xorkey

import "golang.org/x/sys/cpu"

var func32AMD64, func64AMD64 func([]byte, []byte)

func init() {
	if cpu.X86.HasAVX2 {
		func32AMD64 = encode32AVX2
		func64AMD64 = encode64AVX2
		return
	}
	func32AMD64 = encodeGeneric
}

func encode32(dst, src []byte) {
	func32AMD64(dst, src)
}

func encode64(dst, src []byte) {
	func64AMD64(dst, src)
}

//go:noescape
func encode32AVX2([]byte, []byte)

//go:noescape
func encode64AVX2([]byte, []byte)
