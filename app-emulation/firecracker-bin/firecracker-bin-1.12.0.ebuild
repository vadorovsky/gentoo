# Copyright 2021-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-info

DESCRIPTION="Secure and fast microVMs for serverless computing (static build)"
HOMEPAGE="https://firecracker-microvm.github.io https://github.com/firecracker-microvm/firecracker"
SRC_URI="
	amd64? (
		https://github.com/firecracker-microvm/firecracker/releases/download/v${PV}/firecracker-v${PV}-x86_64.tgz
	)
	arm64? (
		https://github.com/firecracker-microvm/firecracker/releases/download/v${PV}/firecracker-v${PV}-aarch64.tgz
	)"

S="${WORKDIR}"

LICENSE="|| ( Apache-2.0 MIT Apache-2.0-with-LLVM-exceptions ) MPL-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RESTRICT="test strip"

RDEPEND="acct-group/kvm"

QA_PREBUILT="usr/bin/cpu-template-helper
	usr/bin/firecracker
	usr/bin/jailer
	usr/bin/rebase-snap
	usr/bin/seccompiler-bin
	usr/bin/snapshot-editor"

pkg_pretend() {
	if use kernel_linux && kernel_is lt 4 14; then
		eerror "Firecracker requires a host kernel of 4.14 or higher."
	elif use kernel_linux; then
		if ! linux_config_exists; then
			eerror "Unable to check your kernel for KVM support"
		else
			CONFIG_CHECK="~KVM ~TUN ~BRIDGE"
			ERROR_KVM="You must enable KVM in your kernel to continue"
			ERROR_KVM_AMD="If you have an AMD CPU, you must enable KVM_AMD in"
			ERROR_KVM_AMD+=" your kernel configuration."
			ERROR_KVM_INTEL="If you have an Intel CPU, you must enable"
			ERROR_KVM_INTEL+=" KVM_INTEL in your kernel configuration."
			ERROR_TUN="You will need the Universal TUN/TAP driver compiled"
			ERROR_TUN+=" into your kernel or loaded as a module to use"
			ERROR_TUN+=" virtual network devices."
			ERROR_BRIDGE="You will also need support for 802.1d"
			ERROR_BRIDGE+=" Ethernet Bridging for some network configurations."

			if use amd64 || use amd64-linux; then
				if grep -q AuthenticAMD /proc/cpuinfo; then
					CONFIG_CHECK+=" ~KVM_AMD"
				elif grep -q GenuineIntel /proc/cpuinfo; then
					CONFIG_CHECK+=" ~KVM_INTEL"
				fi
			fi

			# Now do the actual checks setup above
			check_extra_config
		fi
	fi
}

src_compile() { :; }

src_install() {
	local my_arch
	if use amd64; then
		my_arch=x86_64
	elif use arm64; then
		my_arch=aarch64
	fi

	dodoc "release-v${PV}-${my_arch}/firecracker_spec-v${PV}.yaml"
	dodoc "release-v${PV}-${my_arch}/seccomp-filter-v${PV}-${my_arch}.json"

	newbin "release-v${PV}-${my_arch}/cpu-template-helper-v${PV}-${my_arch}" cpu-template-helper
	newbin "release-v${PV}-${my_arch}/firecracker-v${PV}-${my_arch}" firecracker
	newbin "release-v${PV}-${my_arch}/jailer-v${PV}-${my_arch}" jailer
	newbin "release-v${PV}-${my_arch}/rebase-snap-v${PV}-${my_arch}" rebase-snap
	newbin "release-v${PV}-${my_arch}/seccompiler-bin-v${PV}-${my_arch}" seccompiler-bin
	newbin "release-v${PV}-${my_arch}/snapshot-editor-v${PV}-${my_arch}" snapshot-editor
}
