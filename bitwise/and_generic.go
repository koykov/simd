//go:build !amd64 || appengine || !gc || purego

package bitwise

func and(a, b []uint64) {
	andGeneric(a, b)
}
