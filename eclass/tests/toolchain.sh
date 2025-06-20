#!/bin/bash
# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# apply eclass globals to test version parsing
TOOLCHAIN_GCC_PV=11.3.0
PR=r0

source tests-common.sh || exit
source version-funcs.sh || exit

EAPI=7 inherit toolchain

# Ignore actually running version of gcc and fake new version
# to force downgrade test on all conditions below.
gcc-version() {
	echo "99.99"
}

test_downgrade_arch_flags() {
	local exp msg ret=0 ver

	ver=${1}
	exp=${2}
	shift 2
	CFLAGS=${@}

	tbegin "downgrade_arch_flags: ${ver} ${CFLAGS} => ${exp}"

	CHOST=x86_64 # needed for tc-arch
	downgrade_arch_flags ${ver}

	if [[ ${CFLAGS} != ${exp} ]]; then
		msg="Failure - Expected: \"${exp}\" Got: \"${CFLAGS}\" Ver: ${ver}"
		ret=1
	fi
	tend ${ret} ${msg}
}

#                         ver  expected            given
test_downgrade_arch_flags 10  "-march=haswell"    "-march=haswell"
test_downgrade_arch_flags 4.9 "-march=haswell"    "-march=haswell"
test_downgrade_arch_flags 4.8 "-march=core-avx2"  "-march=haswell"
test_downgrade_arch_flags 4.7 "-march=core-avx2"  "-march=haswell"
test_downgrade_arch_flags 4.6 "-march=core-avx-i" "-march=haswell"
test_downgrade_arch_flags 4.5 "-march=core2"      "-march=haswell"
test_downgrade_arch_flags 4.4 "-march=core2"      "-march=haswell"
test_downgrade_arch_flags 4.3 "-march=core2"      "-march=haswell"
test_downgrade_arch_flags 4.2 "-march=nocona"     "-march=haswell"

test_downgrade_arch_flags 4.9 "-march=bdver4"     "-march=bdver4"
test_downgrade_arch_flags 4.8 "-march=bdver3"     "-march=bdver4"
test_downgrade_arch_flags 4.7 "-march=bdver2"     "-march=bdver4"
test_downgrade_arch_flags 4.6 "-march=bdver1"     "-march=bdver4"
test_downgrade_arch_flags 4.5 "-march=amdfam10"   "-march=bdver4"
test_downgrade_arch_flags 4.4 "-march=amdfam10"   "-march=bdver4"
test_downgrade_arch_flags 4.3 "-march=amdfam10"   "-march=bdver4"
test_downgrade_arch_flags 4.2 "-march=k8"         "-march=bdver4"

test_downgrade_arch_flags 4.5 "-march=garbage"    "-march=garbage"

test_downgrade_arch_flags 10  "-mtune=intel"      "-mtune=intel"
test_downgrade_arch_flags 4.9 "-mtune=intel"      "-mtune=intel"
test_downgrade_arch_flags 4.8 "-mtune=generic"    "-mtune=intel"

test_downgrade_arch_flags 4.5 "-march=amdfam10 -mtune=generic" "-march=btver2 -mtune=generic"

test_downgrade_arch_flags 10  "-march=native"     "-march=native"
test_downgrade_arch_flags 8   "-march=znver1"     "-march=znver2"
test_downgrade_arch_flags 4.2 "-march=native"     "-march=native"
test_downgrade_arch_flags 9   "-march=znver2"     "-march=znver3"

test_downgrade_arch_flags 10  "-march=foo -mno-sha -mno-rtm -mno-avx2 -mno-avx -mno-sse4.1" "-march=foo -mno-sha -mno-rtm -mno-avx2 -mno-avx -mno-sse4.1"
test_downgrade_arch_flags 4.9 "-march=foo -mno-sha -mno-rtm -mno-avx2 -mno-avx -mno-sse4.1" "-march=foo -mno-sha -mno-rtm -mno-avx2 -mno-avx -mno-sse4.1"
test_downgrade_arch_flags 4.8 "-march=foo -mno-rtm -mno-avx2 -mno-avx -mno-sse4.1" "-march=foo -mno-sha -mno-rtm -mno-avx2 -mno-avx -mno-sse4.1"
test_downgrade_arch_flags 4.7 "-march=foo -mno-avx2 -mno-avx -mno-sse4.1" "-march=foo -mno-sha -mno-rtm -mno-avx2 -mno-avx -mno-sse4.1"
test_downgrade_arch_flags 4.6 "-march=foo -mno-avx -mno-sse4.1" "-march=foo -mno-sha -mno-rtm -mno-avx2 -mno-avx -mno-sse4.1"
test_downgrade_arch_flags 4.3 "-march=foo -mno-sse4.1" "-march=foo -mno-sha -mno-rtm -mno-avx2 -mno-avx -mno-sse4.1"
test_downgrade_arch_flags 4.2 "-march=foo" "-march=foo -mno-sha -mno-rtm -mno-avx2 -mno-avx -mno-sse4.1"

test_downgrade_arch_flags 4.4 "-O2 -march=core2 -ffoo -fblah" "-O2 -march=atom -mno-sha -ffoo -mno-rtm -fblah"

# basic version parsing tests in preparation to eapi7-ver switch

test_tc_version_is_at_least() {
	local exp msg ret=0 want mine res

	want=${1}
	mine=${2}
	exp=${3}

	tbegin "tc_version_is_at_least: ${want} ${mine} => ${exp}"

	tc_version_is_at_least ${want} ${mine}
	res=$?

	if [[ ${res} -ne ${exp} ]]; then
		msg="Failure - Expected: \"${exp}\" Got: \"${res}\""
		ret=1
	fi
	tend ${ret} ${msg}
}

#                           want                mine expect
test_tc_version_is_at_least 12                  ''   1
test_tc_version_is_at_least 11.4                ''   1
test_tc_version_is_at_least 10                  ''   0
test_tc_version_is_at_least 10                  ''   0
test_tc_version_is_at_least ${TOOLCHAIN_GCC_PV} ''   0
test_tc_version_is_at_least 10                  11   0

test_tc_version_is_between() {
	local exp msg ret=0 lo hi res

	lo=${1}
	hi=${2}
	exp=${3}

	tbegin "tc_version_is_between: ${lo} ${hi} => ${exp}"

	tc_version_is_between ${lo} ${hi}
	res=$?

	if [[ ${res} -ne ${exp} ]]; then
		msg="Failure - Expected: \"${exp}\" Got: \"${res}\""
		ret=1
	fi
	tend ${ret} ${msg}
}

#                          lo                  hi                  expect
test_tc_version_is_between 1                   0                   1
test_tc_version_is_between 1                   2                   1
test_tc_version_is_between 11                  12                  0
test_tc_version_is_between ${TOOLCHAIN_GCC_PV} 12                  0
test_tc_version_is_between ${TOOLCHAIN_GCC_PV} ${TOOLCHAIN_GCC_PV} 1
test_tc_version_is_between 10                  ${TOOLCHAIN_GCC_PV} 1
test_tc_version_is_between 12                  13                  1

# eclass has a few critical global variables worth not breaking
test_var_assert() {
	local var_name exp

	var_name=${1}
	exp=${2}

	tbegin "assert variable value: ${var_name} => ${exp}"

	if [[ ${!var_name} != ${exp} ]]; then
		msg="Failure - Expected: \"${exp}\" Got: \"${!var_name}\""
		ret=1
	fi
	tend ${ret} ${msg}
}

# TODO: convert these globals to helpers to ease testing against multiple
# ${TOOLCHAIN_GCC_PV} values.
test_var_assert GCC_PV          11.3.0
test_var_assert GCC_PVR         11.3.0
test_var_assert GCC_RELEASE_VER 11.3.0
test_var_assert GCC_BRANCH_VER  11.3
test_var_assert GCCMAJOR        11
test_var_assert GCCMINOR        3
test_var_assert GCCMICRO        0
test_var_assert GCC_CONFIG_VER  11.3.0
test_var_assert PREFIX          /usr

texit
