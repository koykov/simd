//go:build !amd64 || appengine || !gc || purego

package popcnt

func count(data []uint64) uint64 {
	return countGeneric(data)
}
