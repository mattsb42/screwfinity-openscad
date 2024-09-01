import os
from pathlib import Path
import nox

TEST_DEPENDENCIES = [
    "pytest",
    "openscad-runner",
    "setuptools",
]
ENV = {}
HERE = Path(__file__).parent.resolve()
BUILD_VECTORS = HERE / "build" / "vectors"


def setup_environment(session):
    session.install(*TEST_DEPENDENCIES)
    if "GITHUB_ACTIONS" in os.environ:
        session.run("./start-xvfb.sh", external=True)
        ENV["DISPLAY"] = ":99"


def clean_build(prefix: str=""):
    if not BUILD_VECTORS.exists():
        return
    for child in BUILD_VECTORS.iterdir():
        if child.name.startswith(prefix):
            child.unlink()


@nox.session
def test(session):
    setup_environment(session)
    clean_build()
    session.run("pytest", "-k", "not compatibility", "-v", env=ENV)


@nox.session
def compatibility(session):
    setup_environment(session)
    clean_build("screwfinity")
    session.run("pytest", "-k", "compatibility", "-v", env=ENV)
