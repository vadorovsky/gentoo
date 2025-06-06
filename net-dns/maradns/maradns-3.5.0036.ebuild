# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit edo flag-o-matic python-any-r1 systemd toolchain-funcs

DESCRIPTION="A security-aware DNS server"
HOMEPAGE="https://maradns.samiam.org"
SRC_URI="https://maradns.samiam.org/download/${PV%.*}/${PV}/${P}.tar.xz"

# The GPL-2 covers the init script, bug 426018.
LICENSE="BSD-2 GPL-2"
SLOT="0"
KEYWORDS="amd64 ~mips ~ppc x86"
IUSE="examples"

BDEPEND="${PYTHON_DEPS}
	dev-lang/perl"
RDEPEND="
	acct-group/maradns
	acct-user/duende
	acct-user/maradns"

PATCHES=(
	"${FILESDIR}"/${PN}-3.5.0036-flags.patch
)

src_configure() {
	# -Werror=lto-type-mismatch
	# bug #861293
	# https://github.com/samboy/MaraDNS/discussions/124
	#
	# should be fixed in git master; try removing this on the next bump
	filter-lto

	# bug #945182
	# https://github.com/samboy/MaraDNS/commit/1cbc02668ee88788e6fb75c774c7e9210d6d52ee
	append-flags -std=gnu17

	tc-export CC

	edo ./configure --ipv6
}

src_install() {
	# Install the MaraDNS and Deadwood binaries
	dosbin server/maradns
	dosbin tcp/zoneserver
	dosbin deadwood-${PV}/src/Deadwood
	dobin tcp/{getzone,fetchzone}
	dobin tools/{askmara,askmara-tcp,duende}

	# MaraDNS docs, manpages, misc
	docompress -x /usr/share/doc/${PF}/maradns.gpg.key
	dodoc {CHANGELOG.TXT,COPYING,maradns.gpg.key}
	dodoc doc/en/{QuickStart,faq.*,*.md,README}
	dodoc -r doc/en/{text,tutorial}
	docinto deadwood
	dodoc deadwood-${PV}/doc/{*.txt,*.html,CHANGELOG,Deadwood-HOWTO}
	dodoc -r deadwood-${PV}/doc/internals

	# Install examples (optional)
	if use examples ; then
		docinto examples
		dodoc doc/en/examples/example_*
	fi

	# Install manpages
	doman doc/en/man/*.[1-9]

	# Example configurations.
	insinto /etc/maradns
	newins doc/en/examples/example_full_mararc mararc_full.dist
	newins doc/en/examples/example_csv2 example_csv2.dist
	newins deadwood-${PV}/doc/dwood3rc-all dwood3rc_all.dist
	keepdir /etc/maradns/logger

	# Init scripts.
	newinitd "${FILESDIR}"/maradns2 maradns
	newinitd "${FILESDIR}"/zoneserver2 zoneserver
	newinitd "${FILESDIR}"/deadwood deadwood

	# systemd unit
	# please keep paths in sync!
	sed -e "s^@bindir@^${EPREFIX}/usr/sbin^" \
		-e "s^@sysconfdir@^${EPREFIX}/etc/maradns^" \
		"${FILESDIR}"/maradns.service.in > "${T}"/maradns.service \
		|| die "failed to create the maradns.service file (sed)"

	systemd_dounit "${T}"/maradns.service
}

pkg_postinst() {
	elog "Examples of configuration files can be found in the"
	elog "/etc/maradns directory, feel free use it like:"
	elog "     cp /etc/maradns/mararc{_full.dist,}"
	elog "and edit /etc/maradns/mararc as described in man mararc."
}
