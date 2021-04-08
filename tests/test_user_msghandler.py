# -*- coding: utf-8 -*-
"""
Test user message hanler.
"""

import unittest

from .helpers import config, mssqlconn, mssql_server_required

msgs = []


def user_msg_handler1(msgstate, severity, srvname, procname, line, msgtext):
    global msgs
    procname = procname.decode('ascii')
    msgtext = msgtext.decode('ascii')
    entry = (u"msg_handler1: msgstate = %d, severity = %d, procname = '%s', "
             "line = %d, msgtext = '%s'") % (msgstate, severity, procname, line, msgtext)
    msgs.append(entry)


def user_msg_handler2(msgstate, severity, srvname, procname, line, msgtext):
    global msgs
    procname = procname.decode('ascii')
    msgtext = msgtext.decode('ascii')
    entry = ("msg_handler2: msgstate = %d, severity = %d, procname = '%s', "
             "line = %d, msgtext = '%s'") % (msgstate, severity, procname, line, msgtext)
    msgs.append(entry)


def wrong_signature_msg_handler():
    pass


@mssql_server_required
class TestUserMsgHandler(unittest.TestCase):

    def test_basic_functionality(self):
        cnx = mssqlconn()
        try:
            cnx.set_msghandler(user_msg_handler1)
            msgs_before = len(msgs)
            cnx.execute_non_query("USE master")
            msgs_after = len(msgs)
            delta = msgs_after - msgs_before
            self.assertEqual(delta, 1)
            expect = ("msg_handler1: msgstate = 1, severity = 0, procname = ''"
                      ", line = 1, msgtext = 'Changed database context to 'master'.'")
            self.assertEqual(expect, msgs[msgs_after - 1])
        finally:
            cnx.close()

    def test_set_handler_to_none(self):
        cnx = mssqlconn()
        try:
            cnx.set_msghandler(None)
            msgs_before = len(msgs)
            cnx.execute_non_query("USE master")
            msgs_after = len(msgs)
            delta = msgs_after - msgs_before
            self.assertEqual(delta, 0)
        finally:
            cnx.close()

    def test_change_handler(self):
        cnx = mssqlconn()
        try:
            cnx.set_msghandler(user_msg_handler1)
            msgs_before = len(msgs)
            cnx.execute_non_query("USE master")
            msgs_after = len(msgs)
            delta = msgs_after - msgs_before
            self.assertEqual(delta, 1)
            expect = ("msg_handler1: msgstate = 1, severity = 0, procname = ''"
                      ", line = 1, msgtext = 'Changed database context to 'master'.'")
            self.assertEqual(expect, msgs[msgs_after - 1])

            cnx.set_msghandler(user_msg_handler2)
            msgs_before = len(msgs)
            cnx.execute_non_query("USE %s" % config.database)
            msgs_after = len(msgs)
            delta = msgs_after - msgs_before
            self.assertEqual(delta, 1)
            expect = ("msg_handler2: msgstate = 1, severity = 0, procname = ''"
                      ", line = 1, msgtext = 'Changed database context to '%s'.'") % config.database
            self.assertEqual(expect, msgs[msgs_after - 1])
        finally:
            cnx.close()

    def test_per_conn_handlers(self):
        cnx1 = mssqlconn()
        cnx2 = mssqlconn()
        try:
            cnx1.set_msghandler(user_msg_handler1)
            msgs_before = len(msgs)
            cnx1.execute_non_query("USE master")
            msgs_after = len(msgs)
            delta = msgs_after - msgs_before
            self.assertEqual(delta, 1)
            expect = ("msg_handler1: msgstate = 1, severity = 0, procname = ''"
                      ", line = 1, msgtext = 'Changed database context to 'master'.'")
            self.assertEqual(expect, msgs[msgs_after - 1])

            cnx2.set_msghandler(user_msg_handler2)
            msgs_before = len(msgs)
            cnx2.execute_non_query("USE %s" % config.database)
            msgs_after = len(msgs)
            delta = msgs_after - msgs_before
            self.assertEqual(delta, 1)
            expect = ("msg_handler2: msgstate = 1, severity = 0, procname = ''"
                      ", line = 1, msgtext = 'Changed database context to '%s'.'") % config.database
            self.assertEqual(expect, msgs[msgs_after - 1])
        finally:
            cnx1.close()
            cnx2.close()

    @staticmethod
    def user_msg_handler3(msgstate, severity, srvname, procname, line, msgtext):
        global msgs
        procname = procname.decode('ascii')
        msgtext = msgtext.decode('ascii')
        entry = ("msg_handler3 called")
        msgs.append(entry)

    def test_static_method_handler(self):
        cnx = mssqlconn()
        try:
            cnx.set_msghandler(self.user_msg_handler3)
            msgs_before = len(msgs)
            cnx.execute_non_query("USE master")
            msgs_after = len(msgs)
            delta = msgs_after - msgs_before
            self.assertEqual(delta, 1)
            expect = ("msg_handler3 called")
            self.assertEqual(expect, msgs[msgs_after - 1])
        finally:
            cnx.close()

    def test_wrong_signature_handler(self):
        cnx = mssqlconn()
        try:
            cnx.set_msghandler(wrong_signature_msg_handler)
            cnx.execute_non_query("USE master")
        finally:
            cnx.close()
