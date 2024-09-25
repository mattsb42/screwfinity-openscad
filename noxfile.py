import os
from pathlib import Path
import nox

TEST_DEPENDENCIES = [
    "pytest",
    "openscad-runner",
    "setuptools",
    "pytest-xdist[psutil]",
]
ENV = {}
HERE = Path(__file__).parent.resolve()
BUILD_VECTORS = HERE / "build" / "vectors"
PYTEST_COMMAND = ["pytest", "-n", "logical"]


def setup_environment(session):
    session.install(*TEST_DEPENDENCIES)
    if "GITHUB_ACTIONS" in os.environ:
        session.run("./start-xvfb.sh", external=True)
        ENV["DISPLAY"] = ":99"


def clean_build():
    if not BUILD_VECTORS.exists():
        return
    for child in BUILD_VECTORS.iterdir():
        child.unlink()


@nox.session
def test(session):
    setup_environment(session)
    clean_build()
    # NOTE: We do not want to paralellize the test,
    # mainly because pytest-xdist makes the output less clear.
    session.run("pytest", "-k", "not compatibility", "-v", *session.posargs, env=ENV)


@nox.session
def compatibility(session):
    setup_environment(session)
    clean_build()
    session.run(*PYTEST_COMMAND, "-k", "compatibility", "-v", *session.posargs, env=ENV)


@nox.session
@nox.parametrize("marker", [
    "screwfinity_small",
    "screwfinity_medium",
    "screwfinity_large",
    "screwfinity_medium_wide",
    "screwfinity_medium_wide_4u",
])
def artifacts(session, marker):
    setup_environment(session)
    clean_build()
    session.run(*PYTEST_COMMAND, "-k", marker, "-v", env=ENV)
