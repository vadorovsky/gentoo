# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

# ebuild generated by hackport 0.5.9999
#hackport: flags: -all_extensions,+with_threaded,+with_utf8,with_iwlib:wifi,with_alsa:alsa,with_xft:xft,with_datezone:timezone,with_dbus:dbus,with_mpd:mpd,with_inotify:inotify,with_mpris:mpris,with_xpm:xpm

CABAL_FEATURES="bin"
inherit haskell-cabal

DESCRIPTION="A Minimalistic Text Based Status Bar"
HOMEPAGE="http://xmobar.org"
SRC_URI="mirror://hackage/packages/archive/${PN}/${PV}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="alsa dbus inotify mpd mpris timezone wifi conduit uvmeter xft xpm"

RDEPEND=">=dev-haskell/http-4000.2.4:=
	>=dev-haskell/mtl-2.1:= <dev-haskell/mtl-2.3:=
	dev-haskell/old-locale:=
	>=dev-haskell/parsec-3.1:= <dev-haskell/parsec-3.2:=
	dev-haskell/regex-compat:=
	>=dev-haskell/stm-2.3:= <dev-haskell/stm-2.5:=
	dev-haskell/transformers:=
	>=dev-haskell/utf8-string-0.3:= <dev-haskell/utf8-string-1.1:=
	>=dev-haskell/x11-1.6.1:=
	>=dev-lang/ghc-7.4.1:=
	x11-libs/libXrandr
	x11-libs/libXrender
	alsa? ( >=dev-haskell/alsa-core-0.5:= <dev-haskell/alsa-core-0.6:=
		>dev-haskell/alsa-mixer-0.2.0.2:= )
	dbus? ( >=dev-haskell/dbus-0.10:= )
	inotify? ( >=dev-haskell/hinotify-0.3:= <dev-haskell/hinotify-0.4:= )
	mpd? ( >=dev-haskell/libmpd-0.9:= <dev-haskell/libmpd-0.10:= )
	mpris? ( >=dev-haskell/dbus-0.10:= )
	timezone? ( >=dev-haskell/timezone-olson-0.1:= <dev-haskell/timezone-olson-0.2:=
			>=dev-haskell/timezone-series-0.1:= <dev-haskell/timezone-series-0.2:= )
	wifi? ( net-wireless/wireless-tools )
	conduit? ( dev-haskell/http-conduit:=
			dev-haskell/http-types:= )
	xft? ( >=dev-haskell/x11-xft-0.2:= <dev-haskell/x11-xft-0.4:= )
	xpm? ( x11-libs/libXpm )
"
DEPEND="${RDEPEND}
	>=dev-haskell/cabal-1.6
"

src_prepare() {
	default
	# xmobar is an idle multithreaded program
	# which sits in 'while { sleep(1); }'
	# loops in multiple threads.
	# It has a pathological behaviour in GHC:
	#   everything program does is thread context switch
	#   100 times per second. It's easily seen with
	#
	#       $ strace -f -p `pidof xmobar`
	#
	#   where rt_sigreturn() manages to enter/exit
	# kernel 32 times in each second to do nothing
	# This workaround allows shrinkng wakeups/thread
	# switches down to one per second (internal xmobar's
	# cycle).
	# Be careful when remove it :]
	HCFLAGS+=" -with-rtsopts=-V0"
}

src_configure() {
	haskell-cabal_src_configure \
		--flag=-all_extensions \
		$(cabal_flag alsa with_alsa) \
		$(cabal_flag conduit with_conduit) \
		$(cabal_flag timezone with_datezone) \
		$(cabal_flag dbus with_dbus) \
		$(cabal_flag inotify with_inotify) \
		$(cabal_flag wifi with_iwlib) \
		$(cabal_flag mpd with_mpd) \
		$(cabal_flag mpris with_mpris) \
		--flag=with_threaded \
		--flag=with_utf8 \
		$(cabal_flag uvmeter with_uvmeter) \
		$(cabal_flag xft with_xft) \
		$(cabal_flag xpm with_xpm)
}

src_install() {
	cabal_src_install

	dodoc samples/xmobar.config readme.md news.md
}
