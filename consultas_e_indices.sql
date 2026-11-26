USE andina_market;

-- ==========================================
-- CONSULTAS DE ANÁLISIS
-- ==========================================

-- Ventas por mes y categoría (solo pagos aprobados).
-- Filtra por RANGO de fechas para que MySQL pueda usar idx_pedido_fecha
-- (YEAR()/MONTH() en el WHERE impedirían usar el índice).
-- Para ver todo el historial, quita las dos condiciones de fecha_pedido.
SELECT
    YEAR(pe.fecha_pedido) AS anio,
    MONTH(pe.fecha_pedido) AS mes,
    c.nombre AS categoria,
    SUM(pd.cantidad) AS unidades_vendidas,
    SUM(pd.cantidad * pd.precio_unitario) AS total_ventas
FROM Pedido pe
INNER JOIN Pago pa ON pe.pedido_id = pa.pedido_id
INNER JOIN Pedido_Detalle pd ON pe.pedido_id = pd.pedido_id
INNER JOIN Producto pr ON pd.producto_id = pr.producto_id
INNER JOIN Categoria c ON pr.categoria_id = c.categoria_id
WHERE pa.estado = 'aprobado'
  AND pe.fecha_pedido >= '2026-10-01'
  AND pe.fecha_pedido <  '2027-01-01'
GROUP BY
    YEAR(pe.fecha_pedido),
    MONTH(pe.fecha_pedido),
    c.categoria_id,
    c.nombre
ORDER BY
    anio,
    mes,
    total_ventas DESC;

-- Productos más vendidos
SELECT
    pr.producto_id,
    pr.nombre AS producto,
    c.nombre AS categoria,
    SUM(pd.cantidad) AS unidades_vendidas,
    SUM(pd.cantidad * pd.precio_unitario) AS total_generado
FROM Pedido_Detalle pd
INNER JOIN Pedido pe ON pd.pedido_id = pe.pedido_id
INNER JOIN Pago pa ON pe.pedido_id = pa.pedido_id
INNER JOIN Producto pr ON pd.producto_id = pr.producto_id
INNER JOIN Categoria c ON pr.categoria_id = c.categoria_id
WHERE pa.estado = 'aprobado'
GROUP BY
    pr.producto_id,
    pr.nombre,
    c.nombre
ORDER BY unidades_vendidas DESC
LIMIT 10;

-- Productos mejor calificados
SELECT
    pr.producto_id,
    pr.nombre AS producto,
    c.nombre AS categoria,
    ROUND(AVG(r.calificacion), 2) AS promedio_calificacion,
    COUNT(r.resena_id) AS total_resenas
FROM Producto pr
INNER JOIN Categoria c ON pr.categoria_id = c.categoria_id
INNER JOIN Resena r ON pr.producto_id = r.producto_id
GROUP BY
    pr.producto_id,
    pr.nombre,
    c.nombre
ORDER BY promedio_calificacion DESC, total_resenas DESC
LIMIT 10;

-- ==========================================
-- PRUEBA DE RENDIMIENTO: ANTES DEL ÍNDICE
-- (con la tabla sin índice por nombre, se espera type = ALL)
-- ==========================================
EXPLAIN SELECT * FROM Producto WHERE nombre = 'Audífonos Bluetooth';

-- ==========================================
-- CREACIÓN DE ÍNDICES
-- Si ya existen (por ejecutar el script dos veces), MySQL dará error de índice duplicado: se puede ignorar.
-- ==========================================
-- Índice para buscar productos por nombre
CREATE INDEX idx_producto_nombre ON Producto(nombre);

-- Índice para consultar pedidos por fecha (consulta de ventas por mes)
CREATE INDEX idx_pedido_fecha ON Pedido(fecha_pedido);

-- Índice para calificaciones por producto (promedios)
CREATE INDEX idx_resena_producto_calificacion ON Resena(producto_id, calificacion);

-- NOTA: no se crea un índice sobre Pedido_Detalle(producto_id) porque esa columna
-- es clave foránea y InnoDB ya crea un índice automático para ella.
-- Se puede comprobar con:
SHOW INDEX FROM Pedido_Detalle;

-- ==========================================
-- PRUEBA DE RENDIMIENTO: DESPUÉS DEL ÍNDICE
-- (se espera type = ref, key = idx_producto_nombre)
-- ==========================================
EXPLAIN SELECT * FROM Producto WHERE nombre = 'Audífonos Bluetooth';

-- La consulta mensual con rango de fechas puede usar idx_pedido_fecha
EXPLAIN SELECT pe.pedido_id
FROM Pedido pe
WHERE pe.fecha_pedido >= '2026-10-01' AND pe.fecha_pedido < '2027-01-01';
