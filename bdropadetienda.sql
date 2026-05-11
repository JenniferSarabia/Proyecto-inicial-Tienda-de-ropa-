-- Base de datos: bdropadetienda
CREATE DATABASE IF NOT EXISTS bdropadetienda;
USE bdropadetienda;

-- 1. producto
CREATE TABLE producto (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  slug VARCHAR(160) UNIQUE,
  descripcion TEXT,
  precio DECIMAL(10,2) NOT NULL,
  precio_oferta DECIMAL(10,2),
  activo BOOLEAN DEFAULT TRUE,
  destacado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. categoria
CREATE TABLE categoria (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  id_padre INT NULL,
  nombre VARCHAR(100) NOT NULL,
  slug VARCHAR(110) UNIQUE,
  imagen_url VARCHAR(255),
  orden TINYINT DEFAULT 0,
  FOREIGN KEY (id_padre) REFERENCES categoria(id_categoria)
);

-- 3. variante
CREATE TABLE variante (
  id_variante INT AUTO_INCREMENT PRIMARY KEY,
  id_producto INT NOT NULL,
  talla VARCHAR(10),
  color VARCHAR(50),
  codigo_barras VARCHAR(50) UNIQUE,
  precio_extra DECIMAL(8,2) DEFAULT 0.00,
  activo BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

-- 4. imagen
CREATE TABLE imagen (
  id_imagen INT AUTO_INCREMENT PRIMARY KEY,
  id_producto INT NOT NULL,
  url VARCHAR(255) NOT NULL,
  alt VARCHAR(150),
  orden TINYINT DEFAULT 0,
  principal BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

-- 5. producto_categoria
CREATE TABLE producto_categoria (
  id_producto INT,
  id_categoria INT,
  PRIMARY KEY (id_producto, id_categoria),
  FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
  FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);

-- 6. cliente
CREATE TABLE cliente (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL,
  apellido VARCHAR(80) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  telefono VARCHAR(20),
  fecha_nacimiento DATE,
  genero ENUM('M','F','otro'),
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. direccion
CREATE TABLE direccion (
  id_direccion INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  alias VARCHAR(50),
  calle VARCHAR(200) NOT NULL,
  colonia VARCHAR(100),
  ciudad VARCHAR(100) NOT NULL,
  estado VARCHAR(80) NOT NULL,
  codigo_postal VARCHAR(10) NOT NULL,
  pais CHAR(2) DEFAULT 'MX',
  predeterminada BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

-- 8. pedido
CREATE TABLE pedido (
  id_pedido INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  estado ENUM('pendiente','pagado','enviado','entregado','cancelado') DEFAULT 'pendiente',
  canal ENUM('online','mostrador') DEFAULT 'online',
  subtotal DECIMAL(10,2) NOT NULL,
  descuento DECIMAL(10,2) DEFAULT 0.00,
  impuesto DECIMAL(10,2) DEFAULT 0.00,
  total DECIMAL(10,2) NOT NULL,
  notas TEXT,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

-- 9. detalle_pedido
CREATE TABLE detalle_pedido (
  id_detalle INT AUTO_INCREMENT PRIMARY KEY,
  id_pedido INT NOT NULL,
  id_variante INT NOT NULL,
  cantidad SMALLINT NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  descuento_linea DECIMAL(10,2) DEFAULT 0.00,
  subtotal_linea DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido),
  FOREIGN KEY (id_variante) REFERENCES variante(id_variante)
);

-- 10. pago
CREATE TABLE pago (
  id_pago INT AUTO_INCREMENT PRIMARY KEY,
  id_pedido INT NOT NULL,
  metodo ENUM('efectivo','tarjeta','transferencia','wallet') NOT NULL,
  monto DECIMAL(10,2) NOT NULL,
  estado ENUM('pendiente','aprobado','rechazado','reembolsado') DEFAULT 'pendiente',
  referencia VARCHAR(100),
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido)
);