# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit dune

DESCRIPTION="Support Library for type-driven code generators"
HOMEPAGE="https://github.com/janestreet/ppx_sexp_conv"
SRC_URI="https://github.com/janestreet/ppx_sexp_conv/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="amd64 arm arm64 ~ppc ppc64 ~riscv x86"
IUSE="+ocamlopt"

# Upper bound on ppxlib for bug #769536
DEPEND="
	>=dev-lang/ocaml-4.14
	dev-ml/base:${SLOT}[ocamlopt?]
	dev-ml/findlib:=[ocamlopt?]
	>=dev-ml/ppxlib-0.28:=[ocamlopt?]
	<dev-ml/ppxlib-0.36.0
	dev-ml/ocaml-compiler-libs:=[ocamlopt?]
"
RDEPEND="${DEPEND}"
