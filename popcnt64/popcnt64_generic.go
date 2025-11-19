//go:build (!amd64 && !arm64) || appengine || !gc || purego

package popcnt64

func count(data []uint64) uint64 {
	return countGeneric(data)
}
