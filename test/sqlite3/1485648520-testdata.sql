-- Migration: testdata
-- Created at: 2017-01-28 19:08:40
-- ====  UP  ====

BEGIN;
PRAGMA foreign_keys = ON;

INSERT INTO testing (code, name) VALUES ('QB' , 'Tom Brady');
INSERT INTO testing (code, name) VALUES ('TE' , 'Ben Coates');
INSERT INTO testing (code, name) VALUES ('CB' , 'Raymond Clayborn');
INSERT INTO testing (code, name) VALUES ('G' ,  'John (Hog) Hannah');

COMMIT;

-- ==== DOWN ====

BEGIN;

DELETE FROM testing;

COMMIT;
