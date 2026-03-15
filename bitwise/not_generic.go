//go:build !amd64 || appengine || !gc || purego

package bitwise

func not(a []uint64) {
	notGeneric(a)
}
