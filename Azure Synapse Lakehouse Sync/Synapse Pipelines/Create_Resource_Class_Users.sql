-- Parquet Auto Loader
-- Create Users for different Resource Classes

IF NOT EXISTS(SELECT name FROM sys.database_principals WHERE name = 'Userstaticrc10') BEGIN
    CREATE USER Userstaticrc10 FOR LOGIN Userstaticrc10; 
    EXEC sp_addrolemember 'db_owner', 'Userstaticrc10';
    EXEC sp_addrolemember 'staticrc10', Userstaticrc10;
END
GO

IF NOT EXISTS(SELECT name FROM sys.database_principals WHERE name = 'Userstaticrc20') BEGIN
    CREATE USER Userstaticrc20 FOR LOGIN Userstaticrc20;
    EXEC sp_addrolemember 'db_owner', 'Userstaticrc20';
    EXEC sp_addrolemember 'staticrc20', Userstaticrc20;
END
GO

IF NOT EXISTS(SELECT name FROM sys.database_principals WHERE name = 'Userstaticrc30') BEGIN
    CREATE USER Userstaticrc30 FOR LOGIN Userstaticrc30;
    EXEC sp_addrolemember 'db_owner', 'Userstaticrc30';
    EXEC sp_addrolemember 'staticrc30', Userstaticrc30;
END
GO

IF NOT EXISTS(SELECT name FROM sys.database_principals WHERE name = 'Userstaticrc40') BEGIN
    CREATE USER Userstaticrc40 FOR LOGIN Userstaticrc40;
    EXEC sp_addrolemember 'db_owner', 'Userstaticrc40';
    EXEC sp_addrolemember 'staticrc40', Userstaticrc40;
END
GO

IF NOT EXISTS(SELECT name FROM sys.database_principals WHERE name = 'Userstaticrc50') BEGIN
    CREATE USER Userstaticrc50 FOR LOGIN Userstaticrc50;
    EXEC sp_addrolemember 'db_owner', 'Userstaticrc50';
    EXEC sp_addrolemember 'staticrc50', Userstaticrc50;
END
GO

IF NOT EXISTS(SELECT name FROM sys.database_principals WHERE name = 'Userstaticrc60') BEGIN
    CREATE USER Userstaticrc60 FOR LOGIN Userstaticrc60;
    EXEC sp_addrolemember 'db_owner', 'Userstaticrc60';
    EXEC sp_addrolemember 'staticrc60', Userstaticrc60;
END
GO

IF NOT EXISTS(SELECT name FROM sys.database_principals WHERE name = 'Userstaticrc70') BEGIN
    CREATE USER Userstaticrc70 FOR LOGIN Userstaticrc70;
    EXEC sp_addrolemember 'db_owner', 'Userstaticrc70';
    EXEC sp_addrolemember 'staticrc70', Userstaticrc70;
END
GO

IF NOT EXISTS(SELECT name FROM sys.database_principals WHERE name = 'Userstaticrc80') BEGIN
    CREATE USER Userstaticrc80 FOR LOGIN Userstaticrc80;
    EXEC sp_addrolemember 'db_owner', 'Userstaticrc80';
    EXEC sp_addrolemember 'staticrc80', Userstaticrc80;
END
GO
