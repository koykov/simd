//go:build (!amd64 && !arm64) || appengine || !gc || purego

package memset64

func memset64(data []uint64) {
	memset64Generic(data)
}
