# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake crossdev flag-o-matic llvm.org llvm-utils toolchain-funcs

DESCRIPTION="Compiler runtime library from LLVM, compatible with GCC"
HOMEPAGE="https://llvm.org/"

LICENSE="Apache-2.0-with-LLVM-exceptions || ( UoI-NCSA MIT )"
SLOT="${LLVM_MAJOR}"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~mips ~ppc64 ~riscv ~x86 ~amd64-linux ~arm64-macos ~ppc-macos ~x64-macos"
IUSE="+abi_x86_32 abi_x86_64 +atomic-builtins debug static-libs test"

DEPEND="
	sys-devel/llvm:${LLVM_MAJOR}
	!!sys-devel/gcc
"
BDEPEND="
	dev-util/patchelf
	sys-devel/clang:${LLVM_MAJOR}
"

LLVM_COMPONENTS=( runtimes llvm-libgcc compiler-rt cmake libunwind libcxx llvm/cmake )
LLVM_TEST_COMPONENTS=( libcxxabi llvm/include/llvm/TargetParser llvm/utils/llvm-lit )
llvm.org_set_globals

pkg_setup() {
	if target_is_not_host || tc-is-cross-compiler ; then
		# strips vars like CFLAGS="-march=x86_64-v3" for non-x86 architectures
		CHOST=${CTARGET} strip-unsupported-flags
		# overrides host docs otherwise
		DOCS=()
	fi
}

src_configure() {
	# LLVM_ENABLE_ASSERTIONS=NO does not guarantee this for us, #614844
	use debug || local -x CPPFLAGS="${CPPFLAGS} -DNDEBUG"

	# pre-set since we need to pass it to cmake
	BUILD_DIR=${WORKDIR}/${P}_build

	strip-unsupported-flags

	local mycmakeargs=(
		-DCOMPILER_RT_INSTALL_PATH="${EPREFIX}/usr/lib/clang/${LLVM_MAJOR}"

		-DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=$(usex !atomic-builtins)
		-DCOMPILER_RT_INCLUDE_TESTS=$(usex test)

		-DCOMPILER_RT_BUILD_CTX_PROFILE=OFF
		-DCOMPILER_RT_BUILD_LIBFUZZER=OFF
		-DCOMPILER_RT_BUILD_MEMPROF=OFF
		-DCOMPILER_RT_BUILD_ORC=OFF
		-DCOMPILER_RT_BUILD_PROFILE=OFF
		-DCOMPILER_RT_BUILD_SANITIZERS=OFF
		-DCOMPILER_RT_BUILD_XRAY=OFF
		-DCOMPILER_RT_BUILTINS_HIDE_SYMBOLS=OFF

		# support non-native unwinding; given it's small enough,
		# enable it unconditionally
		-DLIBUNWIND_ENABLE_CROSS_UNWINDING=ON

		-DLLVM_ENABLE_RUNTIMES="llvm-libgcc"
		-DLLVM_INCLUDE_TESTS=OFF
		-DLLVM_LIBGCC_EXPLICIT_OPT_IN=ON
	)

	if use amd64 && ! target_is_not_host; then
		mycmakeargs+=(
			-DCAN_TARGET_i386=$(usex abi_x86_32)
			-DCAN_TARGET_x86_64=$(usex abi_x86_64)
		)
	fi

	if target_is_not_host || tc-is-cross-compiler ; then
		# Needed to target built libc headers
		export CFLAGS="${CFLAGS} -isystem /usr/${CTARGET}/usr/include"
		mycmakeargs+=(
			# Without this, the compiler will compile a test program
			# and fail due to no builtins.
			-DCMAKE_C_COMPILER_WORKS=1
			-DCMAKE_CXX_COMPILER_WORKS=1

			-DCMAKE_ASM_COMPILER_TARGET="${CTARGET}"
			-DCMAKE_C_COMPILER_TARGET="${CTARGET}"
			-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON
		)
	fi

	if use test; then
		mycmakeargs+=(
			-DLLVM_ENABLE_RUNTIMES="libunwind;libcxxabi;libcxx"
			-DLLVM_EXTERNAL_LIT="${EPREFIX}/usr/bin/lit"
			-DLLVM_LIT_ARGS="$(get_lit_flags)"
			-DLIBUNWIND_LIBCXX_PATH="${WORKDIR}/libcxx"

			-DCOMPILER_RT_TEST_COMPILER="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}/bin/clang"
			-DCOMPILER_RT_TEST_CXX_COMPILER="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}/bin/clang++"

			-DLIBCXXABI_LIBDIR_SUFFIX=
			-DLIBCXXABI_ENABLE_SHARED=OFF
			-DLIBCXXABI_ENABLE_STATIC=ON
			-DLIBCXXABI_USE_LLVM_UNWINDER=ON
			-DLIBCXXABI_INCLUDE_TESTS=OFF

			-DLIBCXX_LIBDIR_SUFFIX=
			-DLIBCXX_ENABLE_SHARED=OFF
			-DLIBCXX_ENABLE_STATIC=ON
			-DLIBCXX_CXX_ABI=libcxxabi
			-DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF
			-DLIBCXX_HAS_MUSL_LIBC=$(usex elibc_musl)
			-DLIBCXX_HAS_GCC_S_LIB=OFF
			-DLIBCXX_INCLUDE_TESTS=OFF
			-DLIBCXX_INCLUDE_BENCHMARKS=OFF
		)
	fi

	cmake_src_configure
}

src_compile() {
	cmake_src_compile

	# To avoid warnings/errors, overwrite the soname.
	patchelf --set-soname libgcc_s.so.1 ${BUILD_DIR}/lib/libunwind.so.1.0
}

src_install() {
	# The way how upstream envisions the installation of llvm-libgcc is:
	#
	# - Installation of libclang_rt.builtins*.a and libunwind.{a,so} files
	#   produced by the llvm-libgcc build. These libraries contain the GNU
	#   symbols and are **not** the same as they would be if you build them
	#   without llvm-libgcc enabled.
	# - Creating symlinks:
	#   - libgcc.a -> libclang_rt.builtins*.a
	#   - libgcc_eh.a -> libunwind.a
	#   - libgcc_s.so -> libunwind.so
	#
	# However, that approach is problematic for us, because it treats libunwind
	# and compiler-rt as a monolith, making it impossible to build them 
	# separately.
	#
	# At the same time, we still want to provide llvm-libgcc for people who want
	# to run binaries linked to libgcc_s without dependency on GCC.
	#
	# Therefore, the best we can do is to:
	#
	# - Keep the main compiler-rt and llvm-libunwind ebuilds separate and without
	#   GNU symbols.
	# - Provide this ebuild which installs the GCC-compatible variants of
	#   compiler-rt and llvm-libunwind with GCC-like names (libgcc*.{a,so})
	#   alongside the default installation.
	#
	# To make this approach work, we can't install the llvm-libgcc files with
	# CMake. Instead, we install the files ourselves under the GCC-like names.
	shopt -s nullglob
	newlib.a ${BUILD_DIR}/compiler-rt/lib/linux/libclang_rt.builtins*.a libgcc.a
	newlib.a ${BUILD_DIR}/lib/libunwind.a libgcc_eh.a
	newlib.so ${BUILD_DIR}/lib/libunwind.so.1.0 libgcc_s.so.1.0
	dosym libgcc_s.so.1.0 /usr/lib/libgcc_s.so.1
	dosym libgcc_s.so.1 /usr/lib/libgcc_s.so
	shopt -u nullglob
}
