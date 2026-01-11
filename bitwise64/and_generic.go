//go:build !amd64 || appengine || !gc || purego

package bitwise64

func and(a, b []uint64) {
	andGeneric(a, b)
}
