#!/bin/bash

# Ruta al compilador de shaders
SHADER_COMPILER="./tools/sokol-shdc"
SHADER_URL="https://raw.githubusercontent.com/floooh/sokol-tools-bin/master/bin/linux/sokol-shdc"
SHADER_DIR="./tools"

# Verificar si el compilador de shaders ya existe
if [ ! -f "$SHADER_COMPILER" ]; then
    echo "El compilador de shaders no se encuentra en la ruta especificada. Descargando..."

    # Crear el directorio de herramientas si no existe
    mkdir -p $SHADER_DIR

    # Descargar el compilador de shaders
    curl -L -o $SHADER_COMPILER $SHADER_URL

    # Verificar si la descarga fue exitosa
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo descargar el compilador de shaders."
        exit 1
    fi

    # Hacer que el archivo sea ejecutable
    chmod +x $SHADER_COMPILER
    echo "Compilador de shaders descargado y configurado."
else
    echo "El compilador de shaders ya está presente."
fi

# Ruta de entrada y salida de shaders
SHADER_INPUT="./shaders/shader.glsl"
SHADER_OUTPUT="./shaders/shader.odin"
FORMAT="sokol_odin"
LANGUAGES="glsl430:hlsl5:metal_macos"

# Compilar el shader
echo "Compilando shader..."
$SHADER_COMPILER -i $SHADER_INPUT -o $SHADER_OUTPUT -f $FORMAT -l $LANGUAGES

# Verificar si el comando anterior tuvo éxito
if [ $? -ne 0 ]; then
    echo "Error: Falló la compilación del shader."
    exit 1
fi

echo "Shader compilado exitosamente."

# Verificar parámetro de ejecución
if [ "$1" == "run" ]; then
    echo "Ejecutando Odin..."
    odin run main --debug
else
    echo "Compilando Odin..."
    odin build main --debug
fi

# Verificar si Odin terminó con error
if [ $? -ne 0 ]; then
    echo "Error: La operación de Odin falló."
    exit 1
fi

echo "Operación completada con éxito."

