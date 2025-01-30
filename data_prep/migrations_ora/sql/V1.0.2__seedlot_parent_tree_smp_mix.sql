
  CREATE TABLE "THE"."SEEDLOT_PARENT_TREE" 
   (	"SEEDLOT_NUMBER" VARCHAR2(5) NOT NULL ENABLE, 
	"PARENT_TREE_ID" NUMBER(10,0) NOT NULL ENABLE, 
	"CONE_COUNT" NUMBER(20,10) NOT NULL ENABLE, 
	"POLLEN_COUNT" NUMBER(20,10) NOT NULL ENABLE, 
	"SMP_SUCCESS_PCT" NUMBER(3,0), 
	"SMP_MIX_LATITUDE_DEGREES" NUMBER(2,0), 
	"SMP_MIX_LATITUDE_MINUTES" NUMBER(2,0), 
	"SMP_MIX_LONGITUDE_DEGREES" NUMBER(3,0), 
	"SMP_MIX_LONGITUDE_MINUTES" NUMBER(2,0), 
	"SMP_MIX_ELEVATION" NUMBER(5,0), 
	"NON_ORCHARD_POLLEN_CONTAM_PCT" NUMBER(3,0), 
	"TOTAL_GENETIC_WORTH_CONTRIB" NUMBER NOT NULL ENABLE, 
	"REVISION_COUNT" NUMBER(5,0) NOT NULL ENABLE, 
	 CONSTRAINT "SPT_PK" PRIMARY KEY ("SEEDLOT_NUMBER", "PARENT_TREE_ID")
  USING INDEX  ENABLE, 
	 CONSTRAINT "SPT_SEE_FK" FOREIGN KEY ("SEEDLOT_NUMBER")
	  REFERENCES "THE"."SEEDLOT" ("SEEDLOT_NUMBER") ENABLE
   ) ;

  CREATE TABLE "THE"."SEEDLOT_PARENT_TREE_SMP_MIX" 
   (	"SEEDLOT_NUMBER" VARCHAR2(5) NOT NULL ENABLE, 
	"PARENT_TREE_ID" NUMBER(10,0) NOT NULL ENABLE, 
	"GENETIC_TYPE_CODE" VARCHAR2(2) NOT NULL ENABLE, 
	"GENETIC_WORTH_CODE" VARCHAR2(3) NOT NULL ENABLE, 
	"SMP_MIX_VALUE" NUMBER(4,1) NOT NULL ENABLE, 
	"REVISION_COUNT" NUMBER(5,0) NOT NULL ENABLE, 
	 CONSTRAINT "SPTSM_PK" PRIMARY KEY ("PARENT_TREE_ID", "SEEDLOT_NUMBER", "GENETIC_TYPE_CODE", "GENETIC_WORTH_CODE")
  USING INDEX  ENABLE, 
	 CONSTRAINT "SPTSM_GTCD_FK" FOREIGN KEY ("GENETIC_TYPE_CODE")
	  REFERENCES "THE"."GENETIC_TYPE_CODE" ("GENETIC_TYPE_CODE") ENABLE, 
	 CONSTRAINT "SPTSM_SPT_FK" FOREIGN KEY ("SEEDLOT_NUMBER", "PARENT_TREE_ID")
	  REFERENCES "THE"."SEEDLOT_PARENT_TREE" ("SEEDLOT_NUMBER", "PARENT_TREE_ID") ENABLE, 
	 CONSTRAINT "SPTSM_GWC_FK" FOREIGN KEY ("GENETIC_WORTH_CODE")
	  REFERENCES "THE"."GENETIC_WORTH_CODE" ("GENETIC_WORTH_CODE") ENABLE
   ) ;
