package xorkey

import "golang.org/x/sys/cpu"

var funcAMD64 func([]byte, []byte)

func init() {
	// if cpu.X86.HasAVX512F {
	// 	funcAMD64 = encodeAVX512
	// 	return
	// }
	if cpu.X86.HasAVX2 {
		funcAMD64 = encodeAVX2
		return
	}
	// if cpu.X86.HasSSE2 {
	// 	funcAMD64 = encodeSSE2
	// 	return
	// }
	funcAMD64 = encodeGeneric
}

func encode(dst, src []byte) {
	funcAMD64(dst, src)
}

// //go:noescape
// func encodeSSE2([]byte, []byte)

//go:noescape
func encodeAVX2([]byte, []byte)

// //go:noescape
// func encodeAVX512([]byte, []byte)
