//go:build !amd64 || appengine || !gc || purego

package skipline

func skipline(p []byte) int {
	return skiplineGeneric(p)
}
