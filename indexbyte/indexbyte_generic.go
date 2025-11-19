//go:build (!amd64 && !arm64) || appengine || !gc || purego

package indexbyte

func indexbyte(b []byte, x byte) (i int) {
	return indexbyteGeneric(b, x)
}
