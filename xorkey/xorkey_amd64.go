package xorkey

import "golang.org/x/sys/cpu"

var func32AMD64, func64AMD64 func([]byte, []byte)

func init() {
	// if cpu.X86.HasAVX512F {
	// 	func32AMD64 = encodeAVX512
	// 	return
	// }
	if cpu.X86.HasAVX2 {
		func32AMD64 = encode32AVX2
		func64AMD64 = encode64AVX2
		return
	}
	// if cpu.X86.HasSSE2 {
	// 	func32AMD64 = encodeSSE2
	// 	return
	// }
	func32AMD64 = encodeGeneric
}

func encode32(dst, src []byte) {
	func32AMD64(dst, src)
}

func encode64(dst, src []byte) {
	func64AMD64(dst, src)
}

// //go:noescape
// func encode32SSE2([]byte, []byte)

//go:noescape
func encode32AVX2([]byte, []byte)

//go:noescape
func encode64AVX2([]byte, []byte)

// //go:noescape
// func encode32AVX512([]byte, []byte)
