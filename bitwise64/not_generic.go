//go:build !amd64 || appengine || !gc || purego

package bitwise64

func not(a []uint64) {
	notGeneric(a)
}
