//go:build (!amd64 && !arm64 && !ppc64le && !riscv64) || appengine || !gc || purego

package memclr64

func memclr64(data []uint64) {
	return memclrGeneric(data)
}
