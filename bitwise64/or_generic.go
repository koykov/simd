//go:build !amd64 || appengine || !gc || purego

package bitwise64

func or(a, b []uint64) {
	orGeneric(a, b)
}
