--------------------------------------------------------------------------------
-- spar.seedlot_collection_method  <-  THE.seedlot (cone_collection_method codes)
--------------------------------------------------------------------------------
-- Oracle keeps up to two cone-collection-method codes as columns on THE.seedlot
-- (CONE_COLLECTION_METHOD_CODE / CONE_COLLECTION_METHOD2_CODE), zero-padded
-- chars such as '07'. Postgres normalises them into spar.seedlot_collection_method
-- as numeric codes, one row each. We unpivot and convert '07' -> 7.
--
-- NOTE: verify the spar.seedlot_collection_method column list against the live
-- schema. The columns below are inferred from the sync tool's usage; adjust if
-- the real table differs.
--------------------------------------------------------------------------------
SELECT
     s.seedlot_number                                   AS seedlot_number
   , TO_NUMBER(s.cone_collection_method_code)           AS cone_collection_method_code
   , REPLACE(s.entry_userid, '@', '\')                  AS entry_userid
   , CAST(FROM_TZ(CAST(s.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(s.update_userid, '@', '\')                 AS update_userid
   , CAST(FROM_TZ(CAST(s.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , s.revision_count                                   AS revision_count
FROM the.seedlot s
WHERE s.seedlot_number = :seedlot_number
  AND s.cone_collection_method_code IS NOT NULL
UNION ALL
SELECT
     s.seedlot_number                                   AS seedlot_number
   , TO_NUMBER(s.cone_collection_method2_code)          AS cone_collection_method_code
   , REPLACE(s.entry_userid, '@', '\')                  AS entry_userid
   , CAST(FROM_TZ(CAST(s.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(s.update_userid, '@', '\')                 AS update_userid
   , CAST(FROM_TZ(CAST(s.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , s.revision_count                                   AS revision_count
FROM the.seedlot s
WHERE s.seedlot_number = :seedlot_number
  AND s.cone_collection_method2_code IS NOT NULL
