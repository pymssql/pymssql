import os
import unittest

def find_tests():
    dirname = os.path.dirname(__file__) or '.'
    tests = []
    for item in os.listdir(dirname):
        if item[-3:] != '.py':
            continue
        module_name = item[:-3]
        module = __import__(module_name)
        suite = getattr(module, 'suite', None)
        if suite:
            tests.append(suite)
    return tests

if __name__ == '__main__':
    tests = find_tests()
    suite = unittest.TestSuite()
    suite.addTests(tests)
    unittest.TextTestRunner(verbosity=2).run(suite)
