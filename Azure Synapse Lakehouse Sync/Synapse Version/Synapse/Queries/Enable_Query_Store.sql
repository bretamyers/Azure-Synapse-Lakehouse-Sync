-- Enable Synapse Dedicated SQL Query Store

DECLARE @Query VARCHAR(MAX);
SET @Query = 'ALTER DATABASE ' + DB_NAME() + ' SET QUERY_STORE = ON';
EXEC (@Query);