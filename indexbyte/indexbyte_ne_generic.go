//go:build !amd64 || appengine || !gc || purego

package indexbyte

func indexbytene(b []byte, x byte) (i int) {
	return indexbyteneGeneric(b, x)
}
