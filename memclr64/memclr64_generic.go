//go:build (!amd64 && !arm64) || appengine || !gc || purego

package memclr64

func memclr64(data []uint64) {
	memclr64Generic(data)
}
