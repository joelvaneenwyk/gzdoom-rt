@echo off
goto:$AfterCopyright

:: **
:: ** auto-setup-windows.cmd
:: ** Automatic (easy) setup and build script for Windows
:: **
:: ** Note that this script assumes you have both 'git' and 'cmake' installed properly and in your PATH!
:: ** This script also assumes you have installed a build system that cmake can automatically detect.
:: ** Such as Visual Studio Community. Requires appropriate SDK installed too!
:: ** Without these items, this script will FAIL! So make sure you have your build environment properly
:: ** set up in order for this script to succeed.
:: **
:: ** The purpose of this script is to get someone easily going with a full working compile of GZDoom.
:: ** This allows anyone to make simple changes or tweaks to the engine as they see fit and easily
:: ** compile their own copy without having to follow complex instructions to get it working.
:: ** Every build environment is different, and every computer system is different - this should work
:: ** in most typical systems under Windows but it may fail under certain types of systems or conditions.
:: ** Not guaranteed to work and your mileage will vary.
:: **
:: **---------------------------------------------------------------------------
:: ** Copyright 2023 Rachael Alexanderson and the GZDoom team
:: ** All rights reserved.
:: **
:: ** Redistribution and use in source and binary forms, with or without
:: ** modification, are permitted provided that the following conditions
:: ** are met:
:: **
:: ** 1. Redistributions of source code must retain the above copyright
:: **    notice, this list of conditions and the following disclaimer.
:: ** 2. Redistributions in binary form must reproduce the above copyright
:: **    notice, this list of conditions and the following disclaimer in the
:: **    documentation and/or other materials provided with the distribution.
:: ** 3. The name of the author may not be used to endorse or promote products
:: **    derived from this software without specific prior written permission.
:: **
:: ** THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
:: ** IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
:: ** OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
:: ** IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
:: ** INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
:: ** NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
:: ** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
:: ** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
:: ** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
:: ** THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
:: **---------------------------------------------------------------------------
:: **

:Build
setlocal EnableExtensions
    git -C "%SOURCE_ROOT%" submodule update --init --recursive

    set "BUILD_ROOT=%SOURCE_ROOT%\.build"
    if not exist "%BUILD_ROOT%" mkdir "%BUILD_ROOT%"

    set "VCPKG_ROOT=%SOURCE_ROOT%\libraries\vcpkg"
    set "VCPKG_INSTALLED=%BUILD_ROOT%\vcpkg_installed"
    if not exist "%VCPKG_INSTALLED%" mkdir "%VCPKG_INSTALLED%"
    if exist "%VCPKG_ROOT%" git -C "%VCPKG_ROOT%" pull --rebase --autostash

    set "ZMUSIC_ROOT=%SOURCE_ROOT%\libraries\zmusic"
    if exist "%ZMUSIC_ROOT%" git -C "%ZMUSIC_ROOT%" pull --rebase --autostash

    set "ZMUSIC_BUILD_ROOT=%BUILD_ROOT%\zmusic"
    if not exist "%ZMUSIC_BUILD_ROOT%" mkdir "%ZMUSIC_BUILD_ROOT%"

    cmake -A x64 -S "%ZMUSIC_ROOT%" -B "%ZMUSIC_BUILD_ROOT%" ^
        -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake" ^
        -DVCPKG_LIBSNDFILE=1 ^
        -DVCPKG_INSTALLLED_DIR="%VCPKG_INSTALLED%"
    cmake --build "%ZMUSIC_BUILD_ROOT%" --config Release -- -maxcpucount -verbosity:minimal

    set "DOOM_BUILD_ROOT=%BUILD_ROOT%\doom"
    cmake -A x64 -S "%SOURCE_ROOT%" -B "%DOOM_BUILD_ROOT%" ^
        -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake" ^
        -DZMUSIC_INCLUDE_DIR="%ZMUSIC_ROOT%/include" ^
        -DZMUSIC_LIBRARIES="%ZMUSIC_BUILD_ROOT%/source/Release/zmusic.lib" ^
        -DVCPKG_INSTALLLED_DIR="%VCPKG_INSTALLED%"
    cmake --build "%DOOM_BUILD_ROOT%" --config RelWithDebInfo -- -maxcpucount -verbosity:minimal

    rem -- If successful, show the build
    if exist "%DOOM_BUILD_ROOT%\RelWithDebInfo\gzdoom.exe" explorer.exe "%DOOM_BUILD_ROOT%\RelWithDebInfo"
endlocal & exit /b %ERRORLEVEL%

:$AfterCopyright
setlocal EnableExtensions EnableDelayedExpansion
    set "SOURCE_ROOT=%~dp0"
    :: remove trailing slash if there is one
    if "!SOURCE_ROOT:~-1!"=="\" set "SOURCE_ROOT=!SOURCE_ROOT:~0,-1!"

    call :Build "!SOURCE_ROOT!"
endlocal & exit /b %ERRORLEVEL%
