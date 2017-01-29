-- Migration: create_table
-- Created at: 2017-01-28 22:39:14
-- ====  UP  ====

BEGIN;

CREATE TABLE
	testing
(
	id	   integer
	, code     varchar(200)
	, name     varchar(200)
);

COMMIT;

-- ==== DOWN ====

BEGIN;

DROP TABLE
	testing;

COMMIT;
