# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )
QTMIN=6.7.2
inherit ecm frameworks.kde.org optfeature python-any-r1

DESCRIPTION="Library for extracting file metadata"

LICENSE="LGPL-2+"
KEYWORDS="~amd64 arm64 ~loong ~ppc64 ~riscv ~x86"
IUSE="epub exif ffmpeg mobi pdf taglib"

RESTRICT="test"

RDEPEND="
	>=dev-qt/qtbase-${QTMIN}:6[gui,xml]
	=kde-frameworks/karchive-${KDE_CATV}*:6
	=kde-frameworks/kcodecs-${KDE_CATV}*:6
	=kde-frameworks/kcoreaddons-${KDE_CATV}*:6
	=kde-frameworks/ki18n-${KDE_CATV}*:6
	epub? ( app-text/ebook-tools )
	exif? ( media-gfx/exiv2:= )
	ffmpeg? ( media-video/ffmpeg:0= )
	mobi? ( kde-apps/kdegraphics-mobipocket:6 )
	pdf? ( app-text/poppler[qt6(-)] )
	taglib? ( media-libs/taglib:= )
"
DEPEND="${RDEPEND}
	kernel_linux? ( sys-apps/attr )
"
BDEPEND="test? ( ${PYTHON_DEPS} )"

CMAKE_SKIP_TESTS=(
	# FIXME: bug 644650, fails on tmpfs (but not for everyone)
	usermetadatawritertest
)

pkg_setup() {
	use test && python-any-r1_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		$(cmake_use_find_package epub EPub)
		$(cmake_use_find_package exif LibExiv2)
		$(cmake_use_find_package ffmpeg FFmpeg)
		$(cmake_use_find_package mobi QMobipocket6)
		-DENABLE_MOBIPOCKET_TEXT_EXTRACTION=OFF
		$(cmake_use_find_package pdf Poppler)
		$(cmake_use_find_package taglib Taglib)
	)

	ecm_src_configure
}

pkg_postinst() {
	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		optfeature "Microsoft Word/Powerpoint file indexing" app-text/catdoc
		optfeature "Microsoft Excel file indexing" dev-libs/libxls
	fi
}
