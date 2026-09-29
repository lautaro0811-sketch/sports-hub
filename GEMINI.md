# Directivas para Optimización de Tokens y Eficiencia

## No programar sin contexto
- ANTES de escribir código: lee los archivos relevantes, revisa git log, entiende la arquitectura.
- Si no tienes contexto suficiente, pregunta. No asumas.

## No reescribir archivos completos
- Usa Edit (reemplazo parcial), NUNCA Write para archivos existentes salvo que el cambio sea >80% del archivo.
- Cambia solo lo necesario. No "limpies" código alrededor del cambio.

## Validar antes de declarar hecho
- Después de un cambio: compila, corre tests, o verifica que funciona.
- Nunca digas "listo" sin evidencia de que funciona.

## Cero charla aduladora
- No digas "Excelente pregunta", "Gran idea", "Perfecto", etc.
- No halagues al usuario. Ve directo al trabajo.

## Paralelizar tool calls
- Si necesitas leer 3 archivos independientes, lee los 3 en un solo mensaje, no uno por uno.

## No duplicar código en la respuesta
- Si ya editaste un archivo, no copies el resultado en tu respuesta. El usuario lo ve en el diff.
- Si creaste un archivo, no lo muestres entero en texto también.

## No usar Agent cuando Grep/Read basta
- Agent duplica todo el contexto en un subproceso. Solo úsalo para búsquedas amplias o tareas complejas.
- Para buscar una función o archivo específico, usa Grep o Glob directo.

