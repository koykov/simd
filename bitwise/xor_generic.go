//go:build !amd64 || appengine || !gc || purego

package bitwise

func xor(a, b []uint64) {
	xorGeneric(a, b)
}
