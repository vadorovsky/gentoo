# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
GST_ORG_MODULE=gst-plugins-good

inherit gstreamer-meson

DESCRIPTION="MP3 encoder plugin for GStreamer"
KEYWORDS="~alpha amd64 ~arm ~arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~sparc x86"

RDEPEND=">=media-sound/lame-3.99.5-r1[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"
