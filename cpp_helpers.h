/*

 cpp_helpers.h

   Copyright (C) 2014 pymssql development team.

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 MA  02110-1301  USA
*/

/*

 Helper module to aid with the fact that Cython doesn't support C pre-procesor
 macros yet. See:

  https://groups.google.com/forum/#!topic/cython-users/HASNraxsGGw
  https://github.com/denik/cython-ifdef
  http://grokbase.com/t/gg/cython-users/128rn1399p/equivalent-of-ifdef-preprocessor

*/

#include "sybdb.h"

#ifdef DBSETLDBNAME
#define FREETDS_SUPPORTS_DBSETLDBNAME 1
#else
#define FREETDS_SUPPORTS_DBSETLDBNAME 0
#endif
