# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit qmake-utils

DESCRIPTION="Fractal planet and terrain generator"
HOMEPAGE="https://sourceforge.net/projects/fracplanet/"
SRC_URI="https://downloads.sourceforge.net/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

BDEPEND="dev-libs/libxslt"
RDEPEND="
	dev-libs/boost:=
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtopengl:5[-gles2-only]
	dev-qt/qtwidgets:5
	virtual/glu
	virtual/opengl
"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}"/${PN}-0.5.1-musl.patch
)

HTML_DOCS=( fracplanet.{htm,css} )

src_configure() {
	eqmake5 fracplanet.pro
}

src_compile() {
	xsltproc -stringparam version ${PV} -html htm_to_qml.xsl fracplanet.htm \
		| sed 's/"/\\"/g' | sed 's/^/"/g' | sed 's/$/\\n"/g'> usage_text.h || die
	default
}

src_install() {
	dobin ${PN}
	doman man/man1/${PN}.1
	einstalldocs
}
