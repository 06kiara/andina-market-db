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
    FOREIGN KEY (cliente_id) REFERENCES Cliente(cliente_id) ON DELETE CASCADE
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
    FOREIGN KEY (categoria_id) REFERENCES Categoria(categoria_id)
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
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id)
);

CREATE TABLE Pedido (
    pedido_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    direccion_id INT NOT NULL,
    estado ENUM('pendiente','confirmado','enviado','entregado','cancelado') NOT NULL DEFAULT 'pendiente',
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (cliente_id) REFERENCES Cliente(cliente_id),
    FOREIGN KEY (direccion_id) REFERENCES Direccion(direccion_id)
);

CREATE TABLE Pedido_Detalle (
    pedido_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (pedido_id, producto_id),
    FOREIGN KEY (pedido_id) REFERENCES Pedido(pedido_id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id)
);

CREATE TABLE Pago (
    pago_id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    fecha_pago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente','aprobado','rechazado','reembolsado') NOT NULL DEFAULT 'pendiente',
    tipo_pago ENUM('tarjeta','yape_plin','transferencia','contraentrega') NOT NULL,
    FOREIGN KEY (pedido_id) REFERENCES Pedido(pedido_id),
    UNIQUE KEY uk_pago_pedido (pedido_id)
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
    pedido_id INT NOT NULL,
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
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id) ON DELETE CASCADE
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

INSERT INTO Pedido (cliente_id, direccion_id, estado, total) VALUES
(1, 1, 'confirmado', 300.00),
(2, 3, 'confirmado', 249.90),
(3, 4, 'pendiente', 65.00);

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
(2, '912345678', 'YAP-20250510-001', 'yape');

INSERT INTO Pago (pedido_id, monto, estado, tipo_pago) VALUES
(3, 65.00, 'pendiente', 'contraentrega');
INSERT INTO Pago_Contraentrega (pago_id, monto_recibido, fecha_entrega_real) VALUES
(3, NULL, NULL);