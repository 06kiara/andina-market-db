USE andina_market;

-- 1. Vista de catálogo disponible (solo productos activos y con stock)
CREATE OR REPLACE VIEW vista_catalogo_disponible AS
SELECT p.producto_id, p.nombre AS producto, c.nombre AS categoria, p.precio, p.stock
FROM Producto p
INNER JOIN Categoria c ON p.categoria_id = c.categoria_id
WHERE p.stock > 0 AND p.activo = TRUE;

-- 2. Vista de pedidos con nombre del cliente (ahora incluye la fecha)
CREATE OR REPLACE VIEW vista_pedidos_clientes AS
SELECT pe.pedido_id, CONCAT(cl.nombre, ' ', cl.apellido) AS cliente, pe.fecha_pedido, pe.estado, pe.total
FROM Pedido pe
INNER JOIN Cliente cl ON pe.cliente_id = cl.cliente_id;

-- 3. Vista de resumen de pagos (sin datos de tarjeta ni de operación)
CREATE OR REPLACE VIEW vista_resumen_pagos AS
SELECT p.pago_id, p.tipo_pago, p.monto, p.estado, p.fecha_pago, pe.pedido_id
FROM Pago p
INNER JOIN Pedido pe ON p.pedido_id = pe.pedido_id;
