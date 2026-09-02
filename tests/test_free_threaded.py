"""
Test free-threaded Python support.

These tests specifically verify that pymssql works correctly with
free-threaded Python builds (cp314t and later) where the GIL is removed.
"""

import sys
import threading
import unittest

import pytest

from .helpers import mssqlconn, pymssqlconn


def is_free_threaded():
    """Check if running in free-threaded Python."""
    return sys.version_info >= (3, 14) and hasattr(sys, '_is_gil_enabled') and not sys._is_gil_enabled()


@pytest.mark.skipif(not is_free_threaded(), reason="Requires free-threaded Python")
@pytest.mark.mssql_server_required
class FreeThreadedTests(unittest.TestCase):
    """Test free-threaded specific behavior."""

    def test_concurrent_connections(self):
        """Test multiple concurrent connections without GIL."""
        num_threads = 20
        results = []
        exceptions = []

        def connect_and_query(thread_id):
            try:
                with mssqlconn() as mssql:
                    for i in range(100):
                        result = mssql.execute_scalar('SELECT %d * %d', (thread_id, i))
                        assert result == thread_id * i
                    results.append(thread_id)
            except Exception as exc:
                exceptions.append(exc)

        threads = [threading.Thread(target=connect_and_query, args=(i,))
                   for i in range(num_threads)]

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join(timeout=30)

        self.assertEqual(len(exceptions), 0)
        self.assertEqual(len(results), num_threads)

    def test_concurrent_bulk_copy(self):
        """Test concurrent bulk copy operations."""
        num_threads = 10
        rows_per_thread = 100
        exceptions = []

        def bulk_copy_thread(thread_id):
            try:
                with pymssqlconn() as conn:
                    conn._conn.execute_non_query(
                        f"CREATE TABLE free_threaded_test_{thread_id} "
                        f"(id INT, value VARCHAR(50))"
                    )

                    rows = [(i, f"value_{i}") for i in range(rows_per_thread)]
                    conn.bulk_copy(f"free_threaded_test_{thread_id}", rows)

                    conn._conn.execute_query(
                        f"SELECT COUNT(*) FROM free_threaded_test_{thread_id}"
                    )
                    count = tuple(conn._conn)[0][0]
                    assert count == rows_per_thread

                    conn._conn.execute_non_query(
                        f"DROP TABLE free_threaded_test_{thread_id}"
                    )
            except Exception as exc:
                exceptions.append(exc)

        threads = [threading.Thread(target=bulk_copy_thread, args=(i,))
                   for i in range(num_threads)]

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join(timeout=60)

        self.assertEqual(len(exceptions), 0)

    def test_concurrent_queries(self):
        """Test concurrent query execution."""
        num_threads = 15
        queries_per_thread = 50
        exceptions = []

        def query_thread(thread_id):
            try:
                with mssqlconn() as mssql:
                    for i in range(queries_per_thread):
                        result = mssql.execute_scalar(
                            'SELECT %d + %d + %d', (thread_id, i, thread_id * i)
                        )
                        expected = thread_id + i + thread_id * i
                        assert result == expected
            except Exception as exc:
                exceptions.append(exc)

        threads = [threading.Thread(target=query_thread, args=(i,))
                   for i in range(num_threads)]

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join(timeout=30)

        self.assertEqual(len(exceptions), 0)

    def test_connection_pool_simulation(self):
        """Simulate connection pool usage without GIL."""
        pool_size = 5
        num_operations = 100
        exceptions = []

        # Create connection pool
        connections = [mssqlconn() for _ in range(pool_size)]

        def pool_operation(op_id):
            try:
                # Simulate getting connection from pool
                conn = connections[op_id % pool_size]
                result = conn.execute_scalar('SELECT %d', (op_id,))
                assert result == op_id
            except Exception as exc:
                exceptions.append(exc)

        threads = [threading.Thread(target=pool_operation, args=(i,))
                   for i in range(num_operations)]

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join(timeout=30)

        for conn in connections:
            conn.close()

        self.assertEqual(len(exceptions), 0)

    def test_shared_resource_safety(self):
        """Test that shared resources are accessed safely."""
        # This tests the connection_object_list thread safety
        num_threads = 20
        exceptions = []

        def connection_lifecycle(thread_id):
            try:
                # Create and close connections rapidly
                for i in range(10):
                    conn = mssqlconn()
                    result = conn.execute_scalar('SELECT %d', (thread_id * 10 + i))
                    assert result == thread_id * 10 + i
                    conn.close()
            except Exception as exc:
                exceptions.append(exc)

        threads = [threading.Thread(target=connection_lifecycle, args=(i,))
                   for i in range(num_threads)]

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join(timeout=30)

        self.assertEqual(len(exceptions), 0)


@pytest.mark.skipif(not is_free_threaded(), reason="Requires free-threaded Python")
@pytest.mark.mssql_server_required
class FreeThreadedStressTests(unittest.TestCase):
    """Stress tests for free-threaded builds."""

    @pytest.mark.slow
    def test_high_concurrency(self):
        """Test with very high concurrency."""
        num_threads = 50
        operations_per_thread = 20
        exceptions = []

        def high_concurrency_op(thread_id):
            try:
                with mssqlconn() as mssql:
                    for i in range(operations_per_thread):
                        result = mssql.execute_scalar(
                            'SELECT %d * %d', (thread_id, i)
                        )
                        assert result == thread_id * i
            except Exception as exc:
                exceptions.append(exc)

        threads = [threading.Thread(target=high_concurrency_op, args=(i,))
                   for i in range(num_threads)]

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join(timeout=60)

        self.assertEqual(len(exceptions), 0)


if __name__ == '__main__':
    if is_free_threaded():
        print("Running free-threaded Python tests")
    else:
        print("Skipping free-threaded tests (not running in free-threaded Python)")
