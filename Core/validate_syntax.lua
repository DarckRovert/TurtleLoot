-- Script para validar la sintaxis de Communication.lua
local file = io.open([[E:\Turtle Wow\Interface\AddOns\TurtleLoot\Core\Communication.lua]], "r")
if not file then
    print("No se pudo abrir el archivo")
    return
end

local content = file:read("*all")
file:close()

-- Intentar cargar el archivo como código Lua
local func, err = loadstring(content)
if not func then
    print("ERROR DE SINTAXIS:")
    print(err)
else
    print("El archivo tiene sintaxis válida")
end
