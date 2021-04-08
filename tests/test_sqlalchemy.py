# -*- coding: utf-8 -*-
"""
Basic SQLAlchemy tests.
"""

import unittest

from .helpers import config, eq_, skip_test, mssql_server_required

try:
    import sqlalchemy as sa
except ImportError:
    skip_test('SQLAlchemy is not available')
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

engine = sa.create_engine(
        'mssql+pymssql://%s:%s@%s:%s/%s' % (
            config.user,
            config.password,
            config.server,
            config.port,
            config.database
        ),
        echo=False
    )

meta = sa.MetaData()
Base = declarative_base(metadata=meta)
Session = sessionmaker(bind=engine)

#sess = Session()

class SAObj(Base):
    __tablename__ = 'sa_test_objs'
    id = sa.Column(sa.Integer, primary_key=True)
    name = sa.Column(sa.String(50))
    data = sa.Column(sa.PickleType)

#saotbl = SAObj.__table__
#
#saotbl.drop(engine, checkfirst=True)
#saotbl.create(engine)

@mssql_server_required
class TestSA(unittest.TestCase):

    def setUp(self):
        self.sess = Session()
        self.saotbl = SAObj.__table__
        self.saotbl.drop(engine, checkfirst=True)
        self.saotbl.create(engine)

    def tearDown(self):
        # issue rollback first, otherwise clearing the table might give us
        # an error that the session is in a bad state
        self.sess.rollback()
        self.sess.execute(SAObj.__table__.delete())
        self.sess.commit()

    def test_basic_usage(self):
        s = SAObj(name='foobar')
        self.sess.add(s)
        self.sess.commit()
        assert s.id
        assert self.sess.query(SAObj).count() == 1

    def test_pickle_type(self):
        s = SAObj(name='foobar', data=['one'])
        self.sess.add(s)
        self.sess.commit()
        res = self.sess.execute(sa.select([self.saotbl.c.data]))
        row = res.fetchone()
        eq_(row['data'], ['one'])
