CREATE TABLE THE.SEEDLOT (
	SEEDLOT_NUMBER VARCHAR2(5),
	SEEDLOT_STATUS_CODE VARCHAR2(3),
	VEGETATION_CODE VARCHAR2(8),
	GENETIC_CLASS_CODE VARCHAR2(1),
	COLLECTION_SOURCE_CODE VARCHAR2(2),
	SUPERIOR_PRVNC_IND VARCHAR2(1),
	ORG_UNIT_NO NUMBER(10,0),
	REGISTERED_SEED_IND VARCHAR2(1),
	TO_BE_REGISTRD_IND VARCHAR2(1),
	REGISTERED_DATE DATE,
	FS721A_SIGNED_IND VARCHAR2(1),
	BC_SOURCE_IND VARCHAR2(1),
	NAD_DATUM_CODE VARCHAR2(2),
	UTM_ZONE NUMBER(5,0),
	UTM_EASTING NUMBER(10,0),
	UTM_NORTHING NUMBER(10,0),
	LONGITUDE_DEGREES NUMBER(3,0),
	LONGITUDE_MINUTES NUMBER(2,0),
	LONGITUDE_SECONDS NUMBER(2,0),
	LONGITUDE_DEG_MIN NUMBER(3,0),
	LONGITUDE_MIN_MIN NUMBER(2,0),
	LONGITUDE_SEC_MIN NUMBER(2,0),
	LONGITUDE_DEG_MAX NUMBER(3,0),
	LONGITUDE_MIN_MAX NUMBER(2,0),
	LONGITUDE_SEC_MAX NUMBER(2,0),
	LATITUDE_DEGREES NUMBER(2,0),
	LATITUDE_MINUTES NUMBER(2,0),
	LATITUDE_SECONDS NUMBER(2,0),
	LATITUDE_DEG_MIN NUMBER(2,0),
	LATITUDE_MIN_MIN NUMBER(2,0),
	LATITUDE_SEC_MIN NUMBER(2,0),
	LATITUDE_DEG_MAX NUMBER(2,0),
	LATITUDE_MIN_MAX NUMBER(2,0),
	LATITUDE_SEC_MAX NUMBER(2,0),
	SEED_COAST_AREA_CODE VARCHAR2(3),
	ELEVATION NUMBER(5,0),
	ELEVATION_MIN NUMBER(5,0),
	ELEVATION_MAX NUMBER(5,0),
	SEED_PLAN_UNIT_ID NUMBER(10,0),
	ORCHARD_ID VARCHAR2(3),
	SECONDARY_ORCHARD_ID VARCHAR2(3),
	COLLECTION_LOCN_DESC VARCHAR2(30),
	COLLECTION_CLI_NUMBER VARCHAR2(8),
	COLLECTION_CLI_LOCN_CD VARCHAR2(2),
	COLLECTION_START_DATE DATE,
	COLLECTION_END_DATE DATE,
	CONE_COLLECTION_METHOD_CODE VARCHAR2(3),
	CONE_COLLECTION_METHOD2_CODE VARCHAR2(3),
	COLLECTION_LAT_DEG NUMBER(2,0),
	COLLECTION_LAT_MIN NUMBER(2,0),
	COLLECTION_LAT_SEC NUMBER(2,0),
	COLLECTION_LATITUDE_CODE VARCHAR2(2),
	COLLECTION_LONG_DEG NUMBER(3,0),
	COLLECTION_LONG_MIN NUMBER(2,0),
	COLLECTION_LONG_SEC NUMBER(2,0),
	COLLECTION_LONGITUDE_CODE VARCHAR2(2),
	COLLECTION_ELEVATION NUMBER(5,0),
	COLLECTION_ELEVATION_MIN NUMBER(5,0),
	COLLECTION_ELEVATION_MAX NUMBER(5,0),
	COLLECTION_AREA_RADIUS NUMBER(5,1),
	COLLECTION_SEED_PLAN_ZONE_IND VARCHAR2(1),
	COLLECTION_BGC_IND VARCHAR2(1),
	NO_OF_CONTAINERS NUMBER(6,2),
	CLCTN_VOLUME NUMBER(6,2),
	VOL_PER_CONTAINER NUMBER(6,2),
	NMBR_TREES_FROM_CODE VARCHAR2(1),
	EFFECTIVE_POP_SIZE NUMBER(5,1),
	ORIGINAL_SEED_QTY NUMBER(10,0),
	INTERM_STRG_CLIENT_NUMBER VARCHAR2(8),
	INTERM_STRG_CLIENT_LOCN VARCHAR2(2),
	INTERM_STRG_ST_DATE DATE,
	INTERM_STRG_END_DATE DATE,
	INTERM_FACILITY_CODE VARCHAR2(3),
	INTERM_STRG_LOCN VARCHAR2(55),
	INTERM_STRG_CMT VARCHAR2(125),
	EXTRACTION_ST_DATE DATE,
	EXTRACTION_END_DATE DATE,
	EXTRACTION_VOLUME NUMBER(6,2),
	EXTRCT_CLI_NUMBER VARCHAR2(8),
	EXTRCT_CLI_LOCN_CD VARCHAR2(2),
	EXTRACTION_COMMENT VARCHAR2(125),
	STORED_CLI_NUMBER VARCHAR2(8),
	STORED_CLI_LOCN_CD VARCHAR2(2),
	LNGTERM_STRG_ST_DATE DATE,
	HISTORICAL_TSR_DATE DATE,
	OWNERSHIP_COMMENT VARCHAR2(4000),
	CONE_SEED_DESC VARCHAR2(250),
	SEEDLOT_COMMENT VARCHAR2(2000),
	TEMPORARY_STORAGE_START_DATE DATE,
	TEMPORARY_STORAGE_END_DATE DATE,
	COLLECTION_STANDARD_MET_IND VARCHAR2(1),
	APPLICANT_EMAIL_ADDRESS VARCHAR2(100),
	BIOTECH_PROCESSES_IND VARCHAR2(1),
	POLLEN_CONTAMINATION_IND VARCHAR2(1),
	POLLEN_CONTAMINATION_PCT NUMBER(3,0),
	CONTROLLED_CROSS_IND VARCHAR2(1),
	ORCHARD_COMMENT VARCHAR2(2000),
	TOTAL_PARENT_TREES NUMBER(5,0),
	SMP_PARENTS_OUTSIDE NUMBER(5,0),
	SMP_MEAN_BV_GROWTH NUMBER(4,1),
	SMP_SUCCESS_PCT NUMBER(3,0),
	CONTAMINANT_POLLEN_BV NUMBER(4,1),
	ORCHARD_CONTAMINATION_PCT NUMBER(3,0),
	COANCESTRY NUMBER(20,10),
	PROVENANCE_ID NUMBER(5,0),
	SEED_PLAN_ZONE_CODE VARCHAR2(3),
	POLLEN_CONTAMINATION_MTHD_CODE VARCHAR2(4),
	APPLICANT_CLIENT_NUMBER VARCHAR2(8),
	APPLICANT_CLIENT_LOCN VARCHAR2(2),
	SEED_STORE_CLIENT_NUMBER VARCHAR2(8),
	SEED_STORE_CLIENT_LOCN VARCHAR2(2),
	SEEDLOT_SOURCE_CODE VARCHAR2(3),
	FEMALE_GAMETIC_MTHD_CODE VARCHAR2(4),
	MALE_GAMETIC_MTHD_CODE VARCHAR2(4),
	BGC_ZONE_CODE VARCHAR2(4),
	BGC_SUBZONE_CODE VARCHAR2(3),
	VARIANT VARCHAR2(1),
	BEC_VERSION_ID NUMBER(10,0),
	PRICE_PER_KG NUMBER(7,2),
	PRICE_COMMENT VARCHAR2(2000),
	APPROVED_USERID VARCHAR2(30),
	APPROVED_TIMESTAMP DATE,
	DECLARED_USERID VARCHAR2(30),
	DECLARED_TIMESTAMP DATE,
	ENTRY_USERID VARCHAR2(30),
	ENTRY_TIMESTAMP DATE,
	UPDATE_USERID VARCHAR2(30),
	UPDATE_TIMESTAMP DATE,
	REVISION_COUNT NUMBER(5,0),
	CONSTRAINT SEEDLOT_PK PRIMARY KEY (SEEDLOT_NUMBER),
	CONSTRAINT SYS_C0029435 CHECK ("SEEDLOT_NUMBER" IS NOT NULL),
	CONSTRAINT SYS_C0029436 CHECK ("SEEDLOT_STATUS_CODE" IS NOT NULL),
	CONSTRAINT SYS_C0029437 CHECK ("ENTRY_USERID" IS NOT NULL),
	CONSTRAINT SYS_C0029438 CHECK ("ENTRY_TIMESTAMP" IS NOT NULL),
	CONSTRAINT SYS_C0029439 CHECK ("UPDATE_USERID" IS NOT NULL),
	CONSTRAINT SYS_C0029440 CHECK ("UPDATE_TIMESTAMP" IS NOT NULL),
	CONSTRAINT SYS_C0029441 CHECK ("REVISION_COUNT" IS NOT NULL)
);

