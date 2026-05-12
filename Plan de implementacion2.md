
# 📘 PLAN DE IMPLEMENTACIÓN: "URBA & FLOW" – TIENDA DIGITAL DE ROPA PARA HOMBRE
> **Alcance:** Desarrollo exclusivo para entornos de desarrollo/staging. Sin analíticas, sin Crashlytics, sin despliegue a producción. Multiplataforma (Android, iOS, Web, Windows). Roles: Admin y Usuario. Estado: Provider. Backend: Firebase (Auth + Firestore + Storage). UI: Paleta azul urbana/minimalista. Sin código en este documento.

---

## 🏗️ 1. Arquitectura y Estructura de Carpetas (Feature-First)
```
lib/
├── core/
│   ├── config/          # Entornos dev/staging, constantes, rutas base
│   ├── theme/           # ThemeData, paleta azul, tipografía, espaciado, formas
│   ├── utils/           # Validadores, formateadores, helpers de fecha/moneda
│   └── services/        # Firebase init, Storage service, Cloud Functions (si aplica)
├── features/
│   ├── auth/            # Login, registro, recuperación, RBAC claims
│   ├── catalog/         # Listado, filtros, detalle, categorías, búsqueda
│   ├── cart/            # Carrito local, sincronización, cálculo de totales
│   ├── checkout/        # Dirección, envío, cupón, resumen, confirmación
│   ├── admin/           # CRUD productos/variantes/categorías, inventario, pedidos, cupones, sucursales, proveedores
│   └── profile/         # Datos cliente, direcciones, historial de pedidos
├── shared/
│   ├── widgets/         # Botones, inputs, tarjetas, loaders, snackbars, diálogos
│   ├── models/          # Entidades Dart (inmutables, fromJson/toJson conceptual)
│   └── providers/       # AuthProvider, ProductProvider, CartProvider, OrderProvider, ThemeProvider
└── main.dart            # Punto de entrada, MultiProvider, MaterialApp.router, init
assets/
├── fonts/
├── images/              # Logos, placeholders, iconos
└── icons/
```

---

## 🔄 2. Mapeo Relacional → Firestore (NoSQL)
| Entidad SQL | Adaptación Firestore | Estrategia |
|-------------|----------------------|------------|
| `producto` | Colección `products` | Documento con campos base. `variants` como subcolección o array embebido según volumen. |
| `variante` | Subcolección `products/{id}/variants` o array dentro de producto | Cada variante incluye `talla`, `color`, `codigo_barras`, `precio_extra`, `activo`. |
| `categoria` | Colección `categories` | Jerarquía vía `parentId`. Índices por `orden` y `slug`. |
| `imagen` | Subcolección `products/{id}/images` o array `imageUrls` | Solo almacenar URLs de Firebase Storage + `orden` + `principal`. |
| `inventario` | Campo `stock` dentro de cada variante + colección `inventory_movements` | Evitar colección separada masiva; `stock` se actualiza atómicamente. |
| `movimiento_inventario` | Colección `inventory_movements` | Documentos con `variantId`, `branchId`, `tipo`, `cantidad`, `motivo`, `fecha`, `employeeId`. |
| `cliente` | Colección `users` (vinculada a UID de Auth) | Perfil embebido. Direcciones como subcolección `users/{uid}/addresses`. |
| `pedido` + `detalle_pedido` | Colección `orders` | `details` como array de mapas. Campos calculados (`subtotal`, `total`) se guardan en el documento. |
| `pago` + `envio` | Campos embebidos dentro de `orders` | `payment: { metodo, estado, referencia }`, `shipping: { paqueteria, estado, tracking }`. |
| `cupon` | Colección `coupons` | Validación de `usos_max`, `fecha_inicio/fin`, `minimo_compra`. |
| `pedido_cupon` | Campo `couponApplied: { id, descuento }` dentro de `orders` | No requiere colección separada. |
| `sucursal`, `empleado`, `proveedor` | Colecciones `branches`, `employees`, `suppliers` | `employees` vinculado a Auth con custom claims. `branches` y `suppliers` solo lectura/escritura admin. |

---

## 🔐 3. Autenticación y Control de Acceso (RBAC)
| Paso | Acción | Entregable |
|------|--------|------------|
| 3.1 | Registro/Login con email/password vía Firebase Auth | Flujo completo con validación |
| 3.2 | Asignación de Custom Claims (`admin: true/false`) desde backend o Cloud Functions simuladas | Claims persistentes y accesibles en cliente |
| 3.3 | Interceptor de rutas (`go_router`) que redirige según rol y estado de sesión | Navegación protegida |
| 3.4 | Reglas de Firestore: lectura pública para catálogo, escritura solo para `admin`, acceso a `users/{uid}` solo por el usuario o admin | `.rules` validadas en emulador |
| 3.5 | Persistencia de sesión y cierre seguro con limpieza de estado local | Estado coherente post-logout |

---

## 📊 4. Gestión de Estado con Provider
| Ámbito | Responsabilidad | Alcance |
|--------|-----------------|---------|
| `AuthProvider` | Login, registro, claims, perfil, logout | Raíz (`MultiProvider`) |
| `ProductProvider` | Listado, filtros, búsqueda, detalle, paginación | Raíz o feature `catalog` |
| `CartProvider` | Agregar, modificar, eliminar, cálculo de totales, persistencia local | Raíz (acceso global) |
| `CheckoutProvider` | Dirección, cupón, método de pago, validación, creación de pedido | Feature `checkout` |
| `AdminProvider` | CRUD productos/variantes/categorías, actualización de stock, gestión de pedidos | Feature `admin` |
| `ThemeStateProvider` | Cambio de tonalidades azules, modo claro/oscuro | Raíz |

> **Patrón de respuesta:** `ResultState<T>` con `idle`, `loading`, `success(data)`, `error(message)`. Todos los proveedores exponen listeners eficientes sin rebuilds innecesarios.

---

## 🎨 5. UI/UX: Tonalidades Azules y Adaptabilidad
| Elemento | Especificación |
|----------|----------------|
| Paleta primaria | `#0A2540` (fondo oscuro), `#1E3A8A` (primario), `#3B82F6` (acentos), `#60A5FA` (hover), `#93C5FD` (suave) |
| Tipografía | `Inter` o `Montserrat` (legibilidad urbana), pesos 400/500/600/700 |
| Espaciado | Base 8px, sistema de 4pt para consistencia multiplataforma |
| Componentes | Botones con radius 12, tarjetas con sombra sutil, inputs con borde azul en foco, loaders circulares |
| Responsividad | `LayoutBuilder` + `AdaptiveLayout` para móvil/tablet/desktop, grids flexibles para catálogo |
| Accesibilidad | Contraste WCAG AA, `Semantics`, tamaños de texto escalables, navegación por teclado en Web/Windows |

---

## 🛒 6. Flujos de Usuario por Rol
### 👤 Cliente/Usuario
1. Registro/Login → Validación → Redirección a Home
2. Navegación por categorías, búsqueda, filtros (talla, precio, color)
3. Detalle de producto: selector de variante, galería, agregar al carrito
4. Carrito: persistencia local + sincronización si autenticado
5. Checkout: selección de dirección, aplicación de cupón, resumen, confirmación (simulación de pago en dev)
6. Perfil: historial de pedidos, gestión de direcciones, edición de datos

### 👨‍💼 Administrador
1. Login con credenciales admin → Claims validados → Dashboard
2. CRUD Productos: nombre, slug, descripción, precio, precio oferta, estado, destacado
3. Gestión de Variantes: talla, color, código de barras, precio extra, stock
4. Inventario: entradas/salidas/ajustes, alertas de stock mínimo
5. Pedidos: cambio de estado, asignación de paquetería, tracking, cancelaciones
6. Cupones: creación, límites, fechas, visualización de usos
7. Sucursales/Proveedores: alta, edición, desactivación
8. Validación estricta en formularios, confirmaciones de acciones destructivas, feedback de éxito/error

---

## 📦 7. Dependencias (`pubspec.yaml` - Conceptual)
| Categoría | Paquetes |
|-----------|----------|
| Core | `flutter`, `flutter_lints` |
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` |
| Estado | `provider` |
| Enrutamiento | `go_router` |
| UI/Assets | `cached_network_image`, `flutter_svg`, `google_fonts`, `intl` |
| Utilidades | `shared_preferences`, `uuid`, `formz` o `auto_route` (validación), `equatable` |
| Dev/Testing | `mocktail`, `flutter_test`, `integration_test` |

> ✅ **Excluido explícitamente:** `firebase_analytics`, `firebase_crashlytics`, `firebase_remote_config`, herramientas de despliegue, CI/CD de producción.

---

## 🧪 8. Pruebas y Validación (Entorno Dev/Staging)
| Tipo | Alcance | Herramienta |
|------|---------|-------------|
| Unitarias | Modelos, lógica de cálculo, validadores, proveedores | `flutter test` |
| Widget | Componentes reutilizables, estados UI, formularios | `testWidgets` |
| Integración | Flujo Login → Catálogo → Carrito → Checkout (simulado) | `integration_test` |
| Reglas Firestore | Simulación de lecturas/escrituras por rol | Firebase Emulator Suite |
| Performance | Rebuilds innecesarios, carga de imágenes, listeners | Flutter DevTools (memory, frames) |

---

## 📅 9. Roadmap de Desarrollo (Dev/Staging)
| Semana | Foco | Entregable |
|--------|------|------------|
| 1 | Setup, estructura, tema azul, routing base | Proyecto inicial, `main.dart`, `core/`, `theme/` |
| 2 | Firebase Auth + RBAC + Providers base | Login, claims, `AuthProvider`, rutas protegidas |
| 3 | Firestore mapping + Catálogo + Filtros | `ProductProvider`, listado paginado, búsqueda |
| 4 | Carrito + Checkout simulado + Cupones | `CartProvider`, flujo de pago dev, validaciones |
| 5 | Panel Admin (CRUD productos/variantes/stock) | Formularios, tablas, alertas, reglas de seguridad |
| 6 | Pedidos + Direcciones + Perfil + Pruebas | Flujo completo, tests, emulador Firestore |
| 7 | Optimización, accesibilidad, responsive Web/Win | `AdaptiveLayout`, DevTools, validación cross-platform |
| 8 | Documentación, empaquetado dev, revisión final | README técnico, checklist, build de staging |

---

## ✅ Checklist de Validación Pre-Implementación
- [ ] Esquema Firestore alineado con requerimientos relacionales
- [ ] Custom claims definidos para `admin` vs `user`
- [ ] Reglas de seguridad probadas en emulador
- [ ] Providers con `ResultState` y listeners eficientes
- [ ] Rutas protegidas por `go_router` según rol
- [ ] Paleta azul aplicada a `ThemeData` y componentes
- [ ] Dependencias limpias (sin analíticas, sin prod)
- [ ] Estructura de carpetas lista para escalabilidad
- [ ] Plan de pruebas unitarias/widget definido
- [ ] Documentación de decisiones técnicas iniciada

---
Aquí tienes la sección técnica faltante, estructurada profesionalmente y lista para integrar en tu plan maestro. Se mantiene el enfoque **dev/staging**, sin analíticas, con mapeo explícito de tus tablas relacionales a colecciones/documentos Firestore, y con el bloque de dependencias listo para `pubspec.yaml`.

---

## 📊 1. Estructura de Colecciones Firestore (Mapeo Relacional → NoSQL)

> 🔹 **Nota de arquitectura:** Firestore es orientado a documentos. Las claves foráneas se modelan como `references` o `strings` con ruta de colección. Las relaciones 1:N se gestionan mediante **subcolecciones** o **arrays embebidos** según el volumen de lecturas. Se prioriza la inmutabilidad de datos históricos y la validación en reglas de seguridad.

| Colección / Subcolección | Campo | Tipo Firestore | Restricciones / Default | Mapeo Relacional |
|--------------------------|-------|----------------|--------------------------|------------------|
| **`products`** | `id` | `string` | PK auto-generado | `producto.id_producto` |
| | `name` | `string` | `max: 150`, `required` | `producto.nombre` |
| | `slug` | `string` | `unique`, `required` | `producto.slug` |
| | `description` | `string` | `nullable` | `producto.descripcion` |
| | `price` | `number` | `required`, `2 decimales` | `producto.precio` |
| | `salePrice` | `number` | `nullable` | `producto.precio_oferta` |
| | `isActive` | `boolean` | `default: true` | `producto.activo` |
| | `isFeatured` | `boolean` | `default: false` | `producto.destacado` |
| | `categoryIds` | `array<string>` | `nullable` | `producto_categoria` (relación N:N) |
| | `createdAt` | `timestamp` | `auto` | `producto.created_at` |
| **`products/{id}/variants`** | `id` | `string` | PK auto | `variante.id_variante` |
| | `size` | `string` | `XS,S,M,L,XL...` | `variante.talla` |
| | `color` | `string` | `nullable` | `variante.color` |
| | `barcode` | `string` | `unique` | `variante.codigo_barras` |
| | `extraPrice` | `number` | `default: 0.00` | `variante.precio_extra` |
| | `isActive` | `boolean` | `default: true` | `variante.activo` |
| | `stock` | `number` | `default: 0` | `inventario.stock` (embebido) |
| | `minStock` | `number` | `default: 5` | `inventario.stock_minimo` |
| **`categories`** | `id` | `string` | PK auto | `categoria.id_categoria` |
| | `parentId` | `string` | `nullable` (FK self) | `categoria.id_padre` |
| | `name` | `string` | `max: 100`, `required` | `categoria.nombre` |
| | `slug` | `string` | `unique`, `max: 110` | `categoria.slug` |
| | `imageUrl` | `string` | `nullable` | `categoria.imagen_url` |
| | `order` | `number` | `default: 0` | `categoria.orden` |
| **`images`** *(subcol: `products/{id}/images`)* | `id` | `string` | PK auto | `imagen.id_imagen` |
| | `url` | `string` | `required` (Storage) | `imagen.url` |
| | `alt` | `string` | `nullable`, `max: 150` | `imagen.alt` |
| | `order` | `number` | `default: 0` | `imagen.orden` |
| | `isPrincipal` | `boolean` | `default: false` | `imagen.principal` |
| **`inventory_movements`** | `id` | `string` | PK auto | `movimiento_inventario.id_movimiento` |
| | `variantId` | `reference` | `required` → `variants` | FK → variante |
| | `branchId` | `reference` | `required` → `branches` | FK → sucursal |
| | `type` | `string` | `enum: entrada,salida,ajuste` | `movimiento.tipo` |
| | `quantity` | `number` | `required`, `≥1` | `movimiento.cantidad` |
| | `reason` | `string` | `nullable`, `max: 200` | `movimiento.motivo` |
| | `employeeId` | `reference` | `nullable` → `employees` | FK → empleado |
| | `date` | `timestamp` | `auto` | `movimiento.fecha` |
| **`users`** *(vinculado a Firebase Auth UID)* | `id` | `string` | PK = Auth UID | `cliente` (perfil) |
| | `firstName` | `string` | `max: 80`, `required` | `cliente.nombre` |
| | `lastName` | `string` | `max: 80`, `required` | `cliente.apellido` |
| | `email` | `string` | `unique`, `required` | `cliente.email` |
| | `phone` | `string` | `nullable`, `max: 20` | `cliente.telefono` |
| | `birthDate` | `timestamp` | `nullable` | `cliente.fecha_nacimiento` |
| | `gender` | `string` | `enum: M,F,otro,null` | `cliente.genero` |
| | `isActive` | `boolean` | `default: true` | `cliente.activo` |
| | `createdAt` | `timestamp` | `auto` | `cliente.created_at` |
| **`users/{uid}/addresses`** | `id` | `string` | PK auto | `direccion.id_direccion` |
| | `alias` | `string` | `max: 50` | `direccion.alias` |
| | `street` | `string` | `required`, `max: 200` | `direccion.calle` |
| | `neighborhood` | `string` | `nullable`, `max: 100` | `direccion.colonia` |
| | `city` | `string` | `required`, `max: 100` | `direccion.ciudad` |
| | `state` | `string` | `required`, `max: 80` | `direccion.estado` |
| | `postalCode` | `string` | `required`, `max: 10` | `direccion.codigo_postal` |
| | `country` | `string` | `default: MX`, `max: 2` | `direccion.pais` |
| | `isDefault` | `boolean` | `default: false` | `direccion.predeterminada` |
| **`orders`** | `id` | `string` | PK auto | `pedido.id_pedido` |
| | `clientId` | `reference` | `required` → `users` | FK → cliente |
| | `branchId` | `reference` | `required` → `branches` | FK → sucursal |
| | `status` | `string` | `enum: pendiente,pagado,enviado,entregado,cancelado` | `pedido.estado` |
| | `channel` | `string` | `enum: online,mostrador` | `pedido.canal` |
| | `subtotal` | `number` | `required`, `2 dec` | `pedido.subtotal` |
| | `discount` | `number` | `default: 0.00` | `pedido.descuento` |
| | `tax` | `number` | `default: 0.00` (IVA 16%) | `pedido.impuesto` |
| | `total` | `number` | `required` | `pedido.total` |
| | `notes` | `string` | `nullable` | `pedido.notas` |
| | `createdAt` | `timestamp` | `auto` | `pedido.fecha` |
| **`orders/{id}/details`** *(array embebido o subcol)* | `id` | `string` | PK auto | `detalle_pedido.id_detalle` |
| | `variantId` | `reference` | `required` | FK → variante |
| | `quantity` | `number` | `required`, `≥1` | `detalle.cantidad` |
| | `unitPrice` | `number` | `required` | `detalle.precio_unitario` |
| | `lineDiscount` | `number` | `default: 0.00` | `detalle.descuento_linea` |
| | `lineSubtotal` | `number` | `calculated` | `detalle.subtotal_linea` |
| **`orders`** *(campos embebidos)* | `payment` | `map` | `{method, amount, status, reference, date}` | `pago` |
| | `shipping` | `map` | `{addressId, carrier, tracking, status, cost, estDate, deliveryDate}` | `envio` |
| | `couponApplied` | `map` | `{id, appliedDiscount}` | `pedido_cupon` |
| **`coupons`** | `id` | `string` | PK auto | `cupon.id_cupon` |
| | `code` | `string` | `unique`, `max: 30`, `required` | `cupon.codigo` |
| | `type` | `string` | `enum: porcentaje,monto,envio_gratis` | `cupon.tipo` |
| | `value` | `number` | `2 decimales` | `cupon.valor` |
| | `minPurchase` | `number` | `default: 0.00` | `cupon.minimo_compra` |
| | `maxUses` | `number` | `nullable = ilimitado` | `cupon.usos_max` |
| | `currentUses` | `number` | `default: 0` | `cupon.usos_actuales` |
| | `startDate` | `timestamp` | `nullable` | `cupon.fecha_inicio` |
| | `endDate` | `timestamp` | `nullable` | `cupon.fecha_fin` |
| | `isActive` | `boolean` | `default: true` | `cupon.activo` |
| **`branches`** | `id` | `string` | PK auto | `sucursal.id_sucursal` |
| | `name` | `string` | `max: 100`, `required` | `sucursal.nombre` |
| | `address` | `string` | `required` | `sucursal.direccion` |
| | `city` | `string` | `required` | `sucursal.ciudad` |
| | `phone` | `string` | `nullable` | `sucursal.telefono` |
| | `email` | `string` | `nullable` | `sucursal.email` |
| | `schedule` | `string` | `nullable` | `sucursal.horario` |
| | `isActive` | `boolean` | `default: true` | `sucursal.activa` |
| **`employees`** | `id` | `string` | PK = Auth UID | `empleado.id_empleado` |
| | `branchId` | `reference` | `required` | FK → sucursal |
| | `firstName`, `lastName` | `string` | `required` | `empleado.nombre/apellido` |
| | `email` | `string` | `unique` | `empleado.email` |
| | `role` | `string` | `enum: admin,gerente,vendedor,almacen` | `empleado.rol` |
| | `isActive` | `boolean` | `default: true` | `empleado.activo` |
| | `hireDate` | `timestamp` | `required` | `empleado.fecha_ingreso` |
| **`suppliers`** | `id` | `string` | PK auto | `proveedor.id_proveedor` |
| | `name` | `string` | `max: 150`, `required` | `proveedor.nombre` |
| | `rfc` | `string` | `unique`, `max: 15`, `nullable` | `proveedor.rfc` |
| | `contact` | `string` | `max: 120`, `nullable` | `proveedor.contacto` |
| | `email`, `phone` | `string` | `nullable` | `proveedor.email/telefono` |
| | `paymentTerms` | `string` | `max: 100`, `nullable` | `proveedor.condiciones_pago` |
| | `isActive` | `boolean` | `default: true` | `proveedor.activo` |

---

## 📦 2. Dependencias `pubspec.yaml` (Listado Conciso)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 🔥 Firebase Core + Servicios
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.2

  # 🔄 Estado & Enrutamiento
  provider: ^6.1.2
  go_router: ^14.2.7

  # 🎨 UI & Assets
  cached_network_image: ^3.4.1
  flutter_svg: ^2.0.10
  google_fonts: ^6.2.1
  intl: ^0.19.0

  # 🛠️ Utilidades & Persistencia Local
  shared_preferences: ^2.3.2
  uuid: ^4.5.0
  formz: ^0.7.0
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mocktail: ^1.0.4
```

> ✅ **Notas técnicas:**
> - Todas las versiones son estables y compatibles con Flutter `3.22+` / `3.24+` (2024-2026).
> - Se excluyeron explícitamente: `firebase_analytics`, `firebase_crashlytics`, `firebase_remote_config`, y cualquier paquete de despliegue o monitoreo de producción.
> - `formz` y `equatable` facilitan validación de formularios y comparación de modelos sin boilerplate.
> - `go_router` maneja rutas declarativas, parámetros, y protección por `redirect` basada en `AuthProvider`.

---

## 📌 Siguientes Pasos Recomendados
1. **Validación de estructura:** Confirma si prefieres `variants` como **subcolección** o **array embebido** (recomiendo array para <20 variantes/producto; subcolección si planeas escalabilidad masiva).
2. **Reglas de seguridad:** Puedo generar el bloque `.rules` de Firestore alineado a roles `admin`/`user` y validaciones de tipo.
3. **Flujo de Providers:** Esquema de `ChangeNotifier` con `ResultState<T>` y listeners optimizados por feature.
4. **Emuladores:** Configuración de `firebase emulators:start` para Auth + Firestore + Storage en dev/staging.

¿Deseas que proceda con las **reglas de seguridad por rol**, la **configuración de emuladores**, o la **estructura de los Providers** antes de pasar a la generación técnica?

# 🎨 Guía de Diseño Visual: "Urba & Flow" – Sistema de Diseño UI/UX

> **Concepto:** Tienda digital de ropa para hombre con estética urbana, minimalista y moderna.  
> **Paleta base:** Tonalidades azules profesionales (confianza, elegancia, masculinidad).  
> **Plataforma:** Flutter multiplataforma (Android, iOS, Web, Windows).  
> **Enfoque:** Accesibilidad WCAG AA, consistencia visual, adaptabilidad responsive.

---

## 🎨 1. Paleta de Colores (Sistema de Diseño Azul)

### 🔵 Colores Primarios (Marca)
| Nombre | Hex | Uso Principal | Contraste sobre blanco |
|--------|-----|---------------|------------------------|
| `primaryDark` | `#0A2540` | Header, footer, textos importantes | ✅ AAA |
| `primary` | `#1E3A8A` | Botones principales, activos, enlaces | ✅ AA |
| `primaryLight` | `#3B82F6` | Hover, acentos secundarios, iconos | ✅ AA |
| `primarySoft` | `#60A5FA` | Fondos suaves, estados focus | ✅ AA |
| `primaryPale` | `#93C5FD` | Bordes, separadores, placeholders | ✅ AA |

### ⚪ Colores Neutros (Base UI)
| Nombre | Hex | Uso |
|--------|-----|-----|
| `background` | `#FFFFFF` | Fondos de pantallas, tarjetas |
| `surface` | `#F8FAFC` | Fondos secundarios, secciones |
| `border` | `#E2E8F0` | Bordes de inputs, divisores |
| `textPrimary` | `#0F172A` | Títulos, texto principal |
| `textSecondary` | `#475569` | Subtítulos, descripciones |
| `textDisabled` | `#94A3B8` | Texto deshabilitado, placeholders |

### 🟢 Colores de Estado (Feedback)
| Estado | Hex | Uso |
|--------|-----|-----|
| `success` | `#10B981` | Confirmaciones, stock disponible |
| `warning` | `#F59E0B` | Stock bajo, alertas suaves |
| `error` | `#EF4444` | Errores, agotado, acciones destructivas |
| `info` | `#3B82F6` | Notificaciones informativas |

### 🌙 Modo Oscuro (Opcional - Escalable)
| Elemento | Hex Claro | Hex Oscuro |
|----------|-----------|------------|
| Background | `#FFFFFF` | `#0F172A` |
| Surface | `#F8FAFC` | `#1E293B` |
| Text Primary | `#0F172A` | `#F1F5F9` |
| Text Secondary | `#475569` | `#94A3B8` |
| Border | `#E2E8F0` | `#334155` |

---

## 🔤 2. Tipografía (Google Fonts)

### Fuentes Principales
| Uso | Fuente | Peso | Tamaño Base | Line Height |
|-----|--------|------|-------------|-------------|
| Títulos H1 | `Montserrat` | 700 (Bold) | 32px / 2rem | 1.2 |
| Títulos H2 | `Montserrat` | 600 (SemiBold) | 24px / 1.5rem | 1.3 |
| Títulos H3 | `Montserrat` | 600 (SemiBold) | 20px / 1.25rem | 1.4 |
| Cuerpo | `Inter` | 400 (Regular) | 16px / 1rem | 1.5 |
| Botones | `Inter` | 500 (Medium) | 14px / 0.875rem | 1.4 |
| Caption | `Inter` | 400 (Regular) | 12px / 0.75rem | 1.4 |
| Precio/Oferta | `Inter` | 600 (SemiBold) | 18px / 1.125rem | 1.3 |

### Escala Responsiva (Mobile → Desktop)
```dart
// Ejemplo conceptual de escala
H1: 24px (mobile) → 28px (tablet) → 32px (desktop)
H2: 20px → 22px → 24px
Body: 14px → 16px → 16px
Button: 14px (fixed)
```

---

## 🧱 3. Sistema de Espaciado y Layout

### Grid Base (8pt System)
| Token | Valor | Uso |
|-------|-------|-----|
| `space-1` | 4px | Micro-espaciado, iconos pequeños |
| `space-2` | 8px | Padding interno de componentes |
| `space-3` | 12px | Espaciado entre elementos relacionados |
| `space-4` | 16px | Padding estándar de contenedores |
| `space-5` | 24px | Separación de secciones |
| `space-6` | 32px | Márgenes entre bloques principales |
| `space-7` | 40px | Espaciado hero, secciones destacadas |
| `space-8` | 48px | Márgenes grandes en desktop |

### Layout Responsive
| Breakpoint | Ancho | Columnas | Gutter | Margen lateral |
|------------|-------|----------|--------|----------------|
| Mobile | < 600px | 4 | 16px | 16px |
| Tablet | 600–1024px | 8 | 24px | 24px |
| Desktop | ≥ 1024px | 12 | 32px | 48px |

---

## 🧩 4. Componentes UI Específicos

### 🔘 Botones
| Variante | Fondo | Texto | Borde | Radius | Sombra | Estados |
|----------|-------|-------|-------|--------|--------|---------|
| Primary | `#1E3A8A` | `#FFFFFF` | none | 12px | sutil (2dp) | hover: `#3B82F6`, pressed: `#1E3A8A` + sombra interna |
| Secondary | `transparent` | `#1E3A8A` | `#1E3A8A` 2px | 12px | none | hover: fondo `#EFF6FF` |
| Outline | `transparent` | `#475569` | `#E2E8F0` 1px | 12px | none | hover: borde `#3B82F6` |
| Disabled | `#E2E8F0` | `#94A3B8` | none | 12px | none | no interacción |

### 🛍️ Tarjeta de Producto (Product Card)
```
┌─────────────────────────┐
│ [Imagen producto]       │ ← Ratio 4:5, border-radius: 16px
│                         │
│ [Badge: "Nuevo"/"Oferta"] ← Posición absoluta, esquina superior
│                         │
│ ─────────────────────   │ ← Separador sutil
│ Nombre del producto     │ ← Inter 14px, SemiBold, 2 líneas máx
│                         │
│ Precio: $XXX.XX         │ ← Inter 16px, Bold, color primary
│ [Precio tachado]        │ ← Inter 14px, textSecondary, line-through
│                         │
│ [Selector de talla]     │ ← Chips horizontales (S, M, L, XL)
│                         │
│ [⭐⭐⭐⭐☆ (4.2)]        │ ← Rating pequeño, textSecondary
│                         │
│ [➕ Agregar]            │ ← Botón outline, ancho completo
└─────────────────────────┘
```

### 🧾 Inputs y Formularios
| Elemento | Estilo Base | Estado Focus | Estado Error | Estado Disabled |
|----------|-------------|--------------|--------------|-----------------|
| TextField | Borde `#E2E8F0`, radius 8px, padding 12px | Borde `#3B82F6` 2px, sombra suave | Borde `#EF4444`, icono error | Fondo `#F8FAFC`, texto `#94A3B8` |
| Label | `Inter 14px`, `#475569` | Color `#1E3A8A` | Color `#EF4444` | Color `#94A3B8` |
| Helper Text | `Inter 12px`, `#64748B` | — | Color `#EF4444` | — |
| Checkbox/Radio | Borde `#E2E8F0`, check `#1E3A8A` | Borde `#3B82F6` | Borde `#EF4444` | Opacidad 50% |

### 🗂️ Filtros y Chips
- **Chips de talla:** `Inter 13px`, padding `8px 16px`, border-radius `20px`, borde `#E2E8F0`
- **Estado seleccionado:** Fondo `#EFF6FF`, texto `#1E3A8A`, borde `#3B82F6`
- **Filtros activos:** Badge con contador, color `primarySoft`

### 🛒 Carrito y Badges
- **Badge de cantidad:** Círculo `16px`, fondo `#EF4444`, texto blanco `10px Bold`, posición absoluta esquina superior derecha
- **Resumen de carrito:** Tarjeta fija en mobile (bottom sheet), sticky en desktop

---

## 🖼️ 5. Guías para Imágenes y Assets

### Fotografía de Producto
| Especificación | Valor |
|----------------|-------|
| Ratio | 4:5 (vertical) o 1:1 (cuadrado) |
| Resolución mínima | 800x1000px |
| Formato recomendado | WebP (con fallback JPG) |
| Fondo | Blanco puro `#FFFFFF` o gris muy claro `#F8FAFC` |
| Iluminación | Uniforme, sin sombras duras |
| Ángulos | Frontal, lateral, detalle de textura, modelo (opcional) |

### Iconografía
- **Estilo:** Lineal minimalista, grosor de trazo 1.5–2px
- **Tamaño base:** 20px para UI, 24px para acciones principales
- **Color por defecto:** `#475569`, activo: `#1E3A8A`
- **Biblioteca recomendada:** `flutter_svg` + icons personalizados o `lucide_icons`

### Ilustraciones y Banners
- **Estilo:** Vectorial moderno, trazos limpios, acentos en azul
- **Uso:** Onboarding, estados vacíos (carrito, historial), promociones
- **Formato:** SVG para escalabilidad, máximo 50KB

---

## ♿ 6. Accesibilidad y Experiencia de Usuario

### Contraste y Legibilidad
- ✅ Todos los textos sobre fondos cumplen WCAG AA (mínimo 4.5:1)
- ✅ Tamaños de texto escalables con `MediaQuery.textScaler`
- ✅ Iconos con `Semantics` para lectores de pantalla

### Feedback Visual y Táctil
| Acción | Feedback |
|--------|----------|
| Tap en botón | Escala 0.98 + sombra reducida + ripple azul suave |
| Carga de datos | Skeleton screens (shimmer) en lugar de spinners genéricos |
| Éxito en acción | Snackbar verde con icono check, auto-dismiss 3s |
| Error | Banner rojo persistente con botón "Reintentar" |
| Sin conexión | Banner informativo en topo + modo offline limitado |

### Navegación y Jerarquía
- **Mobile:** BottomNavigationBar (5 ítems máx), drawer para menú secundario
- **Desktop:** NavigationRail lateral o AppBar con menú horizontal
- **Breadcrumbs:** En desktop para catálogo y perfil (ej: `Home > Hombre > Camisas > Slim Fit`)

---

## 📱 7. Adaptabilidad Multiplataforma

| Plataforma | Ajustes Específicos |
|------------|---------------------|
| **Android** | Respetar gestos de retroceso, soporte para back button, Material 3 tokens |
| **iOS** | SafeArea para notch, gestos de swipe, tipografía San Francisco como fallback |
| **Web** | Hover states visibles, URLs amigables con `go_router`, soporte para teclado |
| **Windows** | Soporte para foco con teclado, redimensionamiento fluido, menús contextuales |

---

## 🧪 8. Estados de UI por Componente (Ejemplo: Product Card)

```
[Estado: Idle]
→ Imagen cargada, precio visible, botón "Agregar" habilitado

[Estado: Loading]
→ Skeleton: rectángulo gris animado (shimmer) en imagen, líneas de texto grises

[Estado: Success]
→ Producto agregado: botón cambia a "✓ Agregado", badge del carrito incrementa

[Estado: Error]
→ Imagen fallback (icono de ropa), mensaje "No disponible", botón deshabilitado

[Estado: Out of Stock]
→ Imagen con overlay gris 30%, texto "Agotado" en diagonal, botón "Notificarme"
```

---

## 🎯 9. Checklist de Implementación Visual en Flutter

- [ ] `ThemeData` configurado con paleta azul completa (colores primarios, neutros, estado)
- [ ] `TextTheme` con `Montserrat` (títulos) e `Inter` (cuerpo) vía `google_fonts`
- [ ] Sistema de espaciado con constantes (`AppSpacing.space4`, etc.)
- [ ] Componentes reutilizables: `PrimaryButton`, `ProductCard`, `AppTextField`, `FilterChip`
- [ ] Skeletons personalizados para catálogo y perfil
- [ ] Soporte para modo oscuro preparado (aunque no se active inicialmente)
- [ ] Assets optimizados: imágenes WebP, iconos SVG, fuentes subseteadas
- [ ] Pruebas de contraste con herramientas como `flutter contrast_checker`
- [ ] Documentación de componentes en `README.md` o Storybook interno

---

## 🖼️ Visualización Rápida (Mockup Conceptual)

```
┌─────────────────────────────────────┐
│  [LOGO]  Urba & Flow    [🔍] [🛒2] │ ← AppBar primaryDark
├─────────────────────────────────────┤
│  [Banner Hero: "Nueva Colección"]   │ ← Imagen full-width, overlay azul 40%
│  "Estilo urbano para el hombre moderno" │
│  [Explorar →]                       │
├─────────────────────────────────────┤
│  Categorías                         │
│  [👕 Camisas] [👖 Pantalones] [...] │ ← Chips horizontales scrollables
├─────────────────────────────────────┤
│  Destacados                         │
│  ┌─────┐ ┌─────┐ ┌─────┐           │
│  │ img │ │ img │ │ img │           │ ← Grid 2 col mobile, 4 desktop
│  │Camisa│ │Pant.│ │Chamarra│        │
│  │$899 │ │$1,299│ │$2,499 │         │
│  │[➕] │ │[➕] │ │[➕]  │           │
│  └─────┘ └─────┘ └─────┘           │
└─────────────────────────────────────┘
```

---
