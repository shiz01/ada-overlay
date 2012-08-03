# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ada/xmlada/xmlada-2.2.0-r1.ebuild,v 1.6 2009/08/29 21:49:37 flameeyes Exp $

EAPI="2"

inherit gnat versionator

IUSE=""

DESCRIPTION="XML library for Ada"
HOMEPAGE="http://libre.adacore.com/xmlada/"
SRC_URI="http://www.ada-ru.org/files/gentoo/${PN}-gpl-${PV}-src.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64 ~ppc"

#	virtual/latex-base
#	sys-apps/texinfo

DEPEND="virtual/ada
	>=sys-apps/sed-4"
RDEPEND=""

S="${WORKDIR}/${P}w-src"

lib_compile()
{
	econf '--datadir=${prefix}/share' '--libdir=${prefix}/lib'
	emake -j1 || die "make failed"
}

# NOTE: we are using $1 - the passed gnat profile name
lib_install() {
	# bug #283160
	emake -j1 prefix="${DL}" install || die "install failed"

	pushd "${DL}"
		# adjusting profile independent stuff in project files
		sed -i -e "/Source_Dirs/s:\.\./\.\./include/xmlada:${AdalibSpecsDir}/${PN}:" \
		 -e "/Libdir/s:\.\./\.\.:${AdalibLibTop}/$1:" \
			lib/gnat/xmlada*.gpr \
			|| die "failed to adjust project files"

		# fix xmlada-config hardsets locations and move it to proper location
		sed -i -e "s:^libdir=.*:libdir=${AdalibLibTop}/$1/${PN}:" \
		   -e "s:^includedir=.*:includedir=${AdalibSpecsDir}/${PN}:" \
			bin/xmlada-config
		mv bin/xmlada-config "${DLbin}"

		# organize gpr files
		mv lib/gnat/* "${DLgpr}"

		# the library and *.ali
		mv lib/${PN}/* .
		rm -rf bin include share lib

		# fix the .so links
		#rm *.so
		for fn in relocatable/*.so.* ; do
			ln -s ${fn} .
		done
	popd
}

src_install ()
{
	cd "${S}"
	dodir ${AdalibSpecsDir}/${PN}
	insinto ${AdalibSpecsDir}/${PN}
	doins dom/*.ad? input_sources/*.ad? sax/*.ad? unicode/*.ad? schema/*.ad?

	#set up environment
	echo "PATH=%DLbin%" > ${LibEnv}
	echo "LDPATH=%DL%" >> ${LibEnv}
	echo "ADA_OBJECTS_PATH=%DL%" >> ${LibEnv}
	echo "ADA_INCLUDE_PATH=${AdalibSpecsDir}/${PN}" >> ${LibEnv}
	echo "ADA_PROJECT_PATH=%DLgpr%" >> ${LibEnv}

	gnat_src_install

	dodoc AUTHORS README TODO features*
	dohtml docs/*.html
	doinfo docs/*.info
	insinto /usr/share/doc/${PF}
	doins docs/*.pdf distrib/xmlada_gps.py

	dodir /usr/share/doc/${PF}/examples
	insinto /usr/share/doc/${PF}/examples
	doins -r docs/{dom,sax,schema}
}
