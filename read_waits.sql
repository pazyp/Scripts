set lines 200
set pages 200
SELECT relative_fno, owner, segment_name, segment_type
FROM dba_extents
WHERE file_id = &file
AND &block BETWEEN block_id AND block_id + blocks - 1;
