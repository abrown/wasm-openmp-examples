PROJECT_DIR := $(realpath .)
BUILD_DIR := $(PROJECT_DIR)/build

# Specify a different wasi-sdk with `make WASI_SDK_DIR=...`.
WASI_SDK_DIR := /opt/wasi-sdk/latest
WASI_CC := $(WASI_SDK_DIR)/bin/clang
WASI_SYSROOT := $(WASI_SDK_DIR)/share/wasi-sysroot
TARGET_FLAGS=--target=wasm32-wasi-threads -pthread
WASI_LIBC_FLAGS=-D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS
SYSROOT_FLAGS=--sysroot=$(WASI_SYSROOT)

# Specify a different location for the OpenMP sources with `make OPENMP_DIR=...`.
OPENMP_DIR := $(PROJECT_DIR)/llvm-project/openmp
OPENMP_LIB := $(BUILD_DIR)/runtime/src/libomp.a

# Specify a different Wasm engine to invoke with `make WASM_ENGINE=...`. You can prepend the
# `WASMTIME_LOG=...` bits below if you want to see what Wasmtime is doing under the hood:
#     WASMTIME_LOG=wasmtime_runtime::memory=trace,wasmtime_wasi_threads=trace
WASM_ENGINE=../wasmtime/target/release/wasmtime

# The default target--builds and runs everything.
all: run

# Run the compiled example in a WebAssembly engine.
run: example.wasm
	$(WASM_ENGINE) -W threads -S threads $^

# Compile the example; note how we will need the `libomp.a` runtime.
example.wasm: example.c $(OPENMP_LIB)
	make check-wasi-sdk
	$(WASI_CC) -fopenmp=libomp -g --sysroot=$(WASI_SYSROOT) --target=wasm32-wasi-threads \
	  -I$(BUILD_DIR)/runtime/src -I$(WASI_SYSROOT)/include -pthread \
	  -Wl,--import-memory,--export-memory,--max-memory=67108864 example.c \
	  -L$(BUILD_DIR)/runtime/src -lomp \
	  -lwasi-emulated-getpid \
	  -o example.wasm

# Compile the `libomp.a` runtime library to WebAssembly. This uses the PR changes from
# https://github.com/llvm/llvm-project/pull/71297.
libomp: $(OPENMP_LIB)
$(OPENMP_LIB): $(OPENMP_DIR)
	make check-wasi-sdk
	cmake \
	  -DCMAKE_BUILD_TYPE=Debug \
	  -DCMAKE_C_COMPILER="$(WASI_SDK_DIR)/bin/clang" \
	  -DCMAKE_C_FLAGS="$(TARGET_FLAGS) $(WASI_LIBC_FLAGS) $(SYSROOT_FLAGS)" \
	  -DCMAKE_CXX_COMPILER="$(WASI_SDK_DIR)/bin/clang++" \
	  -DCMAKE_CXX_FLAGS="$(TARGET_FLAGS) $(WASI_LIBC_FLAGS) $(SYSROOT_FLAGS)" \
	  -DCMAKE_LINKER="${WASI_SDK}/bin/ld.lld" \
	  -B $(BUILD_DIR) \
	  -S $(OPENMP_DIR)
	cmake --build $(BUILD_DIR)
$(OPENMP_DIR):
	$(error cannot find $@; retrieve the submodule with `git submodule update --init` or rerun with `make OPENMP_DIR=...`)

# Check that the parts of wasi-sdk we need are present; if they're not, fail.
check-wasi-sdk: $(WASI_CC) $(WASI_SYSROOT)
$(WASI_CC) $(WASI_SYSROOT):
	$(error cannot find $@; install wasi-sdk from https://github.com/WebAssembly/wasi-sdk/releases and rerun with `make WASI_SDK_DIR=...`)

clean:
	rm -f *.wasm
	rm -rf $(BUILD_DIR)
