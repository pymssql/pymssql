"""
Test GIL safety for free-threaded Python builds.

This test verifies that pymssql extension modules are properly marked
as GIL-safe and can run without the GIL in free-threaded Python builds.
"""

import sys
import subprocess
import unittest

import pytest


def is_free_threaded():
    """Check if running in free-threaded Python."""
    return (
        sys.version_info >= (3, 14)
        and hasattr(sys, "_is_gil_enabled")
        and not sys._is_gil_enabled()
    )


@pytest.mark.skipif(not is_free_threaded(), reason="Requires free-threaded Python")
@pytest.mark.mssql_server_required
class GILSafetyTests(unittest.TestCase):
    """Test that pymssql is GIL-safe."""

    def test_module_loads_without_gil_warning(self):
        """Test that pymssql modules load without GIL re-enablement warning."""
        # Import in a subprocess to catch warnings
        code = """
import sys
import warnings

if not hasattr(sys, '_is_gil_enabled'):
    print("SKIPPED: Not free-threaded Python")
    sys.exit(0)

if sys._is_gil_enabled():
    print("SKIPPED: GIL is enabled")
    sys.exit(0)

# Capture warnings
with warnings.catch_warnings(record=True) as w:
    warnings.simplefilter("always")

    # Import pymssql modules
    import pymssql._mssql
    import pymssql._pymssql

    # Check for GIL re-enablement warnings
    gil_warnings = [warning for warning in w
                   if 'global interpreter lock' in str(warning.message).lower()
                   or 'gil' in str(warning.message).lower()]

    if gil_warnings:
        print(f"FAIL: Found {len(gil_warnings)} GIL-related warnings:")
        for warning in gil_warnings:
            print(f"  {warning.category.__name__}: {warning.message}")
        sys.exit(1)
    else:
        print("PASS: No GIL re-enablement warnings")
        sys.exit(0)
"""
        result = subprocess.run(
            [sys.executable, "-c", code],
            capture_output=True,
            text=True,
            env={**subprocess.os.environ, "PYTHON_GIL": "0"},
        )

        output = result.stdout.strip()
        if output.startswith("SKIPPED"):
            self.skipTest(output.split(":")[1].strip())
        elif output.startswith("FAIL"):
            self.fail(f"Module loaded with GIL warnings:\n{output}")
        elif output.startswith("PASS"):
            # Success
            pass
        else:
            self.fail(f"Unexpected output: {output}")

    def test_gil_remains_disabled_after_import(self):
        """Test that GIL remains disabled after importing pymssql."""
        if not hasattr(sys, "_is_gil_enabled"):
            self.skipTest("Not free-threaded Python")

        if sys._is_gil_enabled():
            self.skipTest("GIL is enabled")

        # Import pymssql
        import pymssql._mssql
        import pymssql._pymssql

        # Verify GIL is still disabled
        self.assertFalse(
            sys._is_gil_enabled(),
            "GIL was re-enabled after importing pymssql modules",
        )

    def test_gil_enabled_flag_in_subprocess(self):
        """Test that PYTHON_GIL=0 works correctly in subprocess."""
        if not hasattr(sys, "_is_gil_enabled"):
            self.skipTest("Not free-threaded Python")

        code = """
import sys
if hasattr(sys, '_is_gil_enabled'):
    print(f"GIL_ENABLED: {sys._is_gil_enabled()}")
else:
    print("NO_GIL_CHECK")
"""
        result = subprocess.run(
            [sys.executable, "-c", code],
            capture_output=True,
            text=True,
            env={**subprocess.os.environ, "PYTHON_GIL": "0"},
        )

        output = result.stdout.strip()
        if output.startswith("GIL_ENABLED:"):
            gil_enabled = output.split(":")[1].strip() == "True"
            self.assertFalse(
                gil_enabled, "GIL should be disabled with PYTHON_GIL=0"
            )
        elif output == "NO_GIL_CHECK":
            self.skipTest("Python version doesn't support GIL query")
        else:
            self.fail(f"Unexpected output: {output}")

    def test_concurrent_operations_without_gil(self):
        """Test concurrent operations work correctly without GIL."""
        if not hasattr(sys, "_is_gil_enabled"):
            self.skipTest("Not free-threaded Python")

        if sys._is_gil_enabled():
            self.skipTest("GIL is enabled")

        import threading
        from pymssql.tests.helpers import mssqlconn

        num_threads = 10
        results = []
        exceptions = []

        def query_thread(thread_id):
            try:
                with mssqlconn() as mssql:
                    for i in range(50):
                        result = mssql.execute_scalar("SELECT %d * %d", (thread_id, i))
                        assert result == thread_id * i
                results.append(thread_id)
            except Exception as exc:
                exceptions.append(exc)

        threads = [threading.Thread(target=query_thread, args=(i,)) for i in range(num_threads)]

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join(timeout=30)

        self.assertEqual(len(exceptions), 0, f"Exceptions occurred: {exceptions}")
        self.assertEqual(len(results), num_threads)


if __name__ == "__main__":
    if is_free_threaded():
        print("Running GIL safety tests")
    else:
        print("Skipping GIL safety tests (not running in free-threaded Python)")
