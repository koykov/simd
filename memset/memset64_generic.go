//go:build !amd64 || appengine || !gc || purego

package memset

func memset64(p []uint64, value uint64) {
	memset64Generic(p, value)
}
