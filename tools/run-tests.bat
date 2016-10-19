@echo off

setlocal
setlocal EnableDelayedExpansion

set Configuration=Release
if not X%1==X set Configuration=%1

cd %~dp0..
set ProjRoot=%cd%

cd build\VStudio
if not exist build\%Configuration% echo === No tests found >&2 & goto fail
cd build\%Configuration%

launchctl-x64 start memfs64 testdsk ""            M: >nul
launchctl-x64 start memfs64 testnet \memfs64\test N: >nul
launchctl-x64 start memfs32 testdsk ""            O: >nul
launchctl-x64 start memfs32 testnet \memfs32\test P: >nul
rem Cannot use timeout under cygwin/mintty: "Input redirection is not supported"
waitfor 7BF47D72F6664550B03248ECFE77C7DD /t 3 2>nul
cd M: >nul 2>nul || (echo === Unable to find drive M: >&2 & goto fail)
cd N: >nul 2>nul || (echo === Unable to find drive N: >&2 & goto fail)
cd O: >nul 2>nul || (echo === Unable to find drive O: >&2 & goto fail)
cd P: >nul 2>nul || (echo === Unable to find drive P: >&2 & goto fail)

set testpass=0
set testfail=0
for %%f in (:winfsp-tests-x64 :winfsp-tests-x86 :fsx-memfs-x64 :fsx-memfs-x86 :winfstest-memfs-x64 :winfstest-memfs-x86) do (
    echo === Running %%f

    if defined APPVEYOR (
        appveyor AddTest "%%f" -FileName None -Framework None -Outcome Running
    )

    pushd %cd%
    call %%f
    popd

    if !ERRORLEVEL! neq 0 (
        set /a testfail=testfail+1

        echo === Failed %%f

        if defined APPVEYOR (
            appveyor UpdateTest "%%f" -FileName None -Framework None -Outcome Failed -Duration 0
        )
    ) else (
        set /a testpass=testpass+1

        echo === Passed %%f

        if defined APPVEYOR (
            appveyor UpdateTest "%%f" -FileName None -Framework None -Outcome Passed -Duration 0
        )
    )
    echo:
)

launchctl-x64 stop memfs64 testdsk >nul
launchctl-x64 stop memfs64 testnet >nul
launchctl-x64 stop memfs32 testdsk >nul
launchctl-x64 stop memfs32 testnet >nul

set /a total=testpass+testfail
echo === Total: %testpass%/%total%
if not %testfail%==0 goto fail

exit /b 0

:fail
exit /b 1

:winfsp-tests-x64
echo winfsp-tests-x64
winfsp-tests-x64
if errorlevel 1 goto fail
echo winfsp-tests-x64 --case-randomize
winfsp-tests-x64 --case-randomize
if errorlevel 1 goto fail
echo winfsp-tests-x64 --mountpoint=X:
winfsp-tests-x64 --mountpoint=X:
if errorlevel 1 goto fail
echo winfsp-tests-x64 --mountpoint=mymnt
winfsp-tests-x64 --mountpoint=mymnt
if errorlevel 1 goto fail
echo winfsp-tests-x64 --no-traverse
winfsp-tests-x64 --no-traverse
if errorlevel 1 goto fail
exit /b 0

:winfsp-tests-x86
echo winfsp-tests-x86
winfsp-tests-x86
if errorlevel 1 goto fail
echo winfsp-tests-x86 --case-randomize
winfsp-tests-x86 --case-randomize
if errorlevel 1 goto fail
echo winfsp-tests-x86 --mountpoint=X:
winfsp-tests-x86 --mountpoint=X:
if errorlevel 1 goto fail
echo winfsp-tests-x86 --mountpoint=mymnt
winfsp-tests-x86 --mountpoint=mymnt
if errorlevel 1 goto fail
echo winfsp-tests-x86 --no-traverse
winfsp-tests-x86 --no-traverse
if errorlevel 1 goto fail
exit /b 0

:fsx-memfs-x64
M:
"%ProjRoot%\ext\test\fstools\src\fsx\fsx.exe" -N 5000 test xxxxxx
if errorlevel 1 goto fail
"%ProjRoot%\ext\test\fstools\src\fsx\fsx.exe" -f foo -N 5000 test xxxxxx
if errorlevel 1 goto fail
N:
"%ProjRoot%\ext\test\fstools\src\fsx\fsx.exe" -N 5000 test xxxxxx
if errorlevel 1 goto fail
"%ProjRoot%\ext\test\fstools\src\fsx\fsx.exe" -f foo -N 5000 test xxxxxx
if errorlevel 1 goto fail
exit /b 0

:fsx-memfs-x86
O:
"%ProjRoot%\ext\test\fstools\src\fsx\fsx.exe" -N 5000 test xxxxxx
if errorlevel 1 goto fail
"%ProjRoot%\ext\test\fstools\src\fsx\fsx.exe" -f foo -N 5000 test xxxxxx
if errorlevel 1 goto fail
P:
"%ProjRoot%\ext\test\fstools\src\fsx\fsx.exe" -N 5000 test xxxxxx
if errorlevel 1 goto fail
"%ProjRoot%\ext\test\fstools\src\fsx\fsx.exe" -f foo -N 5000 test xxxxxx
if errorlevel 1 goto fail
exit /b 0

:winfstest-memfs-x64
M:
call "%ProjRoot%\ext\test\winfstest\run-winfstest.bat"
if errorlevel 1 goto fail
N:
call "%ProjRoot%\ext\test\winfstest\run-winfstest.bat"
if errorlevel 1 goto fail
exit /b 0

:winfstest-memfs-x86
O:
call "%ProjRoot%\ext\test\winfstest\run-winfstest.bat"
if errorlevel 1 goto fail
P:
call "%ProjRoot%\ext\test\winfstest\run-winfstest.bat"
if errorlevel 1 goto fail
exit /b 0
