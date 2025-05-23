# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
PYTHON_REQ_USE="sqlite"
DISTUTILS_USE_PEP517="setuptools"
inherit distutils-r1 xdg

MY_PN="Sunflower"
MY_PV="${PV}-63"

DESCRIPTION="Small and highly customizable twin-panel file manager with plugin-support"
HOMEPAGE="https://github.com/MeanEYE/Sunflower
	https://sunflower-fm.org/"
SRC_URI="https://github.com/MeanEYE/${MY_PN}/archive/refs/tags/${MY_PV}.tar.gz"

S="${WORKDIR}/${MY_PN}-${MY_PV}"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 x86"

DEPEND="
	${PYTHON_DEPS}
	dev-python/pygobject:3[${PYTHON_USEDEP}]
	dev-python/chardet[${PYTHON_USEDEP}]
"

RDEPEND="${DEPEND}
	dev-python/pycairo[${PYTHON_USEDEP}]
	x11-libs/vte:2.91
"

src_prepare() {
	default

	# Upstream's get_version requires a lot of BDEPENDS we do not want.
	sed 's%version=get_version()%version="0.5"%g' -i setup.py
}
