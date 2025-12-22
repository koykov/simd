//go:build !amd64 || appengine || !gc || purego

package indextoken

func indextoken(b []byte) int {
	return indextokenGeneric(b)
}
