//go:build !amd64 || appengine || !gc || purego

package bitwise64

func xor(a, b []uint64) {
	xorGeneric(a, b)
}
