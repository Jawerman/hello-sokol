#!/bin/bash

# Ruta al compilador de shaders
SHADER_COMPILER="./tools/sokol-shdc"
SHADER_INPUT="./shaders/shader.glsl"
SHADER_OUTPUT="./shaders/shader.odin"
FORMAT="sokol_odin"
LANGUAGES="glsl430:hlsl5:metal_macos"

# Compilar el shader
echo "Compilando shader..."
$SHADER_COMPILER -i $SHADER_INPUT -o $SHADER_OUTPUT -f $FORMAT -l $LANGUAGES

# Verificar si el comando anterior tuvo éxito
if [ $? -ne 0 ]; then
    echo "Error: Fallo la compilación del shader."
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
