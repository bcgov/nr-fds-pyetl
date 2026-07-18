--------------------------------------------------------------------------------
-- spar.seedlot_genetic_worth  <-  THE.seedlot_genetic_worth
--------------------------------------------------------------------------------
-- Oracle GENETIC_WORTH_RTNG maps to Postgres genetic_quality_value.
--------------------------------------------------------------------------------
SELECT
     s.seedlot_number                                   AS seedlot_number
   , s.genetic_worth_code                               AS genetic_worth_code
   , s.genetic_worth_rtng                               AS genetic_quality_value
   , REPLACE(s.entry_userid, '@', '\')                  AS entry_userid
   , CAST(FROM_TZ(CAST(s.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(s.update_userid, '@', '\')                 AS update_userid
   , CAST(FROM_TZ(CAST(s.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , s.revision_count                                   AS revision_count
FROM the.seedlot_genetic_worth s
WHERE s.seedlot_number = :seedlot_number
