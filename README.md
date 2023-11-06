`wasm-openmp-examples`
======================

This project contains some sample code demonstrating how to build and run OpenMP code in a
WebAssembly engine. There are several parts to the [`Makefile`]:
- `make libomp`: first, we show how to compile `libomp.a`, the OpenMP runtime, to WebAssembly using
  support for [wasi-threads] in [wasi-sdk]
- `make examples`: then, we compile our examples, `example*.c`, to WebAssembly and link them with
  `libomp.a`
- `make run`: finally, we run the compiled WebAssembly module in the [wasmtime] engine
- optionally, we show how to patch Clang to avoid a crash with `#pragma omp critical`

[`Makefile`]: ./Makefile
[wasi-threads]: https://github.com/WebAssembly/wasi-threads
[wasi-sdk]: https://github.com/WebAssembly/wasi-sdk
[wasmtime]: https://github.com/bytecodealliance/wasmtime

The work to upstream the "compile-OpenMP-to-WebAssembly" is available at: [llvm-project#71297].

[llvm-project#71297]: https://github.com/llvm/llvm-project/pull/71297

### Build and Run

To execute all Makefile targets in sequence, run:

```
make
```
