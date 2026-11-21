USE andina_market;

-- ==========================================
-- PARTE 4: REGLAS DE NEGOCIO Y LÓGICA
-- ==========================================

-- 1. TRIGGERS DE VALIDACIÓN
-- Trigger para evitar ventas sin stock
DELIMITER //
CREATE TRIGGER tr_validar_stock_pedido
BEFORE INSERT ON Pedido_Detalle
FOR EACH ROW
BEGIN
    DECLARE v_stock_actual INT;
    
    SELECT stock INTO v_stock_actual FROM Producto WHERE producto_id = NEW.producto_id;
    
    IF NEW.cantidad > v_stock_actual THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Stock insuficiente';
    END IF;
END //
DELIMITER ;

-- Trigger para validar que solo compradores puedan reseñar
DELIMITER //
CREATE TRIGGER tr_validar_compra_resena
BEFORE INSERT ON Resena
FOR EACH ROW
BEGIN
    DECLARE v_compro INT;
    
    SELECT COUNT(*) INTO v_compro
    FROM Pedido p
    INNER JOIN Pedido_Detalle pd ON p.pedido_id = pd.pedido_id
    WHERE p.cliente_id = NEW.cliente_id AND pd.producto_id = NEW.producto_id;
    
    IF v_compro = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Solo compradores pueden resenar';
    END IF;
END //
DELIMITER ;


-- 2. PROCEDIMIENTOS ALMACENADOS (Lógica del Carrito)
DELIMITER //
-- Procedimiento para agregar producto al carrito
CREATE PROCEDURE sp_agregar_al_carrito(IN p_cliente_id INT, IN p_producto_id INT, IN p_cantidad INT)
BEGIN
    DECLARE v_carrito_id INT;
    
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

-- Procedimiento para convertir el carrito en Pedido
CREATE PROCEDURE sp_pasar_carrito_a_pedido(IN p_cliente_id INT, IN p_direccion_id INT, OUT p_pedido_id INT)
BEGIN
    DECLARE v_carrito_id INT;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    
    SELECT carrito_id INTO v_carrito_id 
    FROM Carrito 
    WHERE cliente_id = p_cliente_id AND estado = 'activo' LIMIT 1;
    
    IF v_carrito_id IS NOT NULL THEN
        SELECT SUM(p.precio * cd.cantidad) INTO v_total 
        FROM Carrito_Detalle cd 
        INNER JOIN Producto p ON cd.producto_id = p.producto_id 
        WHERE cd.carrito_id = v_carrito_id;
        
        INSERT INTO Pedido (cliente_id, direccion_id, estado, total) 
        VALUES (p_cliente_id, p_direccion_id, 'confirmado', v_total);
        
        SET p_pedido_id = LAST_INSERT_ID();
        
        INSERT INTO Pedido_Detalle (pedido_id, producto_id, cantidad, precio_unitario) 
        SELECT p_pedido_id, cd.producto_id, cd.cantidad, p.precio 
        FROM Carrito_Detalle cd 
        INNER JOIN Producto p ON cd.producto_id = p.producto_id 
        WHERE cd.carrito_id = v_carrito_id;
        
        UPDATE Carrito SET estado = 'convertido' WHERE carrito_id = v_carrito_id;
    END IF;
END //
DELIMITER ;