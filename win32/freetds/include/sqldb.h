/* FreeTDS - Library of routines accessing Sybase and Microsoft databases
 * Copyright (C) 1998-1999  Brian Bruns
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#ifndef SQLDB_h
#define SQLDB_h

#include "./sybdb.h"

#define SQLCHAR SYBCHAR
#define SQLVARCHAR SYBVARCHAR
#define SQLINTN SYBINTN
#define SQLINT1 SYBINT1
#define SQLINT2 SYBINT2
#define SQLINT4 SYBINT4
#define SQLINT8 SYBINT8
#define SQLFLT8 SYBFLT8
#define SQLDATETIME SYBDATETIME
#define SQLBIT SYBBIT
#define SQLTEXT SYBTEXT
#define SQLIMAGE SYBIMAGE
#define SQLMONEY4 SYBMONEY4
#define SQLMONEY SYBMONEY
#define SQLDATETIM4 SYBDATETIME4
#define SQLFLT4 SYBREAL
#define SQLBINARY SYBBINARY
#define SQLVARBINARY SYBVARBINARY
#define SQLNUMERIC SYBNUMERIC
#define SQLDECIMAL SYBDECIMAL
#define SQLFLTN SYBFLTN
#define SQLMONEYN SYBMONEYN
#define SQLDATETIMN SYBDATETIMN
#define SQLVOID	SYBVOID

#define SMALLDATETIBIND SMALLDATETIMEBIND

#define DBERRHANDLE_PROC EHANDLEFUNC 
#define DBMSGHANDLE_PROC MHANDLEFUNC 

#define dbfreelogin(x) dbloginfree((x))

#define dbprocerrhandle(p, h) dberrhandle((h))
#define dbprocmsghandle(p, h) dbmsghandle((h))

#define dbwinexit()

static const char rcsid_sqldb_h[] = "$Id: sqldb.h,v 1.5 2009/01/16 20:27:56 jklowden Exp $";
static const void *const no_unused_sqldb_h_warn[] = { rcsid_sqldb_h, no_unused_sqldb_h_warn };


#endif
