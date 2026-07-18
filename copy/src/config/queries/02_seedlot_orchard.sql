--------------------------------------------------------------------------------
-- spar.seedlot_orchard  <-  THE.seedlot (orchard_id / secondary_orchard_id)
--------------------------------------------------------------------------------
-- Oracle keeps the primary/secondary orchard as two columns on THE.seedlot.
-- Postgres normalises them into spar.seedlot_orchard, one row per orchard with
-- a primary_ind flag. We unpivot the two Oracle columns into (up to) two rows,
-- skipping nulls.
--
-- NOTE: verify the spar.seedlot_orchard column list against the live schema.
-- The columns below (audit + revision_count) are inferred from the sync tool's
-- usage of spar.seedlot_orchard; adjust if the real table differs.
--------------------------------------------------------------------------------
SELECT
     s.seedlot_number                                   AS seedlot_number
   , s.orchard_id                                       AS orchard_id
   , 'true'                                             AS primary_ind
   , REPLACE(s.entry_userid, '@', '\')                  AS entry_userid
   , CAST(FROM_TZ(CAST(s.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(s.update_userid, '@', '\')                 AS update_userid
   , CAST(FROM_TZ(CAST(s.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , s.revision_count                                   AS revision_count
FROM the.seedlot s
WHERE s.seedlot_number = :seedlot_number
  AND s.orchard_id IS NOT NULL
UNION ALL
SELECT
     s.seedlot_number                                   AS seedlot_number
   , s.secondary_orchard_id                             AS orchard_id
   , 'false'                                            AS primary_ind
   , REPLACE(s.entry_userid, '@', '\')                  AS entry_userid
   , CAST(FROM_TZ(CAST(s.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(s.update_userid, '@', '\')                 AS update_userid
   , CAST(FROM_TZ(CAST(s.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , s.revision_count                                   AS revision_count
FROM the.seedlot s
WHERE s.seedlot_number = :seedlot_number
  AND s.secondary_orchard_id IS NOT NULL
