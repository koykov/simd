//go:build !amd64 || appengine || !gc || purego

package memcpy

func memcpy64(data []uint64) {
	memcpy64Generic(data)
}
