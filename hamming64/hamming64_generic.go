//go:build (!amd64 && !arm64 && !ppc64le && !riscv64) || appengine || !gc || purego

package hamming64

func hamming(a, b []uint64) int {
	return hammingGeneric(a, b)
}
