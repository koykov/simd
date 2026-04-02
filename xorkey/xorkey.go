package xorkey

func Encode32(data []byte, key [32]byte) {
	encode32(data, key[:])
}

func Encode64(data []byte, key [64]byte) {
	encode64(data, key[:])
}

func encodeGeneric(data, key []byte) {
	n, m := len(data), len(key)
	if n == 0 || m == 0 {
		return
	}
	_, _ = data[n-1], key[m-1]
	for i := 0; i < n; i++ {
		data[i] ^= key[i%m]
	}
}
