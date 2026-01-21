# Registro de Cambios (Changelog)

## v2.0.0 (Limpio y Profesional) - 21-01-2026

### Características Principales
- **Nuevo Tema UI Oscuro**: Aspecto profesional unificado en todas las ventanas (Principal, Ajustes, Dados).
- **Integración con Atlas-TW**: 
    - Detecta automáticamente el addon Atlas-TW instalado.
    - Navega por las tablas de botín directamente en el juego.
    - Botón "Generate SR List" para crear listas pre-rellenadas para Soft Reserves.
- **Sistema GDKP Mejorado**:
    - **Monitor Visual de Subasta**: Una nueva barra arrastrable que muestra el objeto actual y el tiempo de puja.
    - **Subastas Sincronizadas**: Todos los miembros de la raid con el addon ven el mismo temporizador en vivo.
    - **Anti-Snipe**: Lógica actualizada para ser más robusta.
- **Bot de Susurros Soft Reserve**:
    - Los jugadores pueden susurrar `!res [Item]` para reservar.
    - Añadidos comandos `!myres`, `!list`, y `!cancel`.
    - Localización: Las respuestas del bot están totalmente traducidas al español.

### Mejoras
- **Rendimiento**: Eliminadas las librerías Ace2 para una implementación nativa más ligera.
- **Código**: Eliminados módulos sin uso (`LootPriority`, `LootCouncil`, `PackMule`).
- **Configuración**: Corregidos problemas de visibilidad de casillas en la API de Vanilla 1.12.
- **UX**: Expandidas las áreas de clic para las casillas de configuración.

### Corrección de Errores
- Corregido error `SetShowCursor` en la Ventana Principal.
- Corregida concatenación nula en comprobaciones de Configuración.
- Resuelto el bug de "Doble Scroll" en la lista de instancias de Atlas.
