# andina-market-db

Proyecto de Base de Datos – **Andina Market**, tienda en línea de artesanías, tecnología y artículos del hogar (MySQL 8.0.16 o superior).

## Orden de ejecución
1. `andina_market_db.sql` – tablas y datos de ejemplo
2. `triggers_y_procedimientos.sql` – reglas de negocio (stock, reseñas, pagos) y carrito
3. `vistas.sql` – vistas de consulta
4. `proteccion_datos.sql` – vistas enmascaradas, roles, auditoría y anonimización
5. `consultas_e_indices.sql` – consultas de análisis, índices y `EXPLAIN` antes/después

Política escrita: `POLITICA_PROTECCION_DATOS.md`.

## Reglas de negocio cubiertas
- Un pedido solo se confirma si hay stock (se valida y se descuenta; se repone al cancelar).
- Un cliente puede tener varias direcciones, y el pedido solo acepta una suya.
- Solo reseña quien compró el producto y ya recibió el pedido.
- Pago generalizado en Tarjeta, Yape/Plin, Transferencia y Contraentrega, cada tabla hija validada contra su tipo.
