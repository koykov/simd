//go:build !amd64 || appengine || !gc || purego

package bitwise64

func merge(a, b []uint64) {
	hammingGeneric(a, b)
}
