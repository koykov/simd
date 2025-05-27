//go:build (!amd64 && !arm64 && !ppc64le && !riscv64) || appengine || !gc || purego

package skipline

func skipline(p []byte) int {
	return skiplineGeneric(p)
}
