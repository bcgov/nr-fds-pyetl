--------------------------------------------------------------------------------
-- spar.seedlot_seed_plan_zone  <-  THE.seedlot_plan_zone
--------------------------------------------------------------------------------
-- Reverse of config/SQL/SPAR/POSTGRES_SEEDLOT_SEED_PLAN_ZONE_EXTRACT.sql.
-- Target columns confirmed against bcgov/nr-spar common/init_db/init.sql.
--   * primary_ind: Oracle Y/N char -> Postgres boolean (default false)
--   * entry_userid / update_userid: "Provider@User" -> "Provider\User"
--   * entry_timestamp / update_timestamp: America/Los_Angeles -> UTC
--------------------------------------------------------------------------------
SELECT
     spz.seedlot_number                                 AS seedlot_number
   , spz.seed_plan_zone_code                            AS seed_plan_zone_code
   , CASE WHEN spz.primary_ind = 'Y' THEN 'true' ELSE 'false' END AS primary_ind
   , REPLACE(spz.entry_userid, '@', '\')                AS entry_userid
   , CAST(FROM_TZ(CAST(spz.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   -- THE.seedlot_plan_zone has no update_* columns; inherit from the parent seedlot.
   , REPLACE(sl.update_userid, '@', '\')                AS update_userid
   , CAST(FROM_TZ(CAST(sl.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , spz.revision_count                                 AS revision_count
FROM the.seedlot_plan_zone spz
JOIN the.seedlot sl
  ON sl.seedlot_number = spz.seedlot_number
WHERE spz.seedlot_number = :seedlot_number
