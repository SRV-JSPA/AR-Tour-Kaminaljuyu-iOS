# Pruebas de rendimiento

Pruebas de rendimiento con XCTest (`measure` y métricas `XCTClockMetric`, `XCTMemoryMetric`
y `XCTApplicationLaunchMetric`). Cada prueba se repite 5 veces.

| Archivo | Prueba | Métricas |
|---|---|---|
| `UITests/LaunchPerformanceTests.swift` | Arranque de la app | `XCTApplicationLaunchMetric` |
| `UnitTests/LanguagePerformanceTests.swift` | 100 cambios ES → EN → ES; 100 lecturas de las 52 claves en ES y en EN | `XCTClockMetric`, `XCTMemoryMetric` |
| `UnitTests/EventBusPerformanceTests.swift` | 10 000 avisos con 4 suscriptores | `XCTClockMetric`, `XCTMemoryMetric` |
| `UnitTests/TourStatePerformanceTests.swift` | 100 recorridos completos (inicio, todos los montículos de `POIRegistry`, fin), con `AppStateManager` real y con dobles de prueba | `XCTClockMetric`, `XCTMemoryMetric` |

## Agregar las pruebas al proyecto (Xcode)

Estos pasos solo agregan referencias en el proyecto; no modifican el código de la app.

### 1. Pruebas unitarias (casos 2 a 4)

Van en el target existente `ArTourKaminaljuyuTests`, porque ahí están los dobles de prueba
(`MockServices.swift`) y la configuración de CocoaPods.

1. Abrir `ArTourKaminaljuyu/ArTourKaminaljuyu.xcworkspace`.
2. *File → Add Files to "ArTourKaminaljuyu"…* y seleccionar la carpeta `PerformanceTests/UnitTests`.
3. En el diálogo:
   - **Copy items if needed:** desmarcado.
   - **Added folders:** Create groups.
   - **Add to targets:** marcar **solo** `ArTourKaminaljuyuTests` (desmarcar la app).

### 2. Prueba de arranque (caso 1)

`XCTApplicationLaunchMetric` requiere un target de pruebas de UI.

1. *File → New → Target… → iOS → UI Testing Bundle.*
2. **Product Name:** `ArTourKaminaljuyuPerformanceUITests`. **Target to be Tested:** `ArTourKaminaljuyu`.
3. Xcode crea dos archivos de plantilla dentro del target nuevo. Eliminarlos (*Delete → Move to Trash*)
   para que no se ejecuten pruebas vacías.
4. *File → Add Files to "ArTourKaminaljuyu"…*, seleccionar `PerformanceTests/UITests/LaunchPerformanceTests.swift`
   y marcar **solo** el target `ArTourKaminaljuyuPerformanceUITests`.

### 3. Revisar el esquema

*Product → Scheme → Edit Scheme… → Test*: verificar que aparezcan `ArTourKaminaljuyuTests` y
`ArTourKaminaljuyuPerformanceUITests`. Si falta el segundo, agregarlo con **+**.

## Correr las pruebas en el simulador

**Desde Xcode:** elegir el simulador (por ejemplo, iPhone 17) y ejecutar cada prueba con el
rombo junto a su nombre, o todas con **⌘U**. Los resultados quedan en el *Report navigator* (⌘9).

**Desde la Terminal**, en la carpeta `ArTourKaminaljuyu` (donde está el `.xcworkspace`):

```bash
xcodebuild test \
  -workspace ArTourKaminaljuyu.xcworkspace \
  -scheme ArTourKaminaljuyu \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ArTourKaminaljuyuTests/LanguagePerformanceTests \
  -only-testing:ArTourKaminaljuyuTests/EventBusPerformanceTests \
  -only-testing:ArTourKaminaljuyuTests/TourStatePerformanceTests \
  -only-testing:ArTourKaminaljuyuPerformanceUITests/LaunchPerformanceTests \
  2>&1 | grep -E "measured \[|Test Case .*(passed|failed)|error:|TEST SUCCEEDED|TEST FAILED"
```

Cada línea `measured [...]` muestra la métrica, el promedio, la desviación estándar relativa y
los 5 valores medidos.

## Consideraciones para interpretar los resultados

- Los resultados en el simulador dependen de la computadora; no equivalen a los de un iPhone físico.
- Las pruebas unitarias corren dentro de la app (host), así que la memoria medida incluye la app en ejecución.
- `LanguageService.setLanguage()` escribe en la consola en cada cambio; ese costo forma parte del tiempo medido.
