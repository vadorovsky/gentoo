# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( pypy3_11 python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="OpenAPI 2.0 (aka Swagger) and OpenAPI 3.0 spec validator"
HOMEPAGE="
	https://github.com/python-openapi/openapi-spec-validator/
	https://pypi.org/project/openapi-spec-validator/
"

LICENSE="BSD"
SLOT="0"

RDEPEND="
	>=dev-python/jsonschema-4.24.0[${PYTHON_USEDEP}]
	>=dev-python/jsonschema-path-0.4.0_beta1[${PYTHON_USEDEP}]
	>=dev-python/lazy-object-proxy-1.7.1[${PYTHON_USEDEP}]
	>=dev-python/openapi-schema-validator-0.6.0[${PYTHON_USEDEP}]
	>=dev-python/pyyaml-5.1[${PYTHON_USEDEP}]
"

distutils_enable_tests pytest

EPYTEST_DESELECT=(
	# Internet
	tests/integration/test_shortcuts.py::TestPetstoreV2Example
	tests/integration/test_shortcuts.py::TestApiV2WithExampe
	tests/integration/test_shortcuts.py::TestPetstoreV2ExpandedExample
	tests/integration/test_shortcuts.py::TestPetstoreExample
	tests/integration/test_shortcuts.py::TestRemoteValidatev2SpecUrl
	tests/integration/test_shortcuts.py::TestRemoteValidatev30SpecUrl
	tests/integration/test_shortcuts.py::TestApiWithExample
	tests/integration/test_shortcuts.py::TestPetstoreExpandedExample
	tests/integration/test_validate.py::TestPetstoreExample
	tests/integration/test_validate.py::TestApiWithExample
	tests/integration/test_validate.py::TestPetstoreExpandedExample
	tests/integration/validation/test_validators.py
)

src_prepare() {
	sed -i -e '/--cov/d' pyproject.toml || die
	distutils-r1_src_prepare
}
