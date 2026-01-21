# TurtleLoot

**La solución profesional de gestión de botín para Turtle WoW (Vanilla 1.12).**  
Soporte completo para GDKP, Soft Reserves (Reservas Blandas) y Maestro Despojador sin complicaciones.

## Características Principales

*   **Soft Reserves (SR)**: Sistema de gestión completo con un **Bot de Susurros** automatizado (`!res`).
*   **Subastas GDKP**: Subastas profesionales con temporizadores sincronizados en tiempo real y protección anti-snipe.
*   **Integración con Atlas**: Explora las tablas de botín dentro del addon y genera listas de SR al instante.
*   **Interfaz Moderna**: Un diseño oscuro y elegante que se siente actual pero funciona en el cliente de 2006.
*   **Plus Ones (+1)**: Sistema simple de seguimiento de asistencia.

---

## Guía de Inicio Rápido

### 1. Instalación
1.  Descarga la carpeta `TurtleLoot`.
2.  colócala en tu directorio `WoW/Interface/AddOns/`.
3.  (Opcional) Instala `Atlas-TW` para usar el navegador de mazmorras.
4.  Entra al juego.

### 2. La Ventana Principal
Escribe `/tl` para abrir el panel principal.
*   **Overview (Resumen)**: Estadísticas rápidas e historial de botín.
*   **Soft Res**: Gestión de reservas de jugadores.
*   **GDKP**: Gestión de subastas de oro.
*   **Atlas**: Explorador de tablas de botín.

---

## Ejemplos de Uso Detallados

### Escenario A: Organizar una Raid "Soft Res" (MS > OS + 2 SR)

*Objetivo: Permitir reservar 2 items. Si cae un item reservado, solo tiran dados los que reservaron. Si no, es Main Spec > Off Spec.*

1.  **Preparación**:
    *   Abre `/tl`, ve a **Configuración** > **Soft Reserves**.
    *   Pon **Max Reserves** en `2`.
    *   Activa **Enable Whisper Commands** (Comandos por susurro).
2.  **Durante el Trash**:
    *   Dile a tu raid: "¡Susurradme `!res [Link del Item]` para reservar!"
    *   Los jugadores te susurran. La pestaña **Soft Res** se llena automáticamente.
    *   Puedes hacer clic en **"Lock Reserves"** (Bloquear) cuando empiece la raid.
3.  **Despojo**:
    *   Matas a Magmadar. Cae [Mark of the Striker].
    *   **TurtleLoot** detecta que `CazadorUno` y `PicaroDos` lo reservaron.
    *   Aparece una ventana: *"2 Reservas encontradas. ¿Iniciar Dados?"*
    *   Haces clic en **Start Roll**. Solo esos dos jugadores son invitados a tirar dados.
    *   El ganador recibe el objeto.
4.  **¿Sin Reservas?**:
    *   Si caen [Generic Bracers] y nadie los reservó, simplemente haz clic en **"Start Roll (MS)"**.
    *   Todos pueden tirar por Main Spec.

### Escenario B: Organizar una Raid GDKP

*Objetivo: Subastar objetos por oro, rastrear el bote y repartirlo al final.*

1.  **Despojar un Jefe**:
    *   Despojas [Band of Accuria].
    *   Haz Alt+Clic en el objeto o abre la pestaña **GDKP**.
2.  **Iniciar Subasta**:
    *   Establece **Min Bid** (puja mínima, ej. 50g) y haz clic en **"Start Auction"**.
    *   Aparece una **Barra Visual** en la pantalla de todos mostrando el tiempo restante.
3.  **Pujas**:
    *   Los jugadores escriben sus pujas en el chat de banda: `50`, `100`, `150`.
    *   El addon rastrea al mayor postor automáticamente.
    *   Si entra una puja en los últimos 10 segundos, el tiempo se extiende (Anti-Snipe).
4.  **Pago**:
    *   Haz clic en **End Auction**. Se anuncia el ganador.
    *   El oro se suma al **Total Pot** (Bote Total).
    *   Al final de la raid, mira el **Pot Tracker** para ver cuánto oro le toca a cada uno.

---

## Funciones Avanzadas

### Integración con Atlas
¡No escribas listas de IDs a mano!
1.  Ve a la pestaña **Atlas** en `/tl`.
2.  Selecciona "Molten Core".
3.  Haz clic en **"Generate SR List"**.
4.  Esto crea una lista de todos los épicos de MC para que los jugadores puedan empezar a reservar de inmediato.

### Comandos del Bot de Susurros
Tus raiders pueden susurrarte estos comandos:
*   `!res [Link del Item]` : Confirmar una reserva.
*   `!myres` : Ver qué han reservado.
*   `!cancel` : Borrar sus reservas.
*   `!list` : Ver la lista de items permitidos.

---

## Solución de Problemas

*   **"¡No puedo marcar las casillas de opciones!"**: Arreglado en v2.0.0. Ahora el texto de la opción también es clicable.
*   **"Faltan mazmorras en Atlas"**: Haz clic en la pestaña "Atlas" y verifica que la Barra de Desplazamiento funciona. Ahora soporta listas de cualquier tamaño (70+ instancias).
*   **"La ventana está vacía"**: Prueba `/tl reset` para restaurar las posiciones por defecto.
