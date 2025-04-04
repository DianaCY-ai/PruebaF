# repaso.py

# Comentarios
# Esto es un comentario de una sola línea

"""
Esto es un comentario
de múltiples líneas
"""

# Variables y tipos de datos
entero = 10
flotante = 10.5
cadena = "Hola, Mundo"
booleano = True

print("Variables y tipos de datos:")
print(entero)
print(flotante)
print(cadena)
print(booleano)
print()

# Estructuras de control
# Condicionales
print("Estructuras de control - Condicionales:")
if entero > 5:
    print("El número es mayor que 5")
else:
    print("El número es 5 o menor")
print()

# Bucles
print("Estructuras de control - Bucles:")
for i in range(5):
    print(f"Iteración {i}")

contador = 0
while contador < 5:
    print(f"Contador: {contador}")
    contador += 1
print()

# Funciones
print("Funciones:")
def saludar(nombre):
    return f"Hola, {nombre}"

print(saludar("Juan"))
print()

# Listas
print("Listas:")
lista = [1, 2, 3, 4, 5]
print(lista)
lista.append(6)
print(lista)
print(f"Elemento en la posición 2: {lista[2]}")
print()

# Diccionarios
print("Diccionarios:")
diccionario = {"nombre": "Juan", "edad": 30}
print(diccionario)
print(f"Nombre: {diccionario['nombre']}")
diccionario["edad"] = 31
print(f"Edad actualizada: {diccionario['edad']}")
print()

# Manejo de excepciones
print("Manejo de excepciones:")
try:
    resultado = 10 / 0
except ZeroDivisionError:
    print("Error: División por cero")
finally:
    print("Bloque finally ejecutado")
print()

# Ejemplo completo
print("Ejemplo completo:")
def operaciones_basicas(a, b, operacion):
    """
    Realiza operaciones matemáticas básicas entre dos números.

    Parámetros:
    a (float): El primer número.
    b (float): El segundo número.
    operacion (str): La operación a realizar. Puede ser 'suma', 'resta', 'multiplicacion' o 'division'.

    Retorna:
    float: El resultado de la operación.
    """
    if operacion == 'suma':
        return a + b
    elif operacion == 'resta':
        return a - b
    elif operacion == 'multiplicacion':
        return a * b
    elif operacion == 'division':
        if b != 0:
            return a / b
        else:
            return "Error: División por cero"
    else:
        return "Operación no válida"

# Ejemplo de uso
resultado = operaciones_basicas(10, 5, 'suma')
print(f"Resultado de la suma: {resultado}")
