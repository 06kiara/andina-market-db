USE andina_market;

-- ==========================================
-- CONSULTAS DE ANÁLISIS
-- ==========================================
-- Consulta de ventas por categoría
SELECT c.nombre AS categoria, SUM(pd.cantidad) AS unidades_vendidas, SUM(pd.cantidad * pd.precio_unitario) AS total_ventas
FROM Pedido pe INNER JOIN Pago pa ON pe.pedido_id = pa.pedido_id INNER JOIN Pedido_Detalle pd ON pe.pedido_id = pd.pedido_id
INNER JOIN Producto pr ON pd.producto_id = pr.producto_id INNER JOIN Categoria c ON pr.categoria_id = c.categoria_id
WHERE pa.estado = 'aprobado' GROUP BY c.categoria_id, c.nombre ORDER BY total_ventas DESC;

-- Consulta de productos más vendidos
SELECT pr.producto_id, pr.nombre AS producto, c.nombre AS categoria, SUM(pd.cantidad) AS unidades_vendidas, SUM(pd.cantidad * pd.precio_unitario) AS total_generado
FROM Pedido_Detalle pd INNER JOIN Pedido pe ON pd.pedido_id = pe.pedido_id INNER JOIN Pago pa ON pe.pedido_id = pa.pedido_id
INNER JOIN Producto pr ON pd.producto_id = pr.producto_id INNER JOIN Categoria c ON pr.categoria_id = c.categoria_id
WHERE pa.estado = 'aprobado' GROUP BY pr.producto_id, pr.nombre, c.nombre ORDER BY unidades_vendidas DESC LIMIT 10;

-- Consulta de productos mejor calificados
SELECT pr.producto_id, pr.nombre AS producto, c.nombre AS categoria, ROUND(AVG(r.calificacion), 2) AS promedio_calificacion, COUNT(r.resena_id) AS total_resenas
FROM Producto pr INNER JOIN Categoria c ON pr.categoria_id = c.categoria_id INNER JOIN Resena r ON pr.producto_id = r.producto_id
GROUP BY pr.producto_id, pr.nombre, c.nombre ORDER BY promedio_calificacion DESC, total_resenas DESC LIMIT 10;

-- ==========================================
-- CREACIÓN DE ÍNDICES
-- ==========================================
CREATE INDEX idx_producto_nombre ON Producto(nombre);
CREATE INDEX idx_pedido_estado_total ON Pedido(estado, total);
CREATE INDEX idx_resena_producto_calificacion ON Resena(producto_id, calificacion);

-- ==========================================
-- PRUEBA DE RENDIMIENTO (EXPLAIN)
-- ==========================================
EXPLAIN SELECT * FROM Producto WHERE nombre = 'Audífonos Bluetooth';