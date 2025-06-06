# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="Creation/expansion of ISO-9660 filesystems on CD/DVD media supported by libburn"
HOMEPAGE="https://dev.lovelyhq.com/libburnia/web/wiki/Libisoburn https://dev.lovelyhq.com/libburnia/libisoburn"
SRC_URI="https://files.libburnia-project.org/releases/${P}.tar.gz"

LICENSE="GPL-2 GPL-3"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="acl debug external-filters external-filters-setuid frontend-optional
	launch-frontend launch-frontend-setuid libedit readline static-libs xattr zlib"

REQUIRED_USE="frontend-optional? ( || ( launch-frontend launch-frontend-setuid ) )"

BDEPEND="
	virtual/pkgconfig
"
RDEPEND="
	>=dev-libs/libburn-1.5.6
	>=dev-libs/libisofs-1.5.6
	readline? ( sys-libs/readline:0= )
	!readline? (
		libedit? ( dev-libs/libedit )
	)
	acl? ( virtual/acl )
	xattr? ( sys-apps/attr )
	zlib? ( sys-libs/zlib )
	launch-frontend? (
		dev-lang/tcl:0
		dev-lang/tk:0
	)
	launch-frontend-setuid? (
		dev-lang/tcl:0
		dev-lang/tk:0
	)
	frontend-optional? ( dev-tcltk/bwidget )
"
DEPEND="
	${RDEPEND}
"

PATCHES=(
	"${FILESDIR}"/${PN}-1.5.6_slibtool.patch
)

src_prepare() {
	default

	# Ancient libtool version in 1.5.6 at least (debian's 2.4.2-1.11)
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_enable readline libreadline) \
		$(usex readline --disable-libedit $(use_enable libedit)) \
		$(use_enable acl libacl) \
		$(use_enable xattr) \
		$(use_enable zlib) \
		--disable-libjte \
		$(use_enable external-filters) \
		$(use_enable external-filters-setuid) \
		$(use_enable launch-frontend) \
		$(use_enable launch-frontend-setuid) \
		--disable-ldconfig-at-install \
		--enable-pkg-check-modules \
		$(use_enable debug)
}

src_install() {
	default

	dodoc CONTRIBUTORS doc/{comments,*.wiki,startup_file.txt}

	docinto frontend
	dodoc frontend/README-tcltk
	docinto xorriso
	dodoc xorriso/{changelog.txt,README_gnu_xorriso}

	find "${D}" -name '*.la' -delete || die
}
