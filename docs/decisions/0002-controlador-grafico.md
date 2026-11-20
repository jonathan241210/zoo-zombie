# ADR-0002: Controlador gráfico de Windows

**Estado:** Aceptado para corregir la pérdida del dispositivo gráfico · **Fecha:** 2026-11-20

## Contexto

Al acercarse a la jirafa, el registro muestra fallos al crear buffers con el código `0x887A0005` y después recursos `RID` inválidos en `minimap_overlay.gd`. El proyecto estaba configurado explícitamente para usar Direct3D 12 (`d3d12`) en Windows. Ese código corresponde a `DXGI_ERROR_DEVICE_REMOVED`: Windows perdió o reinició el dispositivo gráfico; los errores de los dibujos del minimapa aparecen después al intentar usar recursos del dispositivo perdido.

## Decisión

Configurar Vulkan como controlador gráfico de Windows (`rendering/rendering_device/driver.windows = "vulkan"`). Godot 4.7 documenta Direct3D 12 como experimental y recomienda Vulkan para la mayoría de los proyectos.

## Consecuencias

- Se prueba el juego usando el controlador principal de Godot en Windows.
- Forward+ y sus funciones actuales permanecen disponibles.
- Si el problema continúa con Vulkan, se revisan el controlador de la GPU y la carga gráfica del mapa por separado.
- La decisión se puede revertir cambiando la propiedad a `d3d12`.
