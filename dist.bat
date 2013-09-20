del /q dist\*

python24 setup.py bdist --format=wininst
python25 setup.py bdist --format=wininst
python26 setup.py bdist --format=wininst
python26 setup.py bdist --format=egg

python26 setup.py sdist --format=zip
python26 setup.py sdist --format=gztar

REM python26 setup.py register
REM python26 setup.py sdist bdist_wininst upload
REM the same for 25 and 24 doesn't work, do that via Web

pause
