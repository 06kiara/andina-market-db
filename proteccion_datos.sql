USE andina_market;

-- ==========================================
-- PROTECCIÓN DE DATOS PERSONALES Y DE PAGO
-- Requiere MySQL 8.0 (usa ROLE). Ejecutar DESPUÉS de andina_market_db.sql,
-- triggers_y_procedimientos.sql y vistas.sql.
-- La política completa está en POLITICA_PROTECCION_DATOS.md
-- ==========================================

-- ------------------------------------------
-- 1. VISTAS QUE OCULTAN DATOS SENSIBLES
-- ------------------------------------------

-- Clientes sin datos de contacto completos
CREATE OR REPLACE VIEW vista_clientes_enmascarada AS
SELECT
    cliente_id,
    CONCAT(LEFT(nombre, 1), '***') AS nombre,
    CONCAT(LEFT(apellido, 1), '***') AS apellido,
    CONCAT(LEFT(email, 2), '***', SUBSTRING(email, LOCATE('@', email))) AS email,
    CASE WHEN telefono IS NULL THEN NULL ELSE CONCAT('******', RIGHT(telefono, 3)) END AS telefono,
    fecha_registro
FROM Cliente;

-- Pagos sin titular, token, teléfono ni número de operación
CREATE OR REPLACE VIEW vista_pagos_seguros AS
SELECT
    pa.pago_id,
    pa.pedido_id,
    pa.tipo_pago,
    pa.estado,
    pa.monto,
    pa.fecha_pago,
    pt.marca_tarjeta,
    pt.ultimos_4_digitos
FROM Pago pa
LEFT JOIN Pago_Tarjeta pt ON pa.pago_id = pt.pago_id;

-- Ventas por mes y categoría, sin ningún dato de clientes (para análisis)
CREATE OR REPLACE VIEW vista_ventas_mensuales AS
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
GROUP BY YEAR(pe.fecha_pedido), MONTH(pe.fecha_pedido), c.categoria_id, c.nombre;

-- ------------------------------------------
-- 2. ROLES Y PERMISOS (mínimo privilegio)
-- ------------------------------------------
CREATE ROLE IF NOT EXISTS 'rol_admin_bd', 'rol_atencion', 'rol_analista', 'rol_pagos', 'rol_app_tienda';

-- Administrador de la base de datos
GRANT ALL PRIVILEGES ON andina_market.* TO 'rol_admin_bd';

-- Atención al cliente: ve clientes, pedidos y envíos; NO ve datos de pago sensibles
GRANT SELECT ON andina_market.Cliente TO 'rol_atencion';
GRANT SELECT ON andina_market.Direccion TO 'rol_atencion';
GRANT SELECT ON andina_market.Pedido TO 'rol_atencion';
GRANT SELECT ON andina_market.Pedido_Detalle TO 'rol_atencion';
GRANT SELECT ON andina_market.Producto TO 'rol_atencion';
GRANT SELECT ON andina_market.Categoria TO 'rol_atencion';
GRANT SELECT ON andina_market.Envio TO 'rol_atencion';
GRANT UPDATE (empresa_transporte, estado) ON andina_market.Envio TO 'rol_atencion';
GRANT SELECT ON andina_market.vista_pagos_seguros TO 'rol_atencion';

-- Analista: solo vistas sin datos personales identificables
GRANT SELECT ON andina_market.vista_ventas_mensuales TO 'rol_analista';
GRANT SELECT ON andina_market.vista_catalogo_disponible TO 'rol_analista';
GRANT SELECT ON andina_market.vista_clientes_enmascarada TO 'rol_analista';
GRANT SELECT ON andina_market.vista_pagos_seguros TO 'rol_analista';

-- Pagos: único rol con acceso a las tablas de pago
GRANT SELECT, INSERT, UPDATE ON andina_market.Pago TO 'rol_pagos';
GRANT SELECT, INSERT, UPDATE ON andina_market.Pago_Tarjeta TO 'rol_pagos';
GRANT SELECT, INSERT, UPDATE ON andina_market.Pago_YapePlin TO 'rol_pagos';
GRANT SELECT, INSERT, UPDATE ON andina_market.Pago_Transferencia TO 'rol_pagos';
GRANT SELECT, INSERT, UPDATE ON andina_market.Pago_Contraentrega TO 'rol_pagos';
GRANT SELECT ON andina_market.Pedido TO 'rol_pagos';

-- Aplicación web de la tienda: sin DELETE ni acceso a tablas de pago
GRANT SELECT ON andina_market.Producto TO 'rol_app_tienda';
GRANT SELECT ON andina_market.Categoria TO 'rol_app_tienda';
GRANT SELECT ON andina_market.vista_catalogo_disponible TO 'rol_app_tienda';
GRANT SELECT, INSERT, UPDATE ON andina_market.Cliente TO 'rol_app_tienda';
GRANT SELECT, INSERT, UPDATE ON andina_market.Direccion TO 'rol_app_tienda';
GRANT SELECT ON andina_market.Pedido TO 'rol_app_tienda';
GRANT SELECT ON andina_market.Pedido_Detalle TO 'rol_app_tienda';
GRANT SELECT, INSERT ON andina_market.Resena TO 'rol_app_tienda';
GRANT EXECUTE ON PROCEDURE andina_market.sp_agregar_al_carrito TO 'rol_app_tienda';
GRANT EXECUTE ON PROCEDURE andina_market.sp_pasar_carrito_a_pedido TO 'rol_app_tienda';

-- Usuarios de ejemplo. CAMBIAR las claves antes de usar fuera de clase.
-- En producción, agregar REQUIRE SSL para exigir conexión cifrada.
CREATE USER IF NOT EXISTS 'u_atencion'@'localhost' IDENTIFIED BY 'CAMBIAR_CLAVE_ATENCION';
CREATE USER IF NOT EXISTS 'u_analista'@'localhost' IDENTIFIED BY 'CAMBIAR_CLAVE_ANALISTA';
CREATE USER IF NOT EXISTS 'u_pagos'@'localhost' IDENTIFIED BY 'CAMBIAR_CLAVE_PAGOS';
CREATE USER IF NOT EXISTS 'u_app'@'localhost' IDENTIFIED BY 'CAMBIAR_CLAVE_APP';

GRANT 'rol_atencion' TO 'u_atencion'@'localhost';
GRANT 'rol_analista' TO 'u_analista'@'localhost';
GRANT 'rol_pagos' TO 'u_pagos'@'localhost';
GRANT 'rol_app_tienda' TO 'u_app'@'localhost';
SET DEFAULT ROLE ALL TO 'u_atencion'@'localhost', 'u_analista'@'localhost', 'u_pagos'@'localhost', 'u_app'@'localhost';

-- ------------------------------------------
-- 3. AUDITORÍA DE CAMBIOS EN DATOS PERSONALES
--    Solo registra quién, cuándo y qué registro; NUNCA guarda los valores
--    (así la auditoría no conserva datos que luego se deban borrar).
-- ------------------------------------------
CREATE TABLE IF NOT EXISTS Auditoria_Datos (
    auditoria_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tabla VARCHAR(50) NOT NULL,
    accion ENUM('UPDATE','DELETE') NOT NULL,
    registro_id INT NOT NULL,
    usuario_bd VARCHAR(100) NOT NULL,
    fecha_evento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS tr_auditar_cliente_update;
DROP TRIGGER IF EXISTS tr_auditar_cliente_delete;

DELIMITER //
CREATE TRIGGER tr_auditar_cliente_update
AFTER UPDATE ON Cliente
FOR EACH ROW
BEGIN
    INSERT INTO Auditoria_Datos (tabla, accion, registro_id, usuario_bd)
    VALUES ('Cliente', 'UPDATE', NEW.cliente_id, CURRENT_USER());
END //

CREATE TRIGGER tr_auditar_cliente_delete
AFTER DELETE ON Cliente
FOR EACH ROW
BEGIN
    INSERT INTO Auditoria_Datos (tabla, accion, registro_id, usuario_bd)
    VALUES ('Cliente', 'DELETE', OLD.cliente_id, CURRENT_USER());
END //
DELIMITER ;

-- ------------------------------------------
-- 4. DERECHO DE CANCELACIÓN: ANONIMIZAR A UN CLIENTE
--    Conserva pedidos y montos (para contabilidad) pero elimina los datos
--    que identifican a la persona.
-- ------------------------------------------
DROP PROCEDURE IF EXISTS sp_anonimizar_cliente;

DELIMITER //
CREATE PROCEDURE sp_anonimizar_cliente(IN p_cliente_id INT)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT COUNT(*) INTO v_existe FROM Cliente WHERE cliente_id = p_cliente_id;
    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: el cliente no existe';
    END IF;

    START TRANSACTION;

    UPDATE Cliente
    SET nombre = 'ANONIMIZADO',
        apellido = 'ANONIMIZADO',
        email = CONCAT('anonimo_', cliente_id, '@anonimo.invalid'),
        telefono = NULL
    WHERE cliente_id = p_cliente_id;

    UPDATE Direccion
    SET linea_direccion = 'ANONIMIZADO', referencia = NULL
    WHERE cliente_id = p_cliente_id;

    UPDATE Pago_Tarjeta pt
    INNER JOIN Pago pa ON pt.pago_id = pa.pago_id
    INNER JOIN Pedido pe ON pa.pedido_id = pe.pedido_id
    SET pt.titular_nombre = 'ANONIMIZADO'
    WHERE pe.cliente_id = p_cliente_id;

    UPDATE Pago_YapePlin py
    INNER JOIN Pago pa ON py.pago_id = pa.pago_id
    INNER JOIN Pedido pe ON pa.pedido_id = pe.pedido_id
    SET py.telefono_origen = '000000000'
    WHERE pe.cliente_id = p_cliente_id;

    COMMIT;
END //
DELIMITER ;

GRANT EXECUTE ON PROCEDURE andina_market.sp_anonimizar_cliente TO 'rol_admin_bd';
