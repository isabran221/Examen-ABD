USE zoologico;
GO

-- 1. No permitir añadir un animal si el tipo es 'León' y el número de años es mayor que 20
CREATE TRIGGER animales_checkAdd_INSERT
ON animales
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @tipo VARCHAR(50), @numero_años INT;
    SELECT @tipo = tipo, @numero_años = numero_años FROM inserted;
    IF @tipo = 'León' AND @numero_años > 20
    BEGIN
        RAISERROR('No se puede añadir un león de más de 20 años.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO animales (tipo, numero_años, artista_id)
        SELECT tipo, numero_años, artista_id FROM inserted;
    END
END;
GO

-- 2. Asignar el artista que cuida a menos animales a un nuevo animal
CREATE TRIGGER asignar_artista
ON animales
AFTER INSERT
AS
BEGIN
    DECLARE @artista_con_menor_animales INT;

    SELECT TOP 1 @artista_con_menor_animales = id
    FROM artistas
    ORDER BY (SELECT COUNT(*) FROM animales WHERE animales.artista_id = artistas.id) ASC;

    UPDATE animales
    SET artista_id = @artista_con_menor_animales
    WHERE id = (SELECT id FROM inserted);
END;
GO

-- 3. Actualizar ganancias en ATRACCIONES
CREATE TRIGGER actualiza_ganancias_insert
ON ATRACCION_DIA
AFTER INSERT
AS
BEGIN
    UPDATE ATRACCIONES
    SET ganancias = ganancias + inserted.ganancia
    FROM inserted
    WHERE ATRACCIONES.id = inserted.atraccion_id;
END;
GO

CREATE TRIGGER actualiza_ganancias_delete
ON ATRACCION_DIA
AFTER DELETE
AS
BEGIN
    UPDATE ATRACCIONES
    SET ganancias = ganancias - deleted.ganancia
    FROM deleted
    WHERE ATRACCIONES.id = deleted.atraccion_id;
END;
GO

CREATE TRIGGER actualiza_ganancias_update
ON ATRACCION_DIA
AFTER UPDATE
AS
BEGIN
    UPDATE ATRACCIONES
    SET ganancias = ganancias - deleted.ganancia + inserted.ganancia
    FROM deleted, inserted
    WHERE ATRACCIONES.id = inserted.atraccion_id;
END;
GO

-- 4. Contador de celebraciones en ATRACCIONES
CREATE TRIGGER incrementa_contador_insert
ON ATRACCION_DIA
AFTER INSERT
AS
BEGIN
    UPDATE ATRACCIONES
    SET contador = contador + 1
    FROM inserted
    WHERE ATRACCIONES.id = inserted.atraccion_id;
END;
GO

CREATE TRIGGER decrementa_contador_delete
ON ATRACCION_DIA
AFTER DELETE
AS
BEGIN
    UPDATE ATRACCIONES
    SET contador = contador - 1
    FROM deleted
    WHERE ATRACCIONES.id = deleted.atraccion_id;
END;
GO

-- 5. Validar aforo en pistas
CREATE TRIGGER check_aforo_insert
ON pistas
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @aforo INT;
    SELECT @aforo = aforo FROM inserted;
    IF @aforo > 1000 OR @aforo < 10
    BEGIN
        RAISERROR('El aforo debe estar entre 10 y 1000.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO pistas (nombre_pista, aforo)
        SELECT nombre_pista, aforo FROM inserted;
    END
END;
GO

CREATE TRIGGER check_aforo_update
ON pistas
INSTEAD OF UPDATE
AS
BEGIN
    DECLARE @aforo INT;
    SELECT @aforo = aforo FROM inserted;
    IF @aforo > 1000 OR @aforo < 10
    BEGIN
        RAISERROR('El aforo debe estar entre 10 y 1000.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        UPDATE pistas
        SET nombre_pista = inserted.nombre_pista, aforo = inserted.aforo
        FROM inserted
        WHERE pistas.id = inserted.id;
    END
END;
GO

-- 6. Cambiar nif_jefe a NULL si no existe
CREATE TRIGGER check_nif_jefe_insert
ON artistas
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @nif_jefe INT;
    SELECT @nif_jefe = nif_jefe FROM inserted;
    IF (SELECT COUNT(*) FROM artistas WHERE id = @nif_jefe) = 0
    BEGIN
        SET @nif_jefe = NULL;
    END
    INSERT INTO artistas (nif_jefe, nombre)
    SELECT @nif_jefe, nombre FROM inserted;
END;
GO

-- 7. Registrar operaciones en la tabla PISTAS
CREATE TRIGGER registro_alta_pista
ON pistas
AFTER INSERT
AS
BEGIN
    INSERT INTO REGISTRO (usuario, tabla, operacion, datos_antiguos, datos_nuevos, fecha_hora)
    VALUES (SYSTEM_USER, 'PISTAS', 'ALTA', NULL, (SELECT nombre_pista + ':' + CAST(aforo AS VARCHAR) FROM inserted), GETDATE());
END;
GO

CREATE TRIGGER registro_baja_pista
ON pistas
AFTER DELETE
AS
BEGIN
    INSERT INTO REGISTRO (usuario, tabla, operacion, datos_antiguos, datos_nuevos, fecha_hora)
    VALUES (SYSTEM_USER, 'PISTAS', 'BAJA', (SELECT nombre_pista + ':' + CAST(aforo AS VARCHAR) FROM deleted), NULL, GETDATE());
END;
GO

CREATE TRIGGER registro_modificacion_pista
ON pistas
AFTER UPDATE
AS
BEGIN
    INSERT INTO REGISTRO (usuario, tabla, operacion, datos_antiguos, datos_nuevos, fecha_hora)
    VALUES (SYSTEM_USER, 'PISTAS', 'MODIFICAR', (SELECT nombre_pista + ':' + CAST(aforo AS VARCHAR) FROM deleted), (SELECT nombre_pista + ':' + CAST(aforo AS VARCHAR) FROM inserted), GETDATE());
END;
GO

-- 8. Actualizar el contador de pistas y animales
CREATE TRIGGER actualiza_contador_pistas
ON pistas
AFTER INSERT
AS
BEGIN
    UPDATE CONTADOR
    SET valor = valor + 1
    WHERE tipo = 'pistas';
END;
GO

CREATE TRIGGER actualiza_contador_baja_pistas
ON pistas
AFTER DELETE
AS
BEGIN
    UPDATE CONTADOR
    SET valor = valor - 1
    WHERE tipo = 'pistas';
END;
GO

CREATE TRIGGER actualiza_contador_animales
ON animales
AFTER INSERT
AS
BEGIN
    UPDATE CONTADOR
    SET valor = valor + 1
    WHERE tipo = 'animales';
END;
GO

CREATE TRIGGER actualiza_contador_baja_animales
ON animales
AFTER DELETE
AS
BEGIN
    UPDATE CONTADOR
    SET valor = valor - 1
    WHERE tipo = 'animales';
END;
GO
