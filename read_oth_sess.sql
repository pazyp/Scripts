set lines 200
set pages 200
SELECT p1 "file#", p2 "block#", p3 "class#"
FROM v$session_wait
WHERE event = 'read by other session';

