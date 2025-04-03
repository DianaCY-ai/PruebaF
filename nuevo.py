#Hola
#crear codigo python#Hola
#crear codigo python

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
