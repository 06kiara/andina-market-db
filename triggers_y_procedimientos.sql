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

    START TRANSACTION;

    INSERT INTO Pedido (cliente_id, direccion_id, estado, total)
    VALUES (p_cliente_id, p_direccion_id, 'confirmado', v_total);

    SET p_pedido_id = LAST_INSERT_ID();

    -- Los triggers validan el stock y lo descuentan
    INSERT INTO Pedido_Detalle (pedido_id, producto_id, cantidad, precio_unitario)
    SELECT p_pedido_id, cd.producto_id, cd.cantidad, p.precio
    FROM Carrito_Detalle cd
    INNER JOIN Producto p ON cd.producto_id = p.producto_id
    WHERE cd.carrito_id = v_carrito_id;

    UPDATE Carrito SET estado = 'convertido' WHERE carrito_id = v_carrito_id;

    COMMIT;
END //
DELIMITER ;
