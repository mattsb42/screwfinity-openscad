import pytest


def pytest_sessionstart(session):
    """Initiate the failed test run record."""
    session.failednames = set()


def pytest_runtest_makereport(item, call):
    """Store failed test run names."""
    if call.excinfo is not None:
        item.session.failednames.add(item.originalname)


def pytest_runtest_setup(item):
    """Skip parameterized test cases if an earlier iteration failed."""
    if item.originalname in item.session.failednames:
        pytest.skip("earlier iteration failed")
