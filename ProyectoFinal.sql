/*
PROYECTO DE BASES DATOS
INDUSTRIA DIRIGIDA: HOTELES
*/

/*CREACIÓN DE LA BASE DE DATOS*/

Create database CertficacionHoteles;

Use CertficacionHoteles;

Create Table Cliente 
(
	ID_Cliente int IDENTITY(1,1) PRIMARY KEY,
	Nombre varchar(40) NOT NULL,
	EstadoProcedencia varchar(30) NOT NULL,
	Municipio varchar(30) NOT NULL,
);

Create Table Requerimiento
(
	ID_Requerimiento int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	AreaHotel varchar(40) NOT NULL,
	NombreRequerimiento varchar(20) NOT NULL,
	EspecficiacionRequerimiento varchar(250) NOT NULL
);

Create Table ProcesoCertificacion 
(
	ID_Certificacion int IDENTITY(1,1) PRIMARY KEY,
	ID_Cliente int FOREIGN KEY REFERENCES Cliente(ID_Cliente),
	FechaInicioProceso date NOT NULL,
	FechaFinProceso date, 
	CertificacionCompletada bit NOT NULL, 
	ComentariosGenerales varchar(250),

	Constraint DateConstraint CHECK (FechaInicioProceso >= '2020-01-01' AND FechaFinProceso >= FechaInicioProceso)
);

Alter Table ProcesoCertificacion
Alter Column FechaFinProceso date NULL;

Create Table DetalleProceso 
(
	ID_Certificacion int NOT NULL REFERENCES ProcesoCertificacion(ID_Certificacion),
	ID_Requerimiento int NOT NULL REFERENCES Requerimiento(ID_Requerimiento),
	PRIMARY KEY (ID_Requerimiento, ID_Certificacion),
	
	FechaInicioRequerimiento date NOT NULL,
	FechaFinRequerimiento date,
	RequerimientoCompletado bit NOT NULL,

	Constraint DateRequirementConstraint check (FechaInicioRequerimiento >= '2020-01-01' AND FechaFinRequerimiento >= FechaInicioRequerimiento)
);

/*IMPLEMENTACIÓN DE LOS QUERYS*/

/*1. ¿Cuál es el requerimiento que menos se ha cumplido?*/
Select NombreRequerimiento
From Requerimiento
Where ID_Requerimiento IN (
	Select ID_Requerimiento
	From DetalleProceso
	Group by ID_Requerimiento
	Having count(*) <= ALL (
		Select count(*)
		From DetalleProceso
		Group By ID_Requerimiento
		))

/*1.5 ¿Cuál es el requerimiento que menos se ha cumplido en 'x' mes?*/
Select NombreRequerimiento as Nombre 
From Requerimiento
Where ID_Requerimiento IN (
	Select ID_Requerimiento
	From DetalleProceso
	Where MONTH(FechaFinRequerimiento) = '5'
	Group by ID_Requerimiento
	Having count(*) <= ALL (
		Select count(*)
		From DetalleProceso
		Group By ID_Requerimiento
		))

/*2. ¿Cuál es el requerimiento que más se ha cumplido?*/
Select NombreRequerimiento
From Requerimiento
Where ID_Requerimiento IN (
	Select ID_Requerimiento
	From DetalleProceso
	Group by ID_Requerimiento
	Having count(*) >= ALL (
		Select count(*)
		From DetalleProceso
		Group By ID_Requerimiento
		))

/*2.5 ¿Cuál es el requerimiento que menos se ha cumplido en determinada región?*/
Select NombreRequerimiento as Nombre 
From Requerimiento
Where ID_Requerimiento IN (
	Select ID_Requerimiento
	From DetalleProceso
	Group by ID_Requerimiento
	Having count(*) >= ALL (
		Select count(*)
		From DetalleProceso
		Where ID_Certificacion IN (
			Select ID_Certificacion
			From ProcesoCertificacion 
			Where ID_Cliente IN (
					Select ID_Cliente
					From Cliente
					Where EstadoProcedencia = 'Estado de México'))
		Group By ID_Requerimiento
		))
			
/*3. ¿Cuál es el estado de solicitud del hotel 'nombreCliente'?*/
Select CertificacionCompletada as Estado, ComentariosGenerales as Detalles 
From ProcesoCertificacion
Where ID_Cliente IN (
	Select ID_Cliente
	From Cliente
	Where Nombre = 'Crowne Plaza'
	)

/*4. ¿Cuál es la ubicación del hotel que cumple con determinadoRequerimiento?*/
Select EstadoProcedencia as Estado, Municipio as Municipio
From Cliente
Where ID_Cliente IN (
		Select ID_Cliente
		From ProcesoCertificacion
		Where ID_Certificacion IN (
				Select ID_Certificacion
				From DetalleProceso
				Where RequerimientoCompletado = 1 AND ID_Requerimiento IN (
						Select ID_Requerimiento
						From Requerimiento
						Where NombreRequerimiento = 'Inodoro'
						)))

/*5. ¿Cuál es la ubicación del hotel que NO cumple con determinadoRequerimiento?*/
Select EstadoProcedencia as Estado, Municipio as Municipio
From Cliente
Where ID_Cliente IN (
		Select ID_Cliente
		From ProcesoCertificacion
		Where ID_Certificacion IN (
				Select ID_Certificacion
				From DetalleProceso
				Where RequerimientoCompletado = 0 AND ID_Requerimiento IN (
						Select ID_Requerimiento
						From Requerimiento
						Where NombreRequerimiento = 'Pasillo'
						)))

/*6. ¿Cuántos y cuáles hoteles han iniciado el proceso de certificación en el mes 'x' dentro del Estado 'x'?*/		
Select Nombre as Nombre_del_hotel, count(*) as Cantidad
from Cliente
Where EstadoProcedencia = 'Estado de México' AND ID_Cliente IN (
		Select ID_Cliente
		From ProcesoCertificacion
		Where MONTH(FechaInicioProceso) = '6'
		)
Group by Nombre

/*7. ¿Cuáles hoteles tienen su solicitud terminada y cuál es el mes en que concluyó?*/
Select Nombre as Hotel, DATENAME(MONTH, FechaFinProceso) as FechaFinal
From Cliente h, ProcesoCertificacion c, DetalleProceso d 
Where h.ID_Cliente = c.ID_Cliente AND c.ID_Certificacion = d.ID_Certificacion
	  AND c.CertificacionCompletada = 1
Group by Nombre, DATENAME(MONTH, FechaFinProceso)

/*IMPLEMENTACIÓN DE PROCEDIMIENTOS*/

/*1. Procedimiento Query #1*/
Create PROCEDURE Menos_Cumplido
AS
	Declare @x varchar(20);
	Select @x = NombreRequerimiento
				From Requerimiento
				Where ID_Requerimiento IN (
						Select ID_Requerimiento
						From DetalleProceso
						Group by ID_Requerimiento
						Having count(*) <= ALL (
								Select count(*)
								From DetalleProceso
								Group By ID_Requerimiento
								))
	print('El requerimiento que menos se cumple es: ' + @x);
GO
Execute Menos_Cumplido;

/*2. Procedimiento Query #1.5*/
Create PROCEDURE Menos_Cumplido_Por_Mes (@Mes int)
AS
	Declare @x varchar(20);
	Declare @y nvarchar(20);
	Select @x = NombreRequerimiento 
				From Requerimiento
				Where ID_Requerimiento IN (
					Select ID_Requerimiento
					From DetalleProceso
					Where MONTH(FechaFinRequerimiento) = @Mes
					Group by ID_Requerimiento
					Having count(*) <= ALL (
						Select count(*)
						From DetalleProceso
						Group By ID_Requerimiento
						));

	Select @y = DATENAME(MONTH, FechaFinRequerimiento)
				From DetalleProceso
				Where MONTH(FechaFinRequerimiento) = @Mes
				

	print('El requerimiento que menos se cumple en el mes: ' + @y + 'es: ' + @x);
GO

Execute Menos_Cumplido_Por_Mes 5;

/*3. Procedimiento Query #2*/
Create PROCEDURE Mas_Cumplido
AS 
	Declare @x varchar(20);
	Select @x = NombreRequerimiento
				From Requerimiento
				Where ID_Requerimiento IN (
					Select ID_Requerimiento
					From DetalleProceso
					Group by ID_Requerimiento
					Having count(*) >= ALL (
						Select count(*)
						From DetalleProceso
						Group By ID_Requerimiento
						));
	print('El requerimiento que más se cumple es: ' + @x);
GO

Execute Mas_Cumplido

/*4. Procedimiento Query #2.5*/
Create PROCEDURE Mas_Cumplido_En (@Estado varchar(20))
AS
	Declare @x varchar(20);
	Select @x = NombreRequerimiento
				From Requerimiento
				Where ID_Requerimiento IN (
					Select ID_Requerimiento
					From DetalleProceso
					Group by ID_Requerimiento
					Having count(*) >= ALL (
						Select count(*)
						From DetalleProceso
						Where ID_Certificacion IN (
							Select ID_Certificacion
							From ProcesoCertificacion 
							Where ID_Cliente IN (
									Select ID_Cliente
									From Cliente
									Where EstadoProcedencia = @Estado))
						Group By ID_Requerimiento
						));
	print('El requerimiento que más se cumple en ' + @Estado + ' es: ' + @x);
GO

Execute Mas_Cumplido_En 'CDMX'

/*5. Procedimiento Query #3*/
Create PROCEDURE Estado_Hotel (@Hotel varchar(50))
AS
	Declare @x bit
	Declare @y varchar(15)
	Select @x = CertificacionCompletada
				From ProcesoCertificacion
				Where ID_Cliente IN (
					Select ID_Cliente
					From Cliente
					Where Nombre = @Hotel
					);
	If (@x = 1)
	BEGIN 
		Set @y = 'Completado';
	END
	Else
	BEGIN
		Set @y = 'Incompleto';
	END
	print('El estado de la certificación del hotel ' + @Hotel + ' es: ' + @y);
GO

Execute Estado_Hotel 'Crowne Plaza'

/*6. Procedimiento Query #4*/
Create PROCEDURE  Ubicacion_Requerimiento_Completado (@Requerimiento varchar(20))
AS
	Declare @x varchar(20);
	Select @x = EstadoProcedencia
				From Cliente
				Where ID_Cliente IN (
						Select ID_Cliente
						From ProcesoCertificacion
						Where ID_Certificacion IN (
								Select ID_Certificacion
								From DetalleProceso
								Where RequerimientoCompletado = 1 AND ID_Requerimiento IN (
										Select ID_Requerimiento
										From Requerimiento
										Where NombreRequerimiento = @Requerimiento
										)));
	print('El requerimiento ' + @Requerimiento + ' se cumplió en el estado: ' + @x);
GO

Execute Ubicacion_Requerimiento_Completado 'Inodoro'

/*7. Procedimiento Query #5*/
Create PROCEDURE  Ubicacion_Requerimiento_Incompleto (@Requerimiento varchar(20))
AS
	Declare @x varchar(20);
	Select @x = EstadoProcedencia
				From Cliente
				Where ID_Cliente IN (
						Select ID_Cliente
						From ProcesoCertificacion
						Where ID_Certificacion IN (
								Select ID_Certificacion
								From DetalleProceso
								Where RequerimientoCompletado = 0 AND ID_Requerimiento IN (
										Select ID_Requerimiento
										From Requerimiento
										Where NombreRequerimiento = @Requerimiento
										)));
	print('El requerimiento ' + @Requerimiento + ' no se cumplió en el estado: ' + @x);
GO

Execute Ubicacion_Requerimiento_Incompleto 'Pasillo'

/*8. Procedimiento Query #6*/
Create PROCEDURE Hoteles_A_Certificar_En_Mes (@Mes int)
AS
	Declare @Hotel varchar(50);
	Declare @Cantidad int;

	Declare @Hoteles_Cursor CURSOR;
	SET @Hoteles_Cursor = Cursor for Select Nombre, count(*) 
						  from Cliente
						  Where EstadoProcedencia = 'Estado de México' AND ID_Cliente IN (
								Select ID_Cliente
								From ProcesoCertificacion
								Where MONTH(FechaInicioProceso) = @Mes
								)
						  Group by Nombre
	
	OPEN @Hoteles_Cursor 
		FETCH Next From @Hoteles_Cursor INTO @Hotel, @Cantidad
			print('Están en proceso de certificar' + str(@Cantidad));
			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				print('El hotel ' + @Hotel + ' está en proceso')
			FETCH Next From @Hoteles_Cursor INTO @Hotel, @Cantidad 
			END
	CLOSE @Hoteles_Cursor

Deallocate @Hoteles_Cursor 

Execute Hoteles_A_Certificar_En_Mes 6

/*9. Procedimiento Query #7*/
Create PROCEDURE  Hotel_Certificado
AS
	Declare @Hotel varchar(50);
	Declare @Fecha nvarchar(10);

	Declare @Hotel_Cursor CURSOR;
	Set @Hotel_Cursor = Cursor for Select  Nombre, DATENAME(MONTH, FechaFinProceso)
						From Cliente h, ProcesoCertificacion c, DetalleProceso d 
						Where h.ID_Cliente = c.ID_Cliente AND c.ID_Certificacion = d.ID_Certificacion
							  AND c.CertificacionCompletada = 1
						Group by Nombre, DATENAME(MONTH, FechaFinProceso)
	
	OPEN @Hotel_cursor
		FETCH Next From @Hotel_Cursor INTO @Hotel, @Fecha
			WHILE(@@FETCH_STATUS = 0) 
		BEGIN 
			print('El nombre del Hotel certficiado es: ' + @Hotel);
			print('El mes en el que se certificó fue: ' + @Fecha);
			FETCH Next From @Hotel_Cursor INTO @Hotel, @Fecha	
		END
	CLOSE @Hotel_Cursor

Deallocate @Hotel_Cursor

Execute Hotel_Certificado
