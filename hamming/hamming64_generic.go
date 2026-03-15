//go:build !amd64 || appengine || !gc || purego

package hamming

func hamming(a, b []uint64) int {
	return hammingGeneric(a, b)
}
