cd pymssql

# Check the Python version
case $PYTHON_VERSION in
    27)
        PYTHON=python2.7
        ;;
    31)
        PYTHON=python3.1
        echo "Python 3.1 not supported yet"
        exit 0
        ;;
    *)
        echo "Unknown version of Python"
        exit 1
        ;;
esac

# Check the Platform
if [ $(expr match "$PLATFORM" 'win') -gt 0 ]; then
    if [ "$PLATFORM" = "win32" ]; then
        export WINEPREFIX="$HOME/.wine32"
        export WINEARCH="win32"
    elif [ "$PLATFORM" = "win64" ]; then
        export WINEPREFIX="$HOME/.wine64"
        unset WINEARCH
    else
        echo "Unknown version of Windows"
        exit 1
    fi

    PYDIR="c:\Python$PYTHON_VERSION"

    PYTHON="$PYDIR\python.exe"
    SCRIPTS="$PYDIR\Scripts"

    # Do a clean to start out
    wine $PYTHON setup.py clean

    # Remove possibly left over directories
    rm -rf build dist

    # Build pymssql and create binaries
    wine $PYTHON setup.py build -c mingw32 bdist --formats=egg,wininst

    # Copy the binaries over to the downloads directory
    cp dist/pymssql-*.egg /srv/http/nginx/downloads/pymssql/snapshots/
    cp dist/pymssql-*.exe /srv/http/nginx/downloads/pymssql/snapshots/

elif [ "$PLATFORM" = "linux" ]; then

    # Create the virtual python environment
    PYTHON_ENV=$(mktemp -d)

    if [ "$PYTHON" = "python3.1" ]; then
        VIRTUAL_ENV="python /usr/lib/python3.1/site-packages/virtualenv3.py"
    else
        VIRTUAL_ENV="virtualenv --distribute"
    fi

    $VIRTUAL_ENV --python=$PYTHON $PYTHON_ENV

    # Activate the virtual environment
    source $PYTHON_ENV/bin/activate

    # Install Cython
    easy_install Cython

    # Clean up the workspace
    python setup.py clean
    rm -rf build dist

    # Test building pymssql
    python setup.py build -c unix

    # Create a pymssql egg
    python setup.py bdist_egg

    # Copy the egg over to the downloads directory
    cp dist/pymssql-*.egg /srv/http/nginx/downloads/pymssql/snapshots/

    # Remove the vitualenv
    rm -rf $VIRTUAL_ENV
fi;
