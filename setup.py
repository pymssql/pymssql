#!/usr/bin/env python

import sys, os
have_setuptools = 0
from distutils.core import setup, Extension

#try:
#   from setuptools import setup, Extension
#   have_setuptools = 1
#except ImportError:
#   from distutils.core import setup, Extension

# for setup.py register
classifiers = """\
Development Status :: 5 - Production/Stable
Intended Audience :: Developers
License :: OSI Approved :: GNU Library or Lesser General Public License (LGPL)
Programming Language :: Python
Programming Language :: C
Topic :: Database :: Front-Ends
Topic :: Software Development :: Libraries :: Python Modules
Operating System :: Microsoft :: Windows
Operating System :: POSIX
Operating System :: Unix
"""

minpyver = (2, 4)

if sys.version_info < minpyver:
	print """
ERROR: You're using Python %d.%d, but pymssql requires at least
Python %d.%d. Setup cannot continue.
""" % ( sys.version_info[0], sys.version_info[1], minpyver[0], minpyver[1] )
	sys.exit(1)

if sys.platform == "win32":
	p = ''
	import os.path
	try:
		# those modules are available out-of-the box in ActivePython
		import win32api, win32con

		# try to determine include and lib path
		try:
			h = win32api.RegOpenKey(win32con.HKEY_LOCAL_MACHINE, r'SOFTWARE\Microsoft\Microsoft SQL Server\80\Tools\ClientSetup')
			p = win32api.RegQueryValueEx(h,'SQLPath')[0]
		except:
			e = sys.exc_info()
			print """
Setup.py is unable to find path to SQL 2000 tools. Either it's not installed
or you have insufficient permissions to read Windows registry. Please make
sure you've got administrator rights. Setup.py will try some generic paths.
"""
		if p:
			e = ''
			if (not os.path.exists(os.path.join(p, r'DevTools\include'))):
				e += "Setup.py is unable to find SQL 2000 developer tools include directory.\n"
			if (not os.path.exists(os.path.join(p, r'DevTools\lib'))):
				e += "Setup.py is unable to find SQL 2000 developer tools library directory.\n"

			if e:
				print e + """
Either the developer tools package is not installed or you have insufficient
permissions to read the files. Please make sure you've got administrator
rights. Setup.py will try some generic paths.
"""
	except ImportError:
		pass

	# first some generic paths
	# XXX TODO remove developer paths
	include_dirs = [ r'c:\Program Files\Microsoft SQL Server\80\Tools\DevTools\Include', r'c:\mssql7\DevTools\Include', r'd:\DEVEL\pymssql-DEVTOOLS\INCLUDE' ]
	library_dirs = [ r'c:\Program Files\Microsoft SQL Server\80\Tools\DevTools\Lib', r'\mssql7\DevTools\Lib', r'd:\DEVEL\pymssql-DEVTOOLS\X86LIB' ]
	libraries = ["ntwdblib", "msvcrt", "kernel32", "user32", "gdi32", "winspool", "comdlg32", "advapi32", "shell32", "ole32", "oleaut32", "uuid", "odbc32", "odbccp32", ]
	data_files = [("LIB/site-packages",["ntwdblib.dll",]),]

	# prepend path from registry, if any
	if p:
		include_dirs.insert(0, os.path.join(p, r'DevTools\include'))
		library_dirs.insert(0, os.path.join(p, r'DevTools\lib'))

else:	# try some generic paths
	include_dirs = [
		'/usr/local/include', '/usr/local/include/freetds',  # first local install
		'/usr/include', '/usr/include/freetds',   # some generic Linux paths
		'/usr/include/freetds_mssql',             # some versions of Mandriva 
		'/usr/local/freetds/include',             # FreeBSD
		'/usr/pkg/freetds/include'	              # NetBSD
	]
	library_dirs = [
		'/usr/local/lib', '/usr/local/lib/freetds',
		'/usr/lib', '/usr/lib/freetds',
		'/usr/lib/freetds_mssql', 
		'/usr/local/freetds/lib',
		'/usr/pkg/freetds/lib'
	]
	libraries = [ "sybdb" ]   # on Mandriva you may have to change it to sybdb_mssql
	data_files = []

if sys.platform == "cygwin":
	libraries.append("iconv")

# when using Fink (http://Fink.SF.Net) under OS X, the following is needed:
# (thanks Terrence Brannon <metaperl@gmail.com>)
if sys.platform == "darwin":
	fink = '/sw/'
	include_dirs.insert(0, fink + 'include')
	library_dirs.insert(0, fink + 'lib')

setup(name = 'pymssql',
	version = '1.0.2',
	description = 'A simple database interface to MS-SQL for Python.',
	long_description = 'A simple database interface to MS-SQL for Python.',
	author = 'Joon-cheol Park',
	author_email = 'jooncheol@gmail.com',
	maintainer = 'Andrzej Kukula',
	maintainer_email = 'akukula+pymssql@gmail.com',
	license = 'LGPL',
	url = 'http://pymssql.sourceforge.net',
	py_modules = [ 'pymssql' ],
	ext_modules = [ Extension('_mssql', ['mssqldbmodule.c'],
			include_dirs = include_dirs,
			library_dirs = library_dirs,
			libraries = libraries) ],
	classifiers = filter(None, classifiers.split('\n')),
	data_files = data_files,
	#zip_safe = False  # we accept the warning if there's no setuptools and in case of Python 2.4 and 2.5
)
