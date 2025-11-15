package indextoken

//go:noescape
func indextokenSSE2(b []byte) int

//go:noescape
func indextokenAVX2(b []byte) int
