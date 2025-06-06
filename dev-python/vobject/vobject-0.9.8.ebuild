# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Python package for parsing and generating vCard and vCalendar files"
HOMEPAGE="
	https://github.com/skarim/vobject/
	https://pypi.org/project/vobject/
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~riscv x86"

RDEPEND="
	>=dev-python/python-dateutil-2.7.0[${PYTHON_USEDEP}]
	dev-python/pytz[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
"

DOCS=( ACKNOWLEDGEMENTS.txt README.md )

distutils_enable_tests unittest
