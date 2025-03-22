@echo off
setlocal enabledelayedexpansion

rem Ruta al compilador de shaders
set SHADER_COMPILER=tools\sokol-shdc.exe
set SHADER_URL=https://raw.githubusercontent.com/floooh/sokol-tools-bin/master/bin/win32/sokol-shdc.exe
set SHADER_DIR=tools

rem Verificar si el compilador de shaders ya existe
if not exist "%SHADER_COMPILER%" (
    echo El compilador de shaders no se encuentra en la ruta especificada. Descargando...

    rem Crear el directorio de herramientas si no existe
    if not exist "%SHADER_DIR%" mkdir "%SHADER_DIR%"

    rem Descargar el compilador de shaders
    powershell -Command "Invoke-WebRequest -Uri '%SHADER_URL%' -OutFile '%SHADER_COMPILER%'"

    rem Verificar si la descarga fue exitosa
    if not exist "%SHADER_COMPILER%" (
        echo Error: No se pudo descargar el compilador de shaders.
        exit /b 1
    )

    echo Compilador de shaders descargado y configurado.
) else (
    echo El compilador de shaders ya está presente.
)

rem Ruta de entrada y salida de shaders
set SHADER_INPUT=shaders\shader.glsl
set SHADER_OUTPUT=shaders\shader.odin
set FORMAT=sokol_odin
set LANGUAGES=glsl430:hlsl5:metal_macos

rem Compilar el shader
echo Compilando shader...
"%SHADER_COMPILER%" -i "%SHADER_INPUT%" -o "%SHADER_OUTPUT%" -f "%FORMAT%" -l "%LANGUAGES%"
if %errorlevel% neq 0 (
    echo Error: Fallo la compilacion del shader.
    exit /b 1
)

echo Shader compilado exitosamente.

rem Verificar parametro de ejecucion
if "%1"=="run" (
    echo Ejecutando Odin...
    odin run main --debug
) else (
    echo Compilando Odin...
    odin build main --debug
)

rem Verificar si Odin termino con error
if %errorlevel% neq 0 (
    echo Error: La operacion de Odin fallo.
    exit /b 1
)

echo Operacion completada con exito.
endlocal
