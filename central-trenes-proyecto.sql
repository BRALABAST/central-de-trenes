-- Crear base de datos
CREATE DATABASE central_trenes;

-- Conectar a la base de datos
\c central_trenes;

-- Tabla de Estaciones
CREATE TABLE Estaciones (
    id_estacion SERIAL PRIMARY KEY,
    nombre_estacion VARCHAR(100) NOT NULL,
    ubicacion VARCHAR(200),
    codigo_postal VARCHAR(10),
    ciudad VARCHAR(100),
    pais VARCHAR(100)
);

-- Tabla de Trenes
CREATE TABLE Trenes (
    id_tren SERIAL PRIMARY KEY,
    modelo VARCHAR(100) NOT NULL,
    capacidad_pasajeros INTEGER NOT NULL,
    año_fabricacion INTEGER,
    tipo_tren VARCHAR(50),  -- (de alta velocidad, regional, de carga, etc.)
    estado VARCHAR(50)  -- (activo, mantenimiento, inactivo)
);

-- Tabla de Rutas
CREATE TABLE Rutas (
    id_ruta SERIAL PRIMARY KEY,
    nombre_ruta VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- Tabla de Detalles de Ruta (orden de estaciones)
CREATE TABLE DetallesRuta (
    id_detalle_ruta SERIAL PRIMARY KEY,
    id_ruta INTEGER REFERENCES Rutas(id_ruta),
    id_estacion INTEGER REFERENCES Estaciones(id_estacion),
    orden_estacion INTEGER NOT NULL,
    tiempo_llegada_estimado TIME,
    tiempo_salida_estimado TIME,
    distancia_km DECIMAL(10,2)
);

-- Tabla de Horarios de Trenes
CREATE TABLE Horarios (
    id_horario SERIAL PRIMARY KEY,
    id_tren INTEGER REFERENCES Trenes(id_tren),
    id_ruta INTEGER REFERENCES Rutas(id_ruta),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    dia_semana VARCHAR(20),
    hora_salida TIME NOT NULL,
    hora_llegada TIME NOT NULL
);

-- Tabla de Viajes
CREATE TABLE Viajes (
    id_viaje SERIAL PRIMARY KEY,
    id_horario INTEGER REFERENCES Horarios(id_horario),
    fecha_viaje DATE NOT NULL,
    estado_viaje VARCHAR(50),  -- (programado, en progreso, completado, cancelado)
    observaciones TEXT
);

-- Tabla de Llegadas a Estaciones
CREATE TABLE LlegadasEstaciones (
    id_llegada SERIAL PRIMARY KEY,
    id_viaje INTEGER REFERENCES Viajes(id_viaje),
    id_estacion INTEGER REFERENCES Estaciones(id_estacion),
    hora_llegada_real TIMESTAMP,
    hora_salida_real TIMESTAMP,
    retraso_minutos INTEGER,
    estado_llegada VARCHAR(50)  -- (a tiempo, con retraso, adelantado)
);

-- Insertar datos de ejemplo para Estaciones (14 estaciones)
INSERT INTO Estaciones (nombre_estacion, ubicacion, ciudad, pais) VALUES
('Barcelona Sants', 'Plaça dels Països Catalans', 'Barcelona', 'España'),
('Madrid Atocha', 'Glorieta del Emperador Carlos V', 'Madrid', 'España'),
('Valencia Joaquín Sorolla', 'Calle Xàtiva', 'Valencia', 'España'),
('Sevilla Santa Justa', 'Calle Almirante Lobo', 'Sevilla', 'España'),
('Zaragoza Delicias', 'Avenida de Navarra', 'Zaragoza', 'España'),
('Málaga María Zambrano', 'Plaza de la Solidaridad', 'Málaga', 'España'),
('Alicante Terminal', 'Avenida Padre Esplá', 'Alicante', 'España'),
('Girona', 'Plaça d''Ernest Lluch', 'Girona', 'España'),
('Bilbao Abando', 'Plaza Circular', 'Bilbao', 'España'),
('San Sebastián', 'Paseo de Francia', 'San Sebastián', 'España'),
('Córdoba Central', 'Avenida de los Mozárabes', 'Córdoba', 'España'),
('Tarragona', 'Plaza Imperial Tarraco', 'Tarragona', 'España'),
('Granada', 'Explanada de la Estación', 'Granada', 'España'),
('Palma de Mallorca', 'Plaza de España', 'Palma de Mallorca', 'España');

-- Funciones adicionales

-- Función para calcular el retraso de un tren
CREATE OR REPLACE FUNCTION calcular_retraso(
    hora_programada TIME, 
    hora_real TIMESTAMP
) RETURNS INTEGER AS $$
DECLARE
    retraso_minutos INTEGER;
BEGIN
    retraso_minutos := EXTRACT(HOUR FROM hora_real - hora_programada::TIMESTAMP) * 60 +
                       EXTRACT(MINUTE FROM hora_real - hora_programada::TIMESTAMP);
    RETURN ABS(retraso_minutos);
END;
$$ LANGUAGE plpgsql;

-- Vista de resumen de viajes
CREATE OR REPLACE VIEW resumen_viajes AS
SELECT 
    v.id_viaje,
    h.id_ruta,
    t.id_tren,
    t.modelo AS modelo_tren,
    h.fecha_inicio,
    h.fecha_fin,
    v.fecha_viaje,
    v.estado_viaje,
    (SELECT COUNT(*) FROM LlegadasEstaciones le WHERE le.id_viaje = v.id_viaje) AS estaciones_visitadas
FROM 
    Viajes v
JOIN 
    Horarios h ON v.id_horario = h.id_horario
JOIN 
    Trenes t ON h.id_tren = t.id_tren;

-- Índices para mejorar el rendimiento
CREATE INDEX idx_horarios_tren ON Horarios(id_tren);
CREATE INDEX idx_horarios_ruta ON Horarios(id_ruta);
CREATE INDEX idx_llegadas_viaje ON LlegadasEstaciones(id_viaje);
CREATE INDEX idx_llegadas_estacion ON LlegadasEstaciones(id_estacion);
