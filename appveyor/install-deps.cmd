REM OpenSSL
if not exist "openssl\" (
  appveyor DownloadFile http://www.npcglib.org/~stathis/downloads/openssl-%OPENSSL_VER%-vs%VS_VER%.7z || (ping -n 10 127.0.0.1 >"nul:" & appveyor DownloadFile http://www.npcglib.org/~stathis/downloads/openssl-%OPENSSL_VER%-vs%VS_VER%.7z)
  7z x openssl-%OPENSSL_VER%-vs%VS_VER%.7z
  ren openssl-%OPENSSL_VER%-vs%VS_VER% openssl
)
REM FreeTDS
if not exist "freetds\vs%VS_VER%_%PYTHON_ARCH%" (
  rmdir /s /q freetds\vs%VS_VER%_%PYTHON_ARCH% || cmd /c "exit /b 0"
  appveyor DownloadFile https://github.com/ramiro/freetds/releases/download/v%FREETDS_VER%/vs%VS_VER%_%PYTHON_ARCH%.zip
  7z x -ofreetds vs%VS_VER%_%PYTHON_ARCH%.zip
)
