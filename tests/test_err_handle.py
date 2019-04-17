import unittest

import _mssql

from tests.helpers import mssqlconn


class ErrHandleTests(unittest.TestCase):

    def test01DBError(self):
        connection = None
        severity = 8
        dberr = 101
        oserr = 0
        dberrstr = "toblerone1"
        oserrstr = None

        expect = "DB-Lib error message %d, severity %d:\n%s\n" % (
            dberr, severity, dberrstr)
        expect = expect.encode('UTF-8')

        values = _mssql.test_err_handler(
            connection, severity, dberr, oserr, dberrstr, oserrstr)
        self.assertEqual(values[0], 2)
        self.assertEqual(values[1], expect)

    def test02OSError(self):
        connection = None
        # EXCOMM
        severity = 9
        dberr = 102
        oserr = 1001
        dberrstr = "toblerone2"
        oserrstr = "scorpion"

        expect = (
            "DB-Lib error message %d, severity %d:\n%s\n"
            "Net-Lib error during %s (%d)\n" % (
                dberr, severity, dberrstr, oserrstr, oserr))
        expect = expect.encode('UTF-8')

        values = _mssql.test_err_handler(
            connection, severity, dberr, oserr, dberrstr, oserrstr)
        self.assertEqual(values[0], 2)
        self.assertEqual(values[1], expect)

    def test03OSError(self):
        connection = None
        severity = 10
        dberr = 103
        oserr = 1003
        dberrstr = "toblerone3"
        oserrstr = "cabezon"

        expect = (
            "DB-Lib error message %d, severity %d:\n%s\n"
            "Operating System error during %s (%d)\n" % (
                dberr, severity, dberrstr, oserrstr, oserr))
        expect = expect.encode('UTF-8')

        values = _mssql.test_err_handler(
            connection, severity, dberr, oserr, dberrstr, oserrstr)
        self.assertEqual(values[0], 2)
        self.assertEqual(values[1], expect)

    def test04NoError(self):
        connection = None

        # smaller than min error severity, so no output should be generated
        severity = 5
        dberr = 10
        oserr = 4444
        dberrstr = "toblerone4"
        oserrstr = "limpet"

        expect = b""

        values = _mssql.test_err_handler(
            connection, severity, dberr, oserr, dberrstr, oserrstr)
        self.assertEqual(values[0], 2)
        self.assertEqual(values[1], expect)

    def test_errors_above_min_severity_trigger_dead_conns_to_be_marked_as_disconnected(self):
        connection = mssqlconn()
        severity = 10
        dberr = 103
        oserr = 1003
        dberrstr = "toblerone3"
        oserrstr = "cabezon"

        expect = (
            "DB-Lib error message %d, severity %d:\n%s\n"
            "Operating System error during %s (%d)\n" % (
                dberr, severity, dberrstr, oserrstr, oserr))
        expect = expect.encode('UTF-8')

        values = _mssql.test_err_handler(
            connection, severity, dberr, oserr, dberrstr, oserrstr,
            mark_connection_as_dead=True)

        self.assertEqual(values[0], 2)
        self.assertEqual(values[1], expect)

        assert connection.connected is False

    def test_errors_below_min_severity_still_trigger_dead_conns_to_be_marked_as_disconnected(self):
        # ensure dead connections are closed even if severity < min error severity
        # Issue: https://github.com/pymssql/pymssql/issues/631
        severity = 1
        dberr = 20047
        oserr = 0
        dberrstr = "DBPROCESS is dead or not enabled"
        oserrstr = "Success"

        expect = b""

        connection = mssqlconn()

        values = _mssql.test_err_handler(
            connection, severity, dberr, oserr, dberrstr, oserrstr,
            mark_connection_as_dead=True)

        self.assertEqual(values[0], 2)
        self.assertEqual(values[1], expect)

        assert connection.connected is False


if __name__ == "__main__":
    unittest.main()
