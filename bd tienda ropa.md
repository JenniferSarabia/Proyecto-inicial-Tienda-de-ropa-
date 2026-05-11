actua como un administrador de base de datos: proyecto tienda de ropa (Urba & Flow), que entidades se necesitan para su gestion

<img width="739" height="259" alt="image" src="https://github.com/user-attachments/assets/2be604e3-48e2-4bdb-adc2-2c004b4c0171" />
Como administrador de base de datos para **Urba & Flow**, aquí están las entidades esenciales organizadas por módulo funcional:Aquí tienes el resumen por módulo:

**Catálogo** — el núcleo del negocio. `Producto` define lo que se vende; `Variante (SKU)` gestiona combinaciones de talla y color; `Categoría` soporta árbol jerárquico (ropa mujer → blusas → manga larga); `Imagen` y la pivote `Producto_Categoría` completan el modelo.

**Inventario** — separado del catálogo intencionalmente. `Inventario` lleva el stock por variante y sucursal; `Movimiento_Inventario` guarda el historial auditado de cada entrada, salida o ajuste.

**Clientes** — `Cliente` más `Dirección` (relación uno a muchos, con flag de predeterminada para el checkout ágil).

**Ventas** — el módulo más crítico. `Pedido` registra la cabecera y el canal (online / mostrador); `Detalle_Pedido` el carrito línea por línea; `Pago` admite pagos múltiples por pedido (efectivo + tarjeta, por ejemplo); `Envío` gestiona el rastreo logístico.

**Promociones** — `Cupón` con tipos (porcentaje, monto fijo, envío gratis) y `Pedido_Cupón` registra cuánto se aplicó realmente.

**Operaciones** — `Sucursal`, `Empleado` y `Proveedor` dan soporte al inventario físico, control de accesos y compras.

Haz clic en cualquier entidad para explorar sus atributos con más detalle. ¿Quieres que genere el ERD completo con las relaciones, o profundizamos en algún módulo específico como el de ventas o inventario?

las entidades con sus atributos y tipo en forma de tablan para cada una de las entidades

## Tablas
<img width="714" height="315" alt="image" src="https://github.com/user-attachments/assets/c22d18a6-5765-45c4-8c68-936558e199e4" />
<img width="779" height="228" alt="image" src="https://github.com/user-attachments/assets/dcfd8119-0982-42cd-90bd-c834cc33ae8f" />
<img width="324" height="140" alt="image" src="https://github.com/user-attachments/assets/a6a7f74d-7026-49b1-98b3-504b25028dbc" />
<img width="808" height="305" alt="image" src="https://github.com/user-attachments/assets/b26b2e14-1b35-4d85-92db-297b118bb4d8" />
<img width="764" height="388" alt="image" src="https://github.com/user-attachments/assets/3f8fd15e-ebbd-4f01-9d02-7b7138b58eca" />
<img width="781" height="392" alt="image" src="https://github.com/user-attachments/assets/4b412292-5705-4b01-8b0f-9397214172a2" />
<img width="793" height="322" alt="image" src="https://github.com/user-attachments/assets/90c3dbb0-86a5-403c-9393-0bb47219b24e" />
<img width="791" height="698" alt="image" src="https://github.com/user-attachments/assets/24e3b122-0729-4756-8f52-18017bc049f3" />

de acuerdo a tu respuesta anterior puedes generar un script en sql para descargar con el nombre de bdropadetienda.sql pra las 10 entidades con sus relaciones

**Catálogo** — el núcleo del negocio. `Producto` define lo que se vende; `Variante (SKU)` gestiona combinaciones de talla y color; `Categoría` soporta árbol jerárquico (ropa mujer → blusas → manga larga); `Imagen` y la pivote `Producto_Categoría` completan el modelo.

**Inventario** — separado del catálogo intencionalmente. `Inventario` lleva el stock por variante y sucursal; `Movimiento_Inventario` guarda el historial auditado de cada entrada, salida o ajuste.

**Clientes** — `Cliente` más `Dirección` (relación uno a muchos, con flag de predeterminada para el checkout ágil).

**Ventas** — el módulo más crítico. `Pedido` registra la cabecera y el canal (online / mostrador); `Detalle_Pedido` el carrito línea por línea; `Pago` admite pagos múltiples por pedido (efectivo + tarjeta, por ejemplo); `Envío` gestiona el rastreo logístico.

**Promociones** — `Cupón` con tipos (porcentaje, monto fijo, envío gratis) y `Pedido_Cupón` registra cuánto se aplicó realmente.

**Operaciones** — `Sucursal`, `Empleado` y `Proveedor` dan soporte al inventario físico, control de accesos y compras.

Haz clic en cualquier entidad para explorar sus atributos con más detalle. ¿Quieres que genere el ERD completo con las relaciones, o profundizamos en algún módulo específico como el de ventas o inventario?
