package skipline

import "math"

var table [math.MaxUint8]bool

func init() {
	table['\n'] = true
	table['\r'] = true
}
