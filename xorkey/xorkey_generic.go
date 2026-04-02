//go:build !amd64 || appengine || !gc || purego

package xorkey

func xorkey32(data, key []byte) {
	xorkey32Generic(data, key)
}
