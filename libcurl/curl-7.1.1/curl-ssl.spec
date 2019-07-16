%define ver	7.1
%define rel	1
%define prefix	/usr

Summary:	get a file from a FTP, GOPHER or HTTP server.
Name:		curl-ssl
Version:	%ver
Release:	%rel
Copyright:	MPL
Group:		Utilities/Console
Source:		curl-%{version}.tar.gz
URL:		http://curl.haxx.se
BuildPrereq:	openssl
BuildRoot:	/tmp/%{name}-%{version}-%{rel}-root
Packager:	Fill In As You Wish
Docdir:		%{prefix}/doc

%description
curl-ssl is a client to get documents/files from servers, using 
any of the supported protocols.  The command is designed to 
work without user interaction or any kind of interactivity.

curl-ssl offers a busload of useful tricks like proxy support, 
user authentication, ftp upload, HTTP post, file transfer 
resume and more.

Note: this version is compiled with SSL (https:) support.

Authors:
	Daniel Stenberg <daniel@haxx.se>


%prep
%setup -n curl-7.1


%build
# Needed for snapshot releases.
if [ ! -f configure ]; then
	CONF="./autogen.sh"
else
	CONF="./configure"
fi

#
# Configuring the package
#
CFLAGS="${RPM_OPT_FLAGS}" ${CONF}	\
	--prefix=%{prefix}		\
	--with-ssl


[ "$SMP" != "" ] && JSMP = '"MAKE=make -k -j $SMP"'

make ${JSMP} CFLAGS="-DUSE_SSLEAY -I/usr/include/openssl";


%install
[ -d ${RPM_BUILD_ROOT} ] && rm -rf ${RPM_BUILD_ROOT}

make prefix=${RPM_BUILD_ROOT}%{prefix} install-strip

#
# Generating file lists and store them in file-lists
# Starting with the directory listings
#
find ${RPM_BUILD_ROOT}%{prefix}/{bin,lib,man} -type d | sed "s#^${RPM_BUILD_ROOT}#\%attr (-\,root\,root) \%dir #" > file-lists

#
# Then, the file listings
#
echo "%defattr (-, root, root)" >> file-lists
find ${RPM_BUILD_ROOT}%{prefix} -type f | sed -e "s#^${RPM_BUILD_ROOT}##g" >> file-lists


%clean
(cd ..; rm -rf curl-7.1 ${RPM_BUILD_ROOT})


%files -f file-lists
%defattr (-, root, root)
%doc BUGS
%doc CHANGES
%doc CONTRIBUTE
%doc FAQ
%doc FEATURES
%doc FILES
%doc INSTALL
%doc LEGAL
%doc MPL-1.0.txt
%doc README
%doc README.curl
%doc README.libcurl
%doc RESOURCES
%doc TODO
%doc %{name}-ssl.spec.in
%doc %{name}.spec.in
