-- Migration: create_table
-- Created at: 2017-01-28 22:39:14
-- ====  UP  ====

BEGIN;

PRAGMA foreign_keys = ON;

CREATE TABLE
	testing
(
	id	   integer   primary key
	, code     text      not null unique
	, name     text
	, created  integer   current_time
);

COMMIT;

-- ==== DOWN ====

BEGIN;

DROP TABLE
	testing;

COMMIT;
