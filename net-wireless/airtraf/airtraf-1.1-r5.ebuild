# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="AirTraf 802.11b Wireless traffic sniffer"
HOMEPAGE="http://www.elixar.com/"
SRC_URI="http://www.elixar.com/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"

RDEPEND="
	net-libs/libpcap
	sys-libs/ncurses:=
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}"/${P}-sniffd.patch
	"${FILESDIR}"/${P}-off-by-one.patch
	"${FILESDIR}"/${P}-fprintf-format.patch
	"${FILESDIR}"/${P}-fno-common.patch
	"${FILESDIR}"/${P}-c23.patch
	"${FILESDIR}"/${P}-ncurses-opaque.patch
	"${FILESDIR}"/${P}-wformat-security.patch
)

src_prepare() {
	default

	sed -i \
		-e '/^LIBS/s|=.*|= $(shell $(PKG_CONFIG) --libs panel)|' \
		src/libncurses/Makefile || die
	sed -i \
		-e 's|-lpanel -lncurses|$(shell $(PKG_CONFIG) --libs ncurses panel)|' \
		src/sniffd/Makefile || die
	tc-export PKG_CONFIG
}

src_compile() {
	# parallel make (bug #297331)
	emake -C src -j1 \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)" \
		CFLAGS="${CFLAGS}" \
		CXXFLAGS="${CXXFLAGS}" \
		LDFLAGS="${LDFLAGS}"
}

src_install() {
	dobin src/airtraf
	dodoc Authors COMPATIBILITY docs/airtraf_doc.html
}
