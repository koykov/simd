//go:build !amd64 || appengine || !gc || purego

package memclr

func memclr64(data []uint64) {
	memclr64Generic(data)
}
