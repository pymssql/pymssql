Creating a release of pymssql
=============================

* Setting the needed version constant(s) in the source code
* Creating/updating the changelog, release notes, etc. documents
* Make sure the documentation builds
* Cleaning the workspace
* Running tests
* Tagging the release in Git
* Pushing to GitHub
* Creating sdists
* Verifying tarball contents
* Creating wheels
* Creating windows binaries
* Uploading files to PyPI
* Signing / creating hashes of the published files ?
* Performing any needed admin tasks on GitHub / ReadTheDocs ?
* Sending out announcement emails / Posting to relevant sites ?

Marc:

- Try to go through open PRs and see if anything can be merged.
- Update the ChangeLog file (probably the most time-consuming part because I have to dig through the git history; I'll do a git log and ask for everything since the tag of the last release; still a lot to sift through; maybe we want to get in the habit of updating the ChangeLog each time we merge? We've been doing this at work lately and it seems pretty good)
- Increment version number
- Commit updated version number
- python setup.py sdist upload
- I think I've sometimes had to clean up invalid RST and stuff in the README or ChangeLog after doing this because if PyPI gets bad RST, then it renders the stuff as text and it's ugly. So might have to commit some formatting fixes.
- git tag the release
- Build and upload eggs and wheels for various platforms - python setup.py bdist_egg bdist_wheel upload
