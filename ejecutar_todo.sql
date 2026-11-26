-- ================================================================
-- ANDINA MARKET - EJECUTAR TODO (archivos 1 a 5 en orden)
-- Borra la base andina_market si ya existe y la crea de nuevo.
-- Requiere MySQL 8.0.16 o superior y usuario root.
-- ================================================================
DROP DATABASE IF EXISTS andina_market;

-- ########## andina_market_db.sql ##########
CREATE DATABASE IF NOT EXISTS andina_market;
USE andina_market;

CREATE TABLE Cliente (
    cliente_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Direccion (
    direccion_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    departamento VARCHAR(80) NOT NULL,
    provincia VARCHAR(80) NOT NULL,
    distrito VARCHAR(80) NOT NULL,
    linea_direccion VARCHAR(255) NOT NULL,
    referencia VARCHAR(255),
    es_principal BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (cliente_id) REFERENCES Cliente(cliente_id) ON DELETE CASCADE,
    UNIQUE KEY uk_direccion_cliente (direccion_id, cliente_id)
);

CREATE TABLE Categoria (
    categoria_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
);

CREATE TABLE Producto (
    producto_id INT AUTO_INCREMENT PRIMARY KEY,
    categoria_id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES Categoria(categoria_id),
    CHECK (precio > 0),
    CHECK (stock >= 0)
);

CREATE TABLE Carrito (
    carrito_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    estado ENUM('activo','convertido','abandonado') NOT NULL DEFAULT 'activo',
    FOREIGN KEY (cliente_id) REFERENCES Cliente(cliente_id) ON DELETE CASCADE
);

CREATE TABLE Carrito_Detalle (
    carrito_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    PRIMARY KEY (carrito_id, producto_id),
    FOREIGN KEY (carrito_id) REFERENCES Carrito(carrito_id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id),
    CHECK (cantidad>0)
);

CREATE TABLE Pedido (
    pedido_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    direccion_id INT NOT NULL,
    fecha_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente','confirmado','enviado','entregado','cancelado') NOT NULL DEFAULT 'pendiente',
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (cliente_id) REFERENCES Cliente(cliente_id),
    -- La direccion debe pertenecer al mismo cliente del pedido
    FOREIGN KEY (direccion_id, cliente_id) REFERENCES Direccion(direccion_id, cliente_id)
);

CREATE TABLE Pedido_Detalle (
    pedido_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (pedido_id, producto_id),
    FOREIGN KEY (pedido_id) REFERENCES Pedido(pedido_id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id),
    CHECK (cantidad>0),
    CHECK (precio_unitario>0)
);

CREATE TABLE Pago (
    pago_id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    fecha_pago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente','aprobado','rechazado','reembolsado') NOT NULL DEFAULT 'pendiente',
    tipo_pago ENUM('tarjeta','yape_plin','transferencia','contraentrega') NOT NULL,
    FOREIGN KEY (pedido_id) REFERENCES Pedido(pedido_id),
    UNIQUE KEY uk_pago_pedido (pedido_id),
    CHECK (monto > 0)
);

CREATE TABLE Pago_Tarjeta (
    pago_id INT PRIMARY KEY,
    titular_nombre VARCHAR(150) NOT NULL,
    ultimos_4_digitos CHAR(4) NOT NULL,
    marca_tarjeta VARCHAR(30) NOT NULL,
    token_transaccion VARCHAR(255) NOT NULL,
    FOREIGN KEY (pago_id) REFERENCES Pago(pago_id) ON DELETE CASCADE
);

CREATE TABLE Pago_YapePlin (
    pago_id INT PRIMARY KEY,
    telefono_origen VARCHAR(20) NOT NULL,
    codigo_operacion VARCHAR(100) NOT NULL,
    plataforma ENUM('yape','plin') NOT NULL,
    FOREIGN KEY (pago_id) REFERENCES Pago(pago_id) ON DELETE CASCADE
);

CREATE TABLE Pago_Transferencia (
    pago_id INT PRIMARY KEY,
    banco_origen VARCHAR(100) NOT NULL,
    numero_operacion VARCHAR(100) NOT NULL,
    cuenta_destino VARCHAR(50) NOT NULL,
    FOREIGN KEY (pago_id) REFERENCES Pago(pago_id) ON DELETE CASCADE
);

CREATE TABLE Pago_Contraentrega (
    pago_id INT PRIMARY KEY,
    monto_recibido DECIMAL(10,2),
    fecha_entrega_real DATETIME,
    FOREIGN KEY (pago_id) REFERENCES Pago(pago_id) ON DELETE CASCADE
);

CREATE TABLE Envio (
    envio_id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL UNIQUE,
    empresa_transporte VARCHAR(100),
    estado ENUM('preparando','en_transito','entregado','fallido') NOT NULL DEFAULT 'preparando',
    FOREIGN KEY (pedido_id) REFERENCES Pedido(pedido_id) ON DELETE CASCADE
);

CREATE TABLE Resena (
    resena_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    producto_id INT NOT NULL,
    calificacion TINYINT NOT NULL,
    comentario TEXT,
    FOREIGN KEY (cliente_id) REFERENCES Cliente(cliente_id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id) ON DELETE CASCADE,
    UNIQUE (cliente_id, producto_id),
    CHECK (calificacion BETWEEN 1 AND 5)
);

INSERT INTO Cliente (nombre, apellido, email, telefono) VALUES
('Lucia', 'Quispe', 'lucia.quispe@mail.com', '987654321'),
('Carlos', 'Mendoza', 'carlos.mendoza@mail.com', '912345678'),
('Ana', 'Flores', 'ana.flores@mail.com', '956781234'),
('Diego', 'Rojas', 'diego.rojas@mail.com', '934567812'),
('Valeria', 'Huaman', 'valeria.huaman@mail.com', '978123456');

INSERT INTO Categoria (nombre, descripcion) VALUES
('Artesanías', 'Productos hechos a mano'),
('Tecnología', 'Dispositivos y accesorios'),
('Hogar', 'Artículos para el hogar');

INSERT INTO Producto (categoria_id, nombre, descripcion, precio, stock) VALUES
(1, 'Manta andina de lana de alpaca', 'Tejida a mano', 180.00, 15),
(1, 'Cerámica de Quinua', 'Juego de tazas', 65.00, 30),
(1, 'Retablo ayacuchano', 'Artesanía pintada', 120.00, 10),
(1, 'Bolso de cuero artesanal', 'Diseños andinos', 95.00, 20),
(2, 'Audífonos Bluetooth', 'Cancelación de ruido', 249.90, 50),
(2, 'Cargador USB-C 65W', 'Carga rápida', 89.90, 80),
(2, 'Mouse inalámbrico', '1600 DPI', 45.00, 60),
(2, 'Teclado mecánico', 'Switches rojos', 199.00, 25),
(3, 'Juego de manteles', 'Algodón, 4 piezas', 55.00, 40),
(3, 'Lámpara de cerámica', 'Base artesanal', 78.00, 18);

INSERT INTO Direccion (cliente_id, departamento, provincia, distrito, linea_direccion, es_principal) VALUES
(1, 'Lima', 'Lima', 'Miraflores', 'Av. Larco 123', TRUE),
(1, 'Lima', 'Lima', 'San Isidro', 'Calle Álamos 456', FALSE),
(2, 'Cusco', 'Cusco', 'Cusco', 'Av. El Sol 789', TRUE),
(3, 'Arequipa', 'Arequipa', 'Yanahuara', 'Calle San José 321', TRUE),
(4, 'Lima', 'Lima', 'Barranco', 'Jr. Unión 654', TRUE),
(5, 'La Libertad', 'Trujillo', 'Trujillo', 'Av. España 987', TRUE);

INSERT INTO Pedido (cliente_id, direccion_id, fecha_pedido, estado, total) VALUES
(1, 1, '2026-10-05 10:30:00', 'entregado', 300.00),
(2, 3, '2026-11-10 14:20:00', 'entregado', 249.90),
(3, 4, '2026-11-20 16:45:00', 'pendiente', 65.00);

INSERT INTO Pedido_Detalle (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 1, 180.00),
(1, 2, 1, 65.00),
(1, 9, 1, 55.00),
(2, 5, 1, 249.90),
(3, 2, 1, 65.00);

INSERT INTO Pago (pedido_id, monto, estado, tipo_pago) VALUES
(1, 300.00, 'aprobado', 'tarjeta');
INSERT INTO Pago_Tarjeta (pago_id, titular_nombre, ultimos_4_digitos, marca_tarjeta, token_transaccion) VALUES
(1, 'LUCIA QUISPE', '4521', 'Visa', 'tok_9f3a2b8c1d');

INSERT INTO Pago (pedido_id, monto, estado, tipo_pago) VALUES
(2, 249.90, 'aprobado', 'yape_plin');
INSERT INTO Pago_YapePlin (pago_id, telefono_origen, codigo_operacion, plataforma) VALUES
(2, '912345678', 'YAP-20261110-001', 'yape');

INSERT INTO Pago (pedido_id, monto, estado, tipo_pago) VALUES
(3, 65.00, 'pendiente', 'contraentrega');
INSERT INTO Pago_Contraentrega (pago_id, monto_recibido, fecha_entrega_real) VALUES
(3, NULL, NULL);

INSERT INTO Resena (cliente_id, producto_id, calificacion, comentario) VALUES
(1, 1, 5, 'Excelente calidad y acabado artesanal'),
(1, 2, 4, 'Muy bonito diseño'),
(1, 9, 5, 'Buen material y presentación'),
(2, 5, 5, 'Excelente sonido y funcionamiento');

INSERT INTO Envio (pedido_id, empresa_transporte, estado) VALUES
(1, 'Olva Courier', 'entregado'),
(2, 'Shalom', 'entregado');

INSERT INTO Carrito (cliente_id, estado) VALUES
(4, 'activo'),
(5, 'activo');

INSERT INTO Carrito_Detalle (carrito_id, producto_id, cantidad) VALUES
(1, 6, 2),
(1, 7, 1),
(2, 3, 1);

-- ########## triggers_y_procedimientos.sql ##########
USE andina_market;

-- ==========================================
-- REGLAS DE NEGOCIO Y LÓGICA
-- Ejecutar DESPUÉS de andina_market_db.sql
-- Se puede volver a ejecutar sin errores (DROP ... IF EXISTS).
-- ==========================================

DROP TRIGGER IF EXISTS tr_validar_stock_pedido;
DROP TRIGGER IF EXISTS tr_descontar_stock_pedido;
DROP TRIGGER IF EXISTS tr_reponer_stock_cancelado;
DROP TRIGGER IF EXISTS tr_validar_compra_resena;
DROP TRIGGER IF EXISTS tr_pago_tarjeta_tipo;
DROP TRIGGER IF EXISTS tr_pago_yapeplin_tipo;
DROP TRIGGER IF EXISTS tr_pago_transferencia_tipo;
DROP TRIGGER IF EXISTS tr_pago_contraentrega_tipo;
DROP PROCEDURE IF EXISTS sp_agregar_al_carrito;
DROP PROCEDURE IF EXISTS sp_pasar_carrito_a_pedido;

-- ==========================================
-- 1. STOCK: "Un pedido solo se confirma si hay stock"
-- ==========================================

-- 1.1 Valida que el producto esté disponible y que alcance el stock
DELIMITER //
CREATE TRIGGER tr_validar_stock_pedido
BEFORE INSERT ON Pedido_Detalle
FOR EACH ROW
BEGIN
    DECLARE v_stock_actual INT;
    DECLARE v_activo BOOLEAN;

    -- FOR UPDATE bloquea la fila para que dos pedidos simultáneos no vendan el mismo stock
    SELECT stock, activo INTO v_stock_actual, v_activo
    FROM Producto
    WHERE producto_id = NEW.producto_id
    FOR UPDATE;

    IF v_stock_actual IS NULL OR v_activo = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Producto no disponible';
    END IF;

    IF NEW.cantidad > v_stock_actual THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Stock insuficiente';
    END IF;
END //

-- 1.2 Descuenta el stock cuando se registra el detalle del pedido
CREATE TRIGGER tr_descontar_stock_pedido
AFTER INSERT ON Pedido_Detalle
FOR EACH ROW
BEGIN
    UPDATE Producto
    SET stock = stock - NEW.cantidad
    WHERE producto_id = NEW.producto_id;
END //

-- 1.3 Devuelve el stock si el pedido pasa a 'cancelado'
CREATE TRIGGER tr_reponer_stock_cancelado
AFTER UPDATE ON Pedido
FOR EACH ROW
BEGIN
    IF NEW.estado = 'cancelado' AND OLD.estado <> 'cancelado' THEN
        UPDATE Producto pr
        INNER JOIN Pedido_Detalle pd ON pr.producto_id = pd.producto_id
        SET pr.stock = pr.stock + pd.cantidad
        WHERE pd.pedido_id = NEW.pedido_id;
    END IF;
END //
DELIMITER ;

-- ==========================================
-- 2. RESEÑAS: "Solo puede reseñar quien compró el producto"
--    Ahora exige que el pedido esté 'entregado'
--    (antes aceptaba pedidos pendientes o cancelados).
-- ==========================================
DELIMITER //
CREATE TRIGGER tr_validar_compra_resena
BEFORE INSERT ON Resena
FOR EACH ROW
BEGIN
    DECLARE v_compro INT;

    SELECT COUNT(*) INTO v_compro
    FROM Pedido p
    INNER JOIN Pedido_Detalle pd ON p.pedido_id = pd.pedido_id
    WHERE p.cliente_id = NEW.cliente_id
      AND pd.producto_id = NEW.producto_id
      AND p.estado = 'entregado';

    IF v_compro = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Solo compradores con pedido entregado pueden resenar';
    END IF;
END //
DELIMITER ;

-- ==========================================
-- 3. GENERALIZACIÓN DE PAGO
--    Cada tabla hija solo acepta pagos de su propio tipo.
-- ==========================================
DELIMITER //
CREATE TRIGGER tr_pago_tarjeta_tipo
BEFORE INSERT ON Pago_Tarjeta
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(20);
    SELECT tipo_pago INTO v_tipo FROM Pago WHERE pago_id = NEW.pago_id;
    IF v_tipo IS NULL OR v_tipo <> 'tarjeta' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: el pago no es de tipo tarjeta';
    END IF;
END //

CREATE TRIGGER tr_pago_yapeplin_tipo
BEFORE INSERT ON Pago_YapePlin
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(20);
    SELECT tipo_pago INTO v_tipo FROM Pago WHERE pago_id = NEW.pago_id;
    IF v_tipo IS NULL OR v_tipo <> 'yape_plin' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: el pago no es de tipo yape_plin';
    END IF;
END //

CREATE TRIGGER tr_pago_transferencia_tipo
BEFORE INSERT ON Pago_Transferencia
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(20);
    SELECT tipo_pago INTO v_tipo FROM Pago WHERE pago_id = NEW.pago_id;
    IF v_tipo IS NULL OR v_tipo <> 'transferencia' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: el pago no es de tipo transferencia';
    END IF;
END //

CREATE TRIGGER tr_pago_contraentrega_tipo
BEFORE INSERT ON Pago_Contraentrega
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(20);
    SELECT tipo_pago INTO v_tipo FROM Pago WHERE pago_id = NEW.pago_id;
    IF v_tipo IS NULL OR v_tipo <> 'contraentrega' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: el pago no es de tipo contraentrega';
    END IF;
END //
DELIMITER ;

-- ==========================================
-- 4. PROCEDIMIENTOS ALMACENADOS (Lógica del carrito)
-- ==========================================
DELIMITER //

-- Agrega un producto al carrito activo (lo crea si no existe)
CREATE PROCEDURE sp_agregar_al_carrito(IN p_cliente_id INT, IN p_producto_id INT, IN p_cantidad INT)
BEGIN
    DECLARE v_carrito_id INT DEFAULT NULL;
    DECLARE v_disponible INT DEFAULT 0;

    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: la cantidad debe ser mayor que cero';
    END IF;

    SELECT COUNT(*) INTO v_disponible
    FROM Producto
    WHERE producto_id = p_producto_id AND activo = TRUE;

    IF v_disponible = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Producto no disponible';
    END IF;

    SELECT carrito_id INTO v_carrito_id
    FROM Carrito
    WHERE cliente_id = p_cliente_id AND estado = 'activo' LIMIT 1;

    IF v_carrito_id IS NULL THEN
        INSERT INTO Carrito (cliente_id, estado) VALUES (p_cliente_id, 'activo');
        SET v_carrito_id = LAST_INSERT_ID();
    END IF;

    INSERT INTO Carrito_Detalle (carrito_id, producto_id, cantidad)
    VALUES (v_carrito_id, p_producto_id, p_cantidad)
    ON DUPLICATE KEY UPDATE cantidad = cantidad + p_cantidad;
END //

-- Convierte el carrito activo en un pedido (todo o nada, con transacción)
CREATE PROCEDURE sp_pasar_carrito_a_pedido(IN p_cliente_id INT, IN p_direccion_id INT, OUT p_pedido_id INT)
BEGIN
    DECLARE v_carrito_id INT DEFAULT NULL;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    DECLARE v_dir_ok INT DEFAULT 0;

    -- Si algo falla (por ejemplo "Stock insuficiente"), se deshace todo
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_pedido_id = NULL;
        RESIGNAL;
    END;

    SELECT carrito_id INTO v_carrito_id
    FROM Carrito
    WHERE cliente_id = p_cliente_id AND estado = 'activo' LIMIT 1;

    IF v_carrito_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: el cliente no tiene un carrito activo';
    END IF;

    SELECT COUNT(*) INTO v_dir_ok
    FROM Direccion
    WHERE direccion_id = p_direccion_id AND cliente_id = p_cliente_id;

    IF v_dir_ok = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: la direccion no pertenece al cliente';
    END IF;

    SELECT COALESCE(SUM(p.precio * cd.cantidad), 0) INTO v_total
    FROM Carrito_Detalle cd
    INNER JOIN Producto p ON cd.producto_id = p.producto_id
    WHERE cd.carrito_id = v_carrito_id;

    IF v_total = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: el carrito esta vacio';
    END IF;

    -- Se copian primero los productos y precios a una tabla temporal.
    -- Así el INSERT de abajo no lee la tabla Producto, y el trigger que
    -- descuenta el stock puede actualizarla (si no, MySQL da el error 1442).
    DROP TEMPORARY TABLE IF EXISTS tmp_items_carrito;
    CREATE TEMPORARY TABLE tmp_items_carrito AS
        SELECT cd.producto_id, cd.cantidad, p.precio
        FROM Carrito_Detalle cd
        INNER JOIN Producto p ON cd.producto_id = p.producto_id
        WHERE cd.carrito_id = v_carrito_id;

    START TRANSACTION;

    INSERT INTO Pedido (cliente_id, direccion_id, estado, total)
    VALUES (p_cliente_id, p_direccion_id, 'confirmado', v_total);

    SET p_pedido_id = LAST_INSERT_ID();

    -- Los triggers validan el stock y lo descuentan
    INSERT INTO Pedido_Detalle (pedido_id, producto_id, cantidad, precio_unitario)
    SELECT p_pedido_id, producto_id, cantidad, precio
    FROM tmp_items_carrito;

    UPDATE Carrito SET estado = 'convertido' WHERE carrito_id = v_carrito_id;

    COMMIT;

    DROP TEMPORARY TABLE IF EXISTS tmp_items_carrito;
END //
DELIMITER ;


-- ########## vistas.sql ##########
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


-- ########## proteccion_datos.sql ##########
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


-- ########## consultas_e_indices.sql ##########
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

