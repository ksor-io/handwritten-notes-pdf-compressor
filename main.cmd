@ECHO OFF
SETLOCAL enabledelayedexpansion

where /Q gswin64c
IF errorlevel 1 (
  echo ghostscript is not installed on your system. Go to https://ghostscript.com/releases/gsdnld.html, download and install. You may have forgotten to install ImageMagick ^(https://imagemagick.org/script/download.php^) too.
  PAUSE
  EXIT /B
)

where /Q magick.exe
IF errorlevel 1 (
  echo ImageMagick is not installed on your system. Go to ^(https://imagemagick.org/script/download.php^), download and install.
  PAUSE
  EXIT /B
)

SET "installDir=%USERPROFILE%\AppData\Roaming\NotesCompressor"
SET "settingsFile=%installDir%\settings.txt"

:: this program is meant to be run exclusively from file exploerer context menu, therefore if this program is run w/o flags (like when someone double clicks the file) - it will default to "install" mode.

IF NOT [%1] == [] (
  GOTO load_settings
) ELSE (
  net session >NUL 2>&1
  IF errorlevel 1 (
    echo Please run as admin ^(visit https://github.com/ksor-io/handwritten-notes-pdf-compressor for help.^)
    PAUSE
    EXIT /B
  )
  echo Installing. Made by https://github.com/ksor-io with ^<3.
  IF EXIST "%settingsFile%" (
    echo A settings file has been detected. Would you like to keep the current settings ^(y^) or reset them to defaults ^(n^)? 
    SET /p "to_reset=[y/n]: "
    IF /I "!to_reset!"=="n" GOTO dont_backup
    IF /I "!to_reset!"=="no" GOTO dont_backup

    SET "restore_settings=True"
    move "%settingsFile%" "%USERPROFILE%\AppData\Local\Temp\" >NUL 2>&1
    echo Noted, I will make sure to keep your settings.
    GOTO exit_if

    :dont_backup
    echo Noted, I will reset the settings to default.
  )
  :exit_if
  echo Copying...
  mkdir "%installDir%" >NUL 2>&1
  copy "%0" "%installDir%\" >NUL 2>&1

  REG QUERY "HKCR\*\shell\Compress this file\command" | findstr c:"%installDir%\main.cmd %%1" >NUL 2>&1
  IF errorlevel 1 (
    echo Adding to context menu...
    reg add "HKCR\*\shell\Compress this file" /t REG_SZ /F >NUL 2>&1
    reg add "HKCR\*\shell\Compress this file\command" /t REG_SZ /d "%installDir%\main.cmd %%1" /F >NUL 2>&1
  )
  IF DEFINED restore_settings (
    echo Restoring settings...
    move "%USERPROFILE%\AppData\Local\Temp\settings.txt" "%installDir%\" >NUL 2>&1
  ) ELSE (
    echo Resetting settings...
    CALL :create_settings
  )
  echo Install is done. You may delete this file ^(%0^) if you wish.
  PAUSE
  EXIT /B
)

:load_settings
IF EXIST "%settingsFile%" (
  FOR /F %%i IN (%settingsFile%) DO SET %%i
) ELSE (
  call :create_settings
  FOR /F %%i IN (%settingsFile%) DO SET %%i 
)

SET "tempFolder=%USERPROFILE%\AppData\Local\Temp\NotesCompressor"
mkdir "%tempFolder%" >NUL 2>&1

IF /I "%thresholdUnit%"=="MB" (
  SET "multiplier=1048576"
  GOTO multiplier_set
)
IF /I "%thresholdUnit%"=="KB" (
  SET "multiplier=1024"
  GOTO multiplier_set
)
echo invalid thresholdUnit, using MB.
SET "multiplier=1048576"
:multiplier_set
SET /a "thresholdInBytes=%threshold%*%multiplier%"

::for readabilty purposes

SET "fileSize=%~z1"

IF %fileSize% LEQ %thresholdInBytes% (
  
  ::file is already small enough, so we can compress losslessly with ghostscript
  echo Compressing...
  gswin64c.exe -q -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="%~p1\%~n1-compressed.pdf" %1 -dBATCH
  
  ::only way to check a file's size I could find is to load it in like so
  echo %~p1\%~n1-compressed.pdf > "%tempFolder%\compressedFileLocation.txt"
  FOR /F %%i IN ("%tempFolder%\compressedFileLocation.txt") DO (
    IF %fileSize% LSS %%~zi (
      echo NOTE: The file you are trying to compress is already smaller than the threshold. We did not manage to reduce it even further without loss of quality.
      rmdir /Q /s "%tempFolder%"
      del "%~p1\%~n1-compressed.pdf"
      PAUSE
      EXIT /B
    )
    rmdir /Q /s "%tempFolder%"
    EXIT /B
  )
)

:: playing around, these values seem to be a good comprimise between speed / filesize / quality

SET "DPI=450"
SET "Q=90"

mkdir "%tempFolder%\temp-images" >NUL 2>&1
:return_here_if_too_big

:: convert PDF to images
echo Converting to JPEGs...
gswin64c.exe -q -dNOPAUSE -sDEVICE=jpeg -r%DPI% -dJPEGQ=%Q% -sOutputFile="%tempFolder%\temp-images\page-%%04d.jpeg" %1 -dBATCH

:: convert back
echo Converting back to PDF...
magick "%tempFolder%\temp-images\page-*.jpeg" "%~p1\%~n1-compressed.pdf"

echo %~p1\%~n1-compressed.pdf > "%tempFolder%\compressedFileLocation.txt"
FOR /F %%i IN ("%tempFolder%\compressedFileLocation.txt") DO (
  IF %%~zi LSS %thresholdInBytes% (
    echo File compressed.
    rmdir /Q /s "%tempFolder%"
    EXIT /B
  )
  ELSE (
    IF %Q% GTR 5 (
      IF %DPI% GTR 300 (SET /A "DPI-=50")
      SET /A "Q-=5"
      echo File still too big... Trying again.
      GOTO return_here_if_too_big
    )
    echo This file is too big... we were unable to compress it below the threshold.
    rmdir /Q /s "%tempFolder%"
    PAUSE
    EXIT /B
  )
)

::subroutines

:create_settings
mkdir "%installDir%" >NUL 2>&1
(echo "threshold=10" && echo "thresholdUnit=MB") > "%settingsFile%"
GOTO:eof