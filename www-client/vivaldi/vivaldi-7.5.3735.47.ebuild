# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_VERSION="138"
CHROMIUM_LANGS="
	af
	am
	ar
	az
	be
	bg
	bn
	ca
	ca-valencia
	cs
	da
	de
	de-CH
	el
	en-GB
	en-US
	eo
	es
	es-419
	es-PE
	et
	eu
	fa
	fi
	fil
	fr
	fy
	gd
	gl
	gu
	he
	hi
	hr
	hu
	hy
	id
	io
	is
	it
	ja
	jbo
	ka
	kab
	kn
	ko
	lt
	lv
	mk
	ml
	mr
	ms
	nb
	nl
	nn
	pa
	pl
	pt-BR
	pt-PT
	ro
	ru
	sc
	sk
	sl
	sq
	sr
	sr-Latn
	sv
	sw
	ta
	te
	th
	tr
	uk
	ur
	vi
	zh-CN
	zh-TW
"

inherit chromium-2 desktop linux-info toolchain-funcs unpacker xdg

VIVALDI_PN="${PN/%vivaldi/vivaldi-stable}"
VIVALDI_HOME="opt/${PN}"
DESCRIPTION="A browser for our friends"
HOMEPAGE="https://vivaldi.com/"

if [[ ${PV} = *_p* ]]; then
	DEB_REV="${PV#*_p}"
else
	DEB_REV=1
fi

VIVALDI_BASE_URI="https://downloads.vivaldi.com/${VIVALDI_PN#vivaldi-}/${VIVALDI_PN}_${PV%_p*}-${DEB_REV}_"

SRC_URI="
	amd64? ( ${VIVALDI_BASE_URI}amd64.deb )
	arm? ( ${VIVALDI_BASE_URI}armhf.deb )
	arm64? ( ${VIVALDI_BASE_URI}arm64.deb )
"

S="${WORKDIR}"
LICENSE="Vivaldi"
SLOT="0"
KEYWORDS="-* amd64 ~arm ~arm64"
IUSE="ffmpeg-chromium gtk proprietary-codecs qt6 widevine"
RESTRICT="bindist mirror"
#REQUIRED_USE="ffmpeg-chromium? ( proprietary-codecs )"

RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	x11-libs/cairo
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/pango
	gtk? ( gui-libs/gtk:4 x11-libs/gtk+:3 )
	proprietary-codecs? (
		!ffmpeg-chromium? ( >=media-video/ffmpeg-6.1-r1:0/58.60.60[chromium] )
		ffmpeg-chromium? ( media-video/ffmpeg-chromium:${CHROMIUM_VERSION} )
	)
	qt6? ( dev-qt/qtbase:6[gui,widgets] )
	widevine? ( www-plugins/chrome-binary-plugins )
"

QA_PREBUILT="*"
CONFIG_CHECK="~CPU_FREQ"

src_unpack() {
	unpack_deb ${A}
}

src_prepare() {
	# Rename docs directory to our needs.
	mv usr/share/doc/{${VIVALDI_PN},${PF}}/ || die

	# Decompress the docs.
	gunzip usr/share/doc/${PF}/changelog.gz || die

	# The appdata directory is deprecated.
	mv usr/share/{appdata,metainfo}/ || die

	# Remove cron job for updating from Debian repos.
	rm etc/cron.daily/${PN} ${VIVALDI_HOME}/cron/${PN} || die
	rmdir etc/{cron.daily/,} ${VIVALDI_HOME}/cron/ || die

	# Remove scripts that will most likely break things.
	rm -vf ${VIVALDI_HOME}/update-ffmpeg || die

	pushd ${VIVALDI_HOME}/locales > /dev/null || die
	rm ja-KS.pak || die # No flag for Kansai as not in IETF list.
	rm kmr.pak || die # No flag for Kurmanji.
	chromium_remove_language_paks
	popd > /dev/null || die

	if use proprietary-codecs; then
		einfo Bundled $($(tc-getSTRINGS) ${VIVALDI_HOME}/lib/libffmpeg.so | grep -m1 "^FFmpeg version ")
		rm ${VIVALDI_HOME}/lib/libffmpeg.so || die
		rmdir ${VIVALDI_HOME}/lib || die
	fi

	# Qt5 is obsolete now.
	rm ${VIVALDI_HOME}/libqt5_shim.so || die

	if ! use qt6; then
		rm ${VIVALDI_HOME}/libqt6_shim.so || die
	fi

	eapply_user
}

src_install() {
	mv */ "${D}" || die
	dosym ../../${VIVALDI_HOME}/${PN} /usr/bin/${VIVALDI_PN}
	fperms 4711 /${VIVALDI_HOME}/vivaldi-sandbox

	local logo size
	for logo in "${ED}"/${VIVALDI_HOME}/product_logo_*.png; do
		size=${logo##*_}
		size=${size%.*}
		newicon -s "${size}" "${logo}" ${PN}.png
	done

	if use proprietary-codecs; then
		dosym ../../usr/$(get_libdir)/chromium/libffmpeg.so$(usex ffmpeg-chromium .${CHROMIUM_VERSION} "") \
			  /${VIVALDI_HOME}/libffmpeg.so.$(ver_cut 1-2)
	fi

	if use widevine; then
		dosym ../../usr/$(get_libdir)/chromium-browser/WidevineCdm \
			  /${VIVALDI_HOME}/WidevineCdm
	fi

	case ${PN} in
		vivaldi) dosym ${VIVALDI_PN} /usr/bin/${PN} ;;
		vivaldi-snapshot) dosym ${PN} /${VIVALDI_HOME}/vivaldi ;;
	esac
}
