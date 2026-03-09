# Memcpy64

Vectorised memory copying of array of uint64 number.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/memcpy64"

var a = []uint64{0xFFFFFFFFFFFFFFFF, ..., 0xFFFFFFFFFFFFFFFF} // very big slice
dst := make([]uint64, len(a))
memcpy64.Copy(dst, a)
println(dst) // the same contents
```

The solution is optimized for very long input data.

## Copy bytes slice

Package also provides [`CopyBytes`](bytes.go) method, that copies bytes slice.

## Copy raw memory

Package provides unsafe version [CopyUnsafe](unsafe.go) method. Use with caution! Pointers must point to a memory blocks
without heap pointers, memory leak may occur otherwise.

## Performance

Comparison between native `copy` function and memcpy64.Copy - copy contents of array of uint64 numbers:
```
BenchmarkMemcpy64/generic/1-8                        477337251            2.519 ns/op   3175.67 MB/s           0 B/op          0 allocs/op
BenchmarkMemcpy64/generic/10-8                       250577528            4.724 ns/op   16935.12 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64/generic/100-8                      120206377            9.938 ns/op   80502.87 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64/generic/1000-8                      24401158            48.74 ns/op   164132.56 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64/generic/10000-8                       783532             1522 ns/op   52571.69 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64/generic/100000-8                       46424            24912 ns/op   32112.84 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64/generic/1000000-8                       3560           336108 ns/op   23801.89 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64/generic/10000000-8                       204          5932172 ns/op   13485.78 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64/generic/100000000-8                       18         59297315 ns/op   13491.34 MB/s          0 B/op          0 allocs/op

BenchmarkMemcpy64/avx512/1-8                         599937378            2.004 ns/op   3992.02 MB/s           0 B/op          0 allocs/op
BenchmarkMemcpy64/avx512/10-8                        330919657            3.625 ns/op   22069.55 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64/avx512/100-8                       234558537            5.166 ns/op   154860.16 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64/avx512/1000-8                      130547935            9.507 ns/op   841456.12 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64/avx512/10000-8                      17826741            66.98 ns/op   1194374.64 MB/s        0 B/op          0 allocs/op
BenchmarkMemcpy64/avx512/100000-8                       632268             1868 ns/op   428229.94 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64/avx512/1000000-8                       30918            38747 ns/op   206469.49 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64/avx512/10000000-8                       1968           529545 ns/op   151072.98 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64/avx512/100000000-8                       160          7416167 ns/op   107872.44 MB/s         0 B/op          0 allocs/op
```

Comparison between native `copy` function and memcpy64.CopyBytes - copy contents of byte slice:
```
BenchmarkMemcpy64Bytes/generic/1-8                 472139922              2.654 ns/op   3014.80 MB/s           0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/generic/10-8                254690968              4.739 ns/op   16882.73 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/generic/100-8               120304629              9.933 ns/op   80542.04 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/generic/1000-8               24764682              48.75 ns/op   164114.52 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/generic/10000-8                775286               1521 ns/op   52602.63 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/generic/100000-8                47355              24802 ns/op   32255.47 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/generic/1000000-8                2889             349115 ns/op   22915.06 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/generic/10000000-8                195            5817491 ns/op   13751.63 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/generic/100000000-8                18           58559253 ns/op   13661.38 MB/s          0 B/op          0 allocs/op

BenchmarkMemcpy64Bytes/avx512/1-8                  601802276              2.005 ns/op   3989.97 MB/s           0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/avx512/10-8                 330677409              3.649 ns/op   21923.14 MB/s          0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/avx512/100-8                233279983              5.170 ns/op   154742.43 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/avx512/1000-8               130317682              9.209 ns/op   868744.16 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/avx512/10000-8               17608890              67.25 ns/op   1189518.38 MB/s        0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/avx512/100000-8                635359               1869 ns/op   428089.90 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/avx512/1000000-8                30810              38788 ns/op   206247.61 MB/s         0 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/avx512/10000000-8                1926             522954 ns/op   152976.98 MB/s         4 B/op          0 allocs/op
BenchmarkMemcpy64Bytes/avx512/100000000-8                160            7438854 ns/op   107543.45 MB/s         0 B/op          0 allocs/op
```
