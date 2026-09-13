# Tests - ArTourKaminaljuyu

## Estructura de Tests

Este proyecto utiliza **Swift Testing** (no XCTest) para validar la arquitectura modular.

### 📁 Archivos de Tests

#### **Tests con Mocks** (Recomendado - Sin Race Conditions)
- `MockServices.swift` - Mocks de todos los servicios principales
- `TourIntegrationTests.swift` - Tests E2E con mocks (10 tests)
- `ArchitectureIntegrationTests.swift` - Tests arquitectónicos con mocks (9 tests)

#### **Tests Unitarios con Singletons** (Con delays para evitar race conditions)
- `LanguageServiceTests.swift` - Tests de LanguageService (8 tests)
- `LocalizedStringsTests.swift` - Tests de LocalizedStrings (5 tests)
- `EventBusTests.swift` - Tests de EventBus (3 tests)

### ✅ Total: 35 Tests

## Estrategia de Testing

### 1. **Tests con Mocks** (Preferred)
Los tests que usan `AppContainer.mock()` son **completamente aislados** y no tienen race conditions:

```swift
let container = AppContainer.mock()
container.appState.startTour()
#expect(container.appState.startTourCalled == true)
```

**Ventajas:**
- ✅ Sin race conditions
- ✅ Ejecución en paralelo segura
- ✅ Verificación de interacciones
- ✅ Best practice profesional

### 2. **Tests con Singletons** (Legacy)
Algunos tests todavía usan singletons compartidos (`.shared`). Estos tienen delays para minimizar race conditions:

```swift
LanguageService.shared.setLanguage("ES")
try await Task.sleep(for: .milliseconds(100)) // Delay
#expect(LanguageService.shared.currentLanguage == "ES")
```

**Limitaciones:**
- ⚠️ Pueden fallar ocasionalmente por timing
- ⚠️ Más lentos (por los delays)
- ⚠️ No aislados

## Ejecutar Tests

```bash
# En Xcode
Cmd + U

# O específicamente
xcodebuild test -scheme ArTourKaminaljuyu -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Cobertura de Tests

### Módulos Testeados
- ✅ **LanguageModule** - Cambio de idioma, rutas de video, localización
- ✅ **AppStateManager** - Estados del tour (idle, inTour, completed)
- ✅ **EventBus** - Propagación de eventos entre módulos
- ✅ **AppRouter** - Navegación entre rutas
- ✅ **Integración E2E** - Flujos completos de usuario

### Escenarios Cubiertos
- ✅ Usuario completa tour exitosamente
- ✅ Usuario cambia idioma antes del tour
- ✅ Usuario cancela tour a mitad de camino
- ✅ Múltiples suscriptores a eventos
- ✅ Reset y restauración de estado
- ✅ Validación de arquitectura modular

## Para Protocolo de Graduación

### Contribución de Tesis
Estos tests validan la **arquitectura modular desacoplada** que es la contribución principal:

1. **Comunicación por interfaces** - Los mocks prueban que módulos se comunican solo por interfaces públicas
2. **EventBus para coordinación** - Tests verifican propagación de eventos entre módulos
3. **Estado global centralizado** - AppStateManager como single source of truth
4. **Aislamiento de módulos** - Mocks demuestran que módulos son intercambiables

### Métricas
- **35 tests** en total
- **19 tests con mocks** (aislados, sin race conditions)
- **16 tests unitarios** (con delays para serialización)
- **100% de los módulos core** tienen cobertura

## Notas Técnicas

### Problema de Race Conditions
Swift Testing ejecuta tests en paralelo por defecto. Tests que usan singletons compartidos (`LanguageService.shared`, `EventBus.shared`) pueden interferir entre sí.

**Solución aplicada:**
1. Tests con mocks (preferred) - Completamente aislados
2. Tests con singletons - Delays de 50-150ms entre operaciones
3. Suite serialization (`.serialized`) - Solo dentro de cada suite

### Limitación Conocida
No es posible forzar serialización **entre** diferentes suites en Swift Testing. Por eso la estrategia de mocks es superior.

---

**Última actualización:** Septiembre 2026  
**Autor:** Alejandra Salvatierra (Mónica)
