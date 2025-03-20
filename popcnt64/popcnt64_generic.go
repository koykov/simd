//go:build (!amd64 && !arm64) || appengine || !gc || purego

package popcnt64

func popcnt64(data []uint64) uint64 {
	return popcnt64generic(data)
}
