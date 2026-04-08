# doboard

> Gestión de tareas estilo Kanban · Local-first · Sin suscripciones

doboard es una app de productividad personal para Android e iOS construida con Flutter. Organiza tus tareas en cuatro tableros de tiempo estimado, te ayuda a enfocarte con el método Eat the Frog y un temporizador Pomodoro integrado, y detecta automáticamente el tipo de tarea mientras escribes.

---

## Características principales

### Tableros y organización
- **4 tableros fijos** organizados por tiempo estimado: Hoy 🐸, Rápidas ⚡ (< 10 min), Con calma 🧘 (30–60 min), Sin prisa 🌿 (> 1 hora)
- Navegación horizontal por deslizamiento entre tableros
- Reordenamiento libre de tareas dentro de cada tablero (drag & drop con handle ≡)
- Mover tareas entre tableros por arrastre prolongado

### Tareas
- Creación rápida desde la barra inferior/superior de cada tablero
- Prioridad en 3 niveles con indicador de color lateral
- Subtareas con checkbox, reordenamiento y contador de progreso
- **Promote**: convierte una subtarea en tarea de otro tablero manteniendo la referencia al padre
- Completar/archivar con swipe, menú contextual o checkbox
- Limpiar completadas por tablero con confirmación
- Duplicar tarea
- Detección automática de palabras clave → emoji (comprar 🛒, llamar 📞, reunión 👥, médico 🏥…)

### Programación y automatizaciones
- **Programar tarea**: se mueve automáticamente a "Hoy" en la fecha elegida
- **Notificación local** a las 9:00 AM del día programado (funciona con la app cerrada)
- Notificación de resumen al abrir la app si había tareas vencidas
- Procesamiento de tareas programadas al arrancar

### Eat the Frog 🐸
- Marca una tarea como "la rana" del día (la más importante)
- Se distingue visualmente con badge y fondo verde
- Solo puede haber una rana por tablero

### Modo enfoque
- Pantalla completa dedicada a una sola tarea
- Temporizador Pomodoro con 3 modos: 25 min / descanso 5 min / descanso largo 15 min
- Muestra hasta 3 subtareas pendientes para marcar sin salir del modo
- Haptic feedback en pausa y al completar

### Notas extensas
- Editor de texto enriquecido basado en **Quill** por tarea
- Formato: negrita, cursiva, subrayado, tachado, color de texto y fondo
- Listas con viñetas y numeradas
- Checkboxes interactivos dentro de la nota
- Deshacer/rehacer

### Ajustes
- Tema claro / oscuro / sistema
- Posición del input (arriba o abajo)
- Tamaño de fuente base
- Activar/desactivar Eat the Frog
- Activar/desactivar temporizador expreso en tarjetas
- Activar/desactivar automatizaciones de palabras clave
- Mostrar/ocultar tableros

---

## Stack técnico

| Capa | Tecnología |
|---|---|
| UI | Flutter 3.22+ |
| Estado | Riverpod 2 + flutter_hooks |
| Persistencia | Drift (SQLite) |
| Navegación | go_router |
| Editor de notas | flutter_quill |
| Notificaciones | flutter_local_notifications + timezone |
| Tema | flex_color_scheme + Google Fonts (DM Sans) |
| Animaciones | animate_do, flutter_slidable |

---

## Arquitectura

Clean Architecture en 3 capas con dependencia unidireccional:

```
Presentation  →  Domain  ←  Data
   (UI)        (Entities)  (DB/API)
```

- **Domain** — entidades puras Dart + interfaces de repositorio. Sin dependencias externas. Completamente testeable.
- **Data** — implementaciones Drift de los repositorios. Preparada para sustituirse por Firebase sin tocar Domain ni Presentation.
- **Presentation** — widgets, screens y providers Riverpod. Solo conoce Domain.

### Estructura de carpetas

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── services/
│   │   └── notification_service.dart
│   ├── utils/
│   │   └── automation_engine.dart
│   ├── router/
│   │   └── app_router.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── boards/
│   ├── tasks/
│   ├── notes/
│   └── settings/
└── shared/
    └── database/
        ├── app_database.dart
        ├── tables/
        └── daos/
```

---

## Base de datos

Schema SQLite gestionado con Drift. Versión actual: **v4**.

```
Boards ──< Tasks ──< Subtasks
              └──< Notes
```

| Tabla | Columnas clave |
|---|---|
| `boards` | id, name, subtitle, emoji, colorHex, position, isVisible |
| `tasks` | id, boardId, title, content, priority, position, isDone, isFrog, isPinned, detectedKeyword, parentTaskTitle, scheduledDate |
| `subtasks` | id, taskId, title, isDone, position, isPromoted |
| `notes` | id, taskId, contentJson, plainText |

---

## Primeros pasos

### Requisitos

- Flutter 3.22+
- Dart 3.3+
- Android SDK 21+ / iOS 13+

### Instalación

```bash
git clone https://github.com/tu-usuario/doboard.git
cd doboard
flutter pub get
flutter run
```

> No es necesario ejecutar `build_runner` para trabajar con el proyecto — los archivos `.g.dart` generados están incluidos en el repositorio.

### Si modificas modelos de base de datos

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Permisos Android

En `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

Los permisos de notificación se solicitan en el momento en que el usuario programa su primera tarea — nunca al arrancar la app.

---

## Roadmap

### Próximo

- [ ] Backup físico — exportar/importar la base de datos local
- [ ] Widget de pantalla de inicio (Android/iOS) con tareas de "Hoy"
- [ ] Navegación desde notificación directamente a la tarea

### Medio plazo

- [ ] Sincronización en la nube (Firebase)
- [ ] Onboarding interactivo para nuevos usuarios
- [ ] Estadísticas de productividad (tareas completadas por día/semana)

### Exploración

- [ ] Modo compartido / colaboración
- [ ] Integración con calendario del sistema
- [ ] Atajos de teclado para tablets con teclado físico

### Flujo de trabajo

```bash
git checkout -b feat/nombre-feature
# desarrollar
git add .
git commit -m "feat: descripción clara del cambio"
git push origin feat/nombre-feature
# abrir Pull Request
```

---

## Créditos

Construido con Flutter y las siguientes librerías open source: Riverpod, Drift, go_router, flutter_quill, flutter_local_notifications, flex_color_scheme, animate_do, flutter_slidable.

Metodología basada en **Eat the Frog** (Brian Tracy) y el método **Pomodoro** (Francesco Cirillo).
