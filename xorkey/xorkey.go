package xorkey

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
