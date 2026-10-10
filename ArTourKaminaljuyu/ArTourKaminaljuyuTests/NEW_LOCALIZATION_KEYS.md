# Nuevas Claves de Localización Requeridas

Este archivo contiene todas las claves nuevas que necesitas agregar a tu sistema de localización (probablemente en `LocalizedStrings` o archivos `.strings`).

## Claves para ContentView.swift

### skip_intros
**Español (ES):**
```
"skip_intros": "Saltar intros"
```

**Inglés (EN):**
```
"skip_intros": "Skip intros"
```

---

## Claves para TourControlsView.swift

### ready_to_start
**Español (ES):**
```
"ready_to_start": "Listo para iniciar"
```

**Inglés (EN):**
```
"ready_to_start": "Ready to start"
```

### walk_to_start_point
**Español (ES):**
```
"walk_to_start_point": "Camina al punto de partida"
```

**Inglés (EN):**
```
"walk_to_start_point": "Walk to the starting point"
```

### tap_anywhere_to_start
**Español (ES):**
```
"tap_anywhere_to_start": "Toca cualquier lugar para arrancar el tour"
```

**Inglés (EN):**
```
"tap_anywhere_to_start": "Tap anywhere to start the tour"
```

### distance_to_start
**Español (ES):**
```
"distance_to_start": "Estás a %@m del punto de partida"
```

**Inglés (EN):**
```
"distance_to_start": "You are %@m from the starting point"
```

**Nota:** `%@` será reemplazado por la distancia en metros.

### waiting_for_gps
**Español (ES):**
```
"waiting_for_gps": "Esperando ubicación GPS…"
```

**Inglés (EN):**
```
"waiting_for_gps": "Waiting for GPS location…"
```

---

## Claves para MapOverlayView.swift

### distance_to_poi
**Español (ES):**
```
"distance_to_poi": "Estás a unos %@ metros de %@"
```

**Inglés (EN):**
```
"distance_to_poi": "You are about %@ meters from %@"
```

**Nota:** El primer `%@` es la distancia, el segundo es el nombre del POI.

### status_idle
**Español (ES):**
```
"status_idle": "Acércate a un montículo para ver el modelo AR"
```

**Inglés (EN):**
```
"status_idle": "Get close to a mound to see the AR model"
```

### status_navigating_to_start
**Español (ES):**
```
"status_navigating_to_start": "Camina hacia el inicio del recorrido"
```

**Inglés (EN):**
```
"status_navigating_to_start": "Walk towards the tour start"
```

### status_returning
**Español (ES):**
```
"status_returning": "🔙 Regresando al inicio..."
```

**Inglés (EN):**
```
"status_returning": "🔙 Returning to start..."
```

### status_completed
**Español (ES):**
```
"status_completed": "🏁 ¡Recorrido completado!"
```

**Inglés (EN):**
```
"status_completed": "🏁 Tour completed!"
```

---

## Resumen de Cambios

### Archivos de código modificados:
1. ✅ `ContentView.swift` - Extraído "Saltar intros" a `skip_intros`
2. ✅ `TourControlsView.swift` - Extraídos 5 textos a claves de localización
3. ✅ `MapOverlayView.swift` - Extraídos 5 textos a claves de localización

### Total de claves nuevas: 11

---

## Instrucciones de Implementación

Dependiendo de cómo esté estructurado tu sistema de localización:

### Si usas diccionarios en código Swift:
Agrega estas claves a tu archivo `LocalizedStrings.swift` (o similar) en los diccionarios correspondientes para ES y EN.

### Si usas archivos `.strings`:
Agrega estas claves a:
- `Localizable.strings` (ES)
- `en.lproj/Localizable.strings` (EN)

### Si usas el patrón que vi en tu código:
Asegúrate de que el método `languageService.string(_:arguments:)` soporte interpolación de strings con argumentos usando el formato `%@`.
