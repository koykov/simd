package bitwise64

import "golang.org/x/sys/cpu"

var funcAMD64 func([]uint64, []uint64)

func init() {
	// if cpu.X86.HasAVX512F && cpu.X86.HasAVX512VPOPCNTDQ {
	// 	funcAMD64 = mergeAVX512
	// 	return
	// }
	// if cpu.X86.HasAVX2 {
	// 	funcAMD64 = mergeAVX2
	// 	return
	// }
	if cpu.X86.HasSSE2 {
		funcAMD64 = mergeSSE2
		return
	}
	funcAMD64 = mergeGeneric
}

func merge(a, b []uint64) {
	funcAMD64(a, b)
}

//go:noescape
func mergeSSE2(a, b []uint64)

// //go:noescape
// func mergeAVX2(a, b []uint64)
//
// //go:noescape
// func mergeAVX512(a, b []uint64)
