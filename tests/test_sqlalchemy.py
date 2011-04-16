from nose.plugins.skip import SkipTest
from nose.tools import eq_

import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

from .helpers import config

engine = sa.create_engine(
        'mssql+pymssql://%s:%s@%s:%s/%s?charset=UTF-8' % (
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

sess = Session()

class SAObj(Base):
    __tablename__ = 'sa_test_objs'
    id = sa.Column(sa.Integer, primary_key=True)
    name = sa.Column(sa.String(50))
    data = sa.Column(sa.PickleType)

saotbl = SAObj.__table__

saotbl.drop(engine)
saotbl.create(engine)

class TestSA(object):

    def tearDown(self):
        # issue rollback first, otherwise clearing the table might give us
        # an error that the session is in a bad state
        sess.rollback()
        sess.execute(SAObj.__table__.delete())
        sess.commit()

    def test_long_identifiers(self):

        class LongIdent(Base):
            """
                This test definition will cause the tests to fail until the line:

                max_identifier_length = 30

                is removed from:

                sqlalchemy.dialects.mssql.pymssql
            """
            __tablename__ = 'sa_test_long_idents_greater_than_30_chars_bc_of_old_pymssql_limit'
            id = sa.Column(sa.Integer, primary_key=True)
            name = sa.Column(sa.String(50))
        try:
            LongIdent.__table__.create(engine)
            assert False, 'SQLALchemy is no longer limiting identifier lengths!'
        except sa.exc.IdentifierError:
            pass

    def test_basic_usage(self):
        s = SAObj(name='foobar')
        sess.add(s)
        sess.commit()
        assert s.id
        assert sess.query(SAObj).count() == 1

    def test_pickle_type(self):
        s = SAObj(name='foobar', data=['one'])
        sess.add(s)
        sess.commit()
        res = sess.execute(sa.select([saotbl.c.data]))
        #raise SkipTest # SA pickle columns cause us problems, delete this skip to see
        row = res.fetchone()
        eq_(row['data'], ['one'])
