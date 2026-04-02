//go:build !amd64 || appengine || !gc || purego

package xorkey

func xorkey32(data, key []byte) {
	xorkeyGeneric(data, key)
}

func xorkey64(data, key []byte) {
	xorkeyGeneric(data, key)
}
