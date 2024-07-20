-- Mostrar triggers de la tabla pistas
SELECT * 
FROM sys.triggers
WHERE parent_id = OBJECT_ID('pistas');
GO

-- Mostrar el trigger animales_checkAdd_INSERT
SELECT * 
FROM sys.triggers
WHERE name = 'animales_checkAdd_INSERT';
GO
