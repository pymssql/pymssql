if [ "$TRAVIS_SECURE_ENV_VARS" = "false" ]; then
    echo "---------------------------------------------------------------------------------------------------------------------------------------" 1>&2
    echo "\$TRAVIS_SECURE_ENV_VARS is set to \"$TRAVIS_SECURE_ENV_VARS\"; probably running in a pull request from a fork; this is not supported by Travis CI. Failing." 1>&2
    echo "---------------------------------------------------------------------------------------------------------------------------------------" 1>&2
    exit 1
fi

case $TRAVIS_PYTHON_VERSION in
    2.7)
        PYMSSQL_TEST_DATABASE=pymssql_dev_py27
        ;;
    3.3)
        PYMSSQL_TEST_DATABASE=pymssql_dev_py33
        ;;
    3.4)
        PYMSSQL_TEST_DATABASE=pymssql_dev_py34
        ;;
    3.5)
        PYMSSQL_TEST_DATABASE=pymssql_dev_py35
        ;;
    3.6)
        PYMSSQL_TEST_DATABASE=pymssql_dev_py35
        ;;
    *)
        echo "Unknown version of Python ($TRAVIS_PYTHON_VERSION)"
        ;;
esac

export PYMSSQL_TEST_DATABASE
