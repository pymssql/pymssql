# -*- coding: utf-8 -*-

import contextlib
from distutils import ccompiler
from distutils.errors import *
import os
import sys
import types


def _has_function(self, funcname, includes=None, include_dirs=None,
                 libraries=None, library_dirs=None):
    """Return a boolean indicating whether funcname is supported on
    the current platform.  The optional arguments can be used to
    augment the compilation environment.
    """
    # this can't be included at module scope because it tries to
    # import math which might not be available at that point - maybe
    # the necessary logic should just be inlined?
    import tempfile
    if includes is None:
        includes = []
    if include_dirs is None:
        include_dirs = []
    if libraries is None:
        libraries = []
    if library_dirs is None:
        library_dirs = []
    fd, fname = tempfile.mkstemp(".c", funcname, text=True)
    f = os.fdopen(fd, "w")
    try:
        for incl in includes:
            f.write("""#include "%s"\n""" % incl)
        f.write("""\
int main (int argc, char **argv) {
%s;
return 0;
}
""" % funcname)
    finally:
        f.close()
    try:
        objects = self.compile([fname], include_dirs=include_dirs)
    except CompileError:
        return False
    finally:
        os.remove(fname)

    try:
        self.link_executable(objects, "a.out",
                             libraries=libraries,
                             library_dirs=library_dirs)
    except (LinkError, TypeError):
        return False
    else:
        os.remove("a.out")
    finally:
        for fn in objects:
            os.remove(fn)

    return True


@contextlib.contextmanager
def stdchannel_redirected(stdchannel, dest_filename):
    """
    A context manager to temporarily redirect stdout or stderr

    e.g.:

    with stdchannel_redirected(sys.stderr, os.devnull):
        ...
    """

    try:
        oldstdchannel = os.dup(stdchannel.fileno())
        dest_file = open(dest_filename, 'w')
        os.dup2(dest_file.fileno(), stdchannel.fileno())

        yield
    finally:
        if oldstdchannel is not None:
            os.dup2(oldstdchannel, stdchannel.fileno())
        if dest_file is not None:
            dest_file.close()


def has_function(*args, **kw):

        with stdchannel_redirected(sys.stderr, os.devnull):
            return _has_function(*args, **kw)


def new_compiler():

    compiler = ccompiler.new_compiler()
    compiler.has_function = types.MethodType(has_function, compiler)
    return compiler
