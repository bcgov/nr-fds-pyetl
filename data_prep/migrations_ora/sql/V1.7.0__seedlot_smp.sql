
-- THE.BREEDING_SELECTION_TYPE_CODE definition

-- DDL generated by DBeaver
-- WARNING: It may differ from actual native database DDL

-- Drop table

-- DROP TABLE THE.BREEDING_SELECTION_TYPE_CODE;

CREATE TABLE THE.BREEDING_SELECTION_TYPE_CODE (
	BREEDING_SELECTION_TYPE_CODE VARCHAR2(3),
	DESCRIPTION VARCHAR2(120),
	EFFECTIVE_DATE DATE,
	EXPIRY_DATE DATE,
	UPDATE_TIMESTAMP DATE,
	CONSTRAINT BSTCD_PK PRIMARY KEY (BREEDING_SELECTION_TYPE_CODE),
	CONSTRAINT SYS_C008720 CHECK ("BREEDING_SELECTION_TYPE_CODE" IS NOT NULL),
	CONSTRAINT SYS_C008721 CHECK ("DESCRIPTION" IS NOT NULL),
	CONSTRAINT SYS_C008722 CHECK ("EFFECTIVE_DATE" IS NOT NULL),
	CONSTRAINT SYS_C008723 CHECK ("EXPIRY_DATE" IS NOT NULL),
	CONSTRAINT SYS_C008724 CHECK ("UPDATE_TIMESTAMP" IS NOT NULL)
);
-- CREATE UNIQUE INDEX BSTCD_PK ON THE.BREEDING_SELECTION_TYPE_CODE (BREEDING_SELECTION_TYPE_CODE);


-- THE.BEC_ZONE_CODE definition

-- DDL generated by DBeaver
-- WARNING: It may differ from actual native database DDL

-- Drop table

-- DROP TABLE THE.BEC_ZONE_CODE;

CREATE TABLE THE.BEC_ZONE_CODE (
	BEC_ZONE_CODE VARCHAR2(4),
	DESCRIPTION VARCHAR2(120),
	EFFECTIVE_DATE DATE,
	EXPIRY_DATE DATE,
	UPDATE_TIMESTAMP DATE,
	CONSTRAINT BEC_ZC_PK PRIMARY KEY (BEC_ZONE_CODE),
	CONSTRAINT SYS_C0019200 CHECK ("BEC_ZONE_CODE" IS NOT NULL),
	CONSTRAINT SYS_C0019201 CHECK ("DESCRIPTION" IS NOT NULL),
	CONSTRAINT SYS_C0019202 CHECK ("EFFECTIVE_DATE" IS NOT NULL),
	CONSTRAINT SYS_C0019203 CHECK ("EXPIRY_DATE" IS NOT NULL),
	CONSTRAINT SYS_C0019204 CHECK ("UPDATE_TIMESTAMP" IS NOT NULL)
);
-- CREATE UNIQUE INDEX BEC_ZC_PK ON THE.BEC_ZONE_CODE (BEC_ZONE_CODE);


-- THE.NATURAL_SELECTION_TYPE_CODE definition

-- DDL generated by DBeaver
-- WARNING: It may differ from actual native database DDL

-- Drop table

-- DROP TABLE THE.NATURAL_SELECTION_TYPE_CODE;

CREATE TABLE THE.NATURAL_SELECTION_TYPE_CODE (
	NATURAL_SELECTION_TYPE_CODE VARCHAR2(3),
	DESCRIPTION VARCHAR2(120),
	EFFECTIVE_DATE DATE,
	EXPIRY_DATE DATE,
	UPDATE_TIMESTAMP DATE,
	CONSTRAINT NSTCD_PK PRIMARY KEY (NATURAL_SELECTION_TYPE_CODE),
	CONSTRAINT SYS_C0022025 CHECK ("NATURAL_SELECTION_TYPE_CODE" IS NOT NULL),
	CONSTRAINT SYS_C0022026 CHECK ("DESCRIPTION" IS NOT NULL),
	CONSTRAINT SYS_C0022027 CHECK ("EFFECTIVE_DATE" IS NOT NULL),
	CONSTRAINT SYS_C0022028 CHECK ("EXPIRY_DATE" IS NOT NULL),
	CONSTRAINT SYS_C0022029 CHECK ("UPDATE_TIMESTAMP" IS NOT NULL)
);
-- CREATE UNIQUE INDEX NSTCD_PK ON THE.NATURAL_SELECTION_TYPE_CODE (NATURAL_SELECTION_TYPE_CODE);


-- THE.PARENT_TREE_REG_STATUS_CODE definition

-- DDL generated by DBeaver
-- WARNING: It may differ from actual native database DDL

-- Drop table

-- DROP TABLE THE.PARENT_TREE_REG_STATUS_CODE;

CREATE TABLE THE.PARENT_TREE_REG_STATUS_CODE (
	PARENT_TREE_REG_STATUS_CODE VARCHAR2(3),
	DESCRIPTION VARCHAR2(120),
	EFFECTIVE_DATE DATE,
	EXPIRY_DATE DATE,
	UPDATE_TIMESTAMP DATE,
	CONSTRAINT PTRSC_PK PRIMARY KEY (PARENT_TREE_REG_STATUS_CODE),
	CONSTRAINT SYS_C009069 CHECK ("PARENT_TREE_REG_STATUS_CODE" IS NOT NULL),
	CONSTRAINT SYS_C009070 CHECK ("DESCRIPTION" IS NOT NULL),
	CONSTRAINT SYS_C009071 CHECK ("EFFECTIVE_DATE" IS NOT NULL),
	CONSTRAINT SYS_C009072 CHECK ("EXPIRY_DATE" IS NOT NULL),
	CONSTRAINT SYS_C009073 CHECK ("UPDATE_TIMESTAMP" IS NOT NULL)
);
-- CREATE UNIQUE INDEX PTRSC_PK ON THE.PARENT_TREE_REG_STATUS_CODE (PARENT_TREE_REG_STATUS_CODE);

-- THE.PARENT_TREE definition

-- DDL generated by DBeaver
-- WARNING: It may differ from actual native database DDL

-- Drop table

-- DROP TABLE THE.PARENT_TREE;

CREATE TABLE THE.PARENT_TREE (
	PARENT_TREE_ID NUMBER(10,0),
	PARENT_TREE_NUMBER VARCHAR2(5),
	VEGETATION_CODE VARCHAR2(8),
	PARENT_TREE_REG_STATUS_CODE VARCHAR2(3),
	LOCAL_NUMBER VARCHAR2(20),
	ACTIVE_IND VARCHAR2(1),
	TESTED_IND VARCHAR2(1),
	BREEDING_PROGRAM_IND VARCHAR2(1),
	SELECTION_DATE DATE,
	BC_SOURCE_IND VARCHAR2(1),
	CLIENT_NUMBER VARCHAR2(8),
	CLIENT_LOCN_CODE VARCHAR2(2),
	NATURAL_SELECTION_TYPE_CODE VARCHAR2(3),
	GEOGRAPHIC_LOCATION VARCHAR2(30),
	LATITUDE_DEGREES NUMBER(2,0),
	LATITUDE_MINUTES NUMBER(2,0),
	LATITUDE_SECONDS NUMBER(2,0),
	LONGITUDE_DEGREES NUMBER(3,0),
	LONGITUDE_MINUTES NUMBER(2,0),
	LONGITUDE_SECONDS NUMBER(2,0),
	SEED_PLAN_ZONE_CODE VARCHAR2(3),
	ELEVATION NUMBER(5,0),
	SELECTION_AGE NUMBER(3,0),
	BGC_ZONE_CODE VARCHAR2(4),
	BGC_SUBZONE_CODE VARCHAR2(3),
	BGC_VARIANT VARCHAR2(1),
	BREEDING_SELECTION_TYPE_CODE VARCHAR2(3),
	FEMALE_PARENT_PARENT_TREE_ID NUMBER(10,0),
	MALE_PARENT_PARENT_TREE_ID NUMBER(10,0),
	PARENT_TREE_COMMENT VARCHAR2(2000),
	ENTRY_USERID VARCHAR2(30),
	ENTRY_TIMESTAMP DATE,
	UPDATE_USERID VARCHAR2(30),
	UPDATE_TIMESTAMP DATE,
	REVISION_COUNT NUMBER(5,0),
	CONSTRAINT PT_PK PRIMARY KEY (PARENT_TREE_ID),
	CONSTRAINT PT_UK UNIQUE (PARENT_TREE_NUMBER,VEGETATION_CODE),
	CONSTRAINT SYS_C0011857 CHECK ("PARENT_TREE_ID" IS NOT NULL),
	CONSTRAINT SYS_C0011858 CHECK ("PARENT_TREE_NUMBER" IS NOT NULL),
	CONSTRAINT SYS_C0011859 CHECK ("VEGETATION_CODE" IS NOT NULL),
	CONSTRAINT SYS_C0011860 CHECK ("PARENT_TREE_REG_STATUS_CODE" IS NOT NULL),
	CONSTRAINT SYS_C0011861 CHECK ("ENTRY_USERID" IS NOT NULL),
	CONSTRAINT SYS_C0011862 CHECK ("ENTRY_TIMESTAMP" IS NOT NULL),
	CONSTRAINT SYS_C0011863 CHECK ("UPDATE_USERID" IS NOT NULL),
	CONSTRAINT SYS_C0011864 CHECK ("UPDATE_TIMESTAMP" IS NOT NULL),
	CONSTRAINT SYS_C0011865 CHECK ("REVISION_COUNT" IS NOT NULL)
);
CREATE INDEX PT_BSTCD_FK_I ON THE.PARENT_TREE (BREEDING_SELECTION_TYPE_CODE);
CREATE INDEX PT_BZC_FK_I ON THE.PARENT_TREE (BGC_ZONE_CODE);
CREATE INDEX PT_CL1_FK_I ON THE.PARENT_TREE (CLIENT_NUMBER,CLIENT_LOCN_CODE);
CREATE INDEX PT_NSTCD_FK_I ON THE.PARENT_TREE (NATURAL_SELECTION_TYPE_CODE);
-- CREATE UNIQUE INDEX PT_PK ON THE.PARENT_TREE (PARENT_TREE_ID);
CREATE INDEX PT_PTRSC_FK_I ON THE.PARENT_TREE (PARENT_TREE_REG_STATUS_CODE);
CREATE INDEX PT_PT_FEMALE_PARENT_FK_I ON THE.PARENT_TREE (FEMALE_PARENT_PARENT_TREE_ID);
CREATE INDEX PT_PT_MALE_PARENT_FK_I ON THE.PARENT_TREE (MALE_PARENT_PARENT_TREE_ID);
CREATE INDEX PT_SEED_PLAN_ZONE_FK_I ON THE.PARENT_TREE (SEED_PLAN_ZONE_CODE);
-- CREATE UNIQUE INDEX PT_UK ON THE.PARENT_TREE (PARENT_TREE_NUMBER,VEGETATION_CODE);
CREATE INDEX PT_VEGETATION_CODE_FK_I ON THE.PARENT_TREE (VEGETATION_CODE);


-- THE.PARENT_TREE foreign keys

ALTER TABLE THE.PARENT_TREE ADD CONSTRAINT PT_BSTCD_FK FOREIGN KEY (BREEDING_SELECTION_TYPE_CODE) REFERENCES THE.BREEDING_SELECTION_TYPE_CODE(BREEDING_SELECTION_TYPE_CODE);
ALTER TABLE THE.PARENT_TREE ADD CONSTRAINT PT_BZC_FK FOREIGN KEY (BGC_ZONE_CODE) REFERENCES THE.BEC_ZONE_CODE(BEC_ZONE_CODE);
ALTER TABLE THE.PARENT_TREE ADD CONSTRAINT PT_CL1_FK FOREIGN KEY (CLIENT_NUMBER,CLIENT_LOCN_CODE) REFERENCES THE.CLIENT_LOCATION(CLIENT_NUMBER,CLIENT_LOCN_CODE);
ALTER TABLE THE.PARENT_TREE ADD CONSTRAINT PT_NSTCD_FK FOREIGN KEY (NATURAL_SELECTION_TYPE_CODE) REFERENCES THE.NATURAL_SELECTION_TYPE_CODE(NATURAL_SELECTION_TYPE_CODE);
ALTER TABLE THE.PARENT_TREE ADD CONSTRAINT PT_PTRSC_FK FOREIGN KEY (PARENT_TREE_REG_STATUS_CODE) REFERENCES THE.PARENT_TREE_REG_STATUS_CODE(PARENT_TREE_REG_STATUS_CODE);
ALTER TABLE THE.PARENT_TREE ADD CONSTRAINT PT_PT_FEMALE_PARENT_FK FOREIGN KEY (FEMALE_PARENT_PARENT_TREE_ID) REFERENCES THE.PARENT_TREE(PARENT_TREE_ID);
ALTER TABLE THE.PARENT_TREE ADD CONSTRAINT PT_PT_MALE_PARENT_FK FOREIGN KEY (MALE_PARENT_PARENT_TREE_ID) REFERENCES THE.PARENT_TREE(PARENT_TREE_ID);
ALTER TABLE THE.PARENT_TREE ADD CONSTRAINT PT_SEED_PLAN_ZONE_CODE_FK FOREIGN KEY (SEED_PLAN_ZONE_CODE) REFERENCES THE.SEED_PLAN_ZONE_CODE(SEED_PLAN_ZONE_CODE);
ALTER TABLE THE.PARENT_TREE ADD CONSTRAINT PT_VEGETATION_CODE_FK FOREIGN KEY (VEGETATION_CODE) REFERENCES THE.VEGETATION_CODE(VEGETATION_CODE);



-- THE.SMP_MIX definition

-- DDL generated by DBeaver
-- WARNING: It may differ from actual native database DDL

-- Drop table

-- DROP TABLE THE.SMP_MIX;

CREATE TABLE THE.SMP_MIX (
	SEEDLOT_NUMBER VARCHAR2(5),
	PARENT_TREE_ID NUMBER(10,0),
	AMOUNT_OF_MATERIAL NUMBER(6,0),
	REVISION_COUNT NUMBER(5,0),
	CONSTRAINT SMPM_PK PRIMARY KEY (SEEDLOT_NUMBER,PARENT_TREE_ID),
	CONSTRAINT SYS_C0016676 CHECK ("SEEDLOT_NUMBER" IS NOT NULL),
	CONSTRAINT SYS_C0016677 CHECK ("PARENT_TREE_ID" IS NOT NULL),
	CONSTRAINT SYS_C0016678 CHECK ("AMOUNT_OF_MATERIAL" IS NOT NULL),
	CONSTRAINT SYS_C0016679 CHECK ("REVISION_COUNT" IS NOT NULL)
);
-- CREATE UNIQUE INDEX SMPM_PK ON THE.SMP_MIX (SEEDLOT_NUMBER,PARENT_TREE_ID);
CREATE INDEX SMPM_PT_FK_I ON THE.SMP_MIX (PARENT_TREE_ID);
CREATE INDEX SMPM_SEE_FK_I ON THE.SMP_MIX (SEEDLOT_NUMBER);


-- THE.SMP_MIX foreign keys
ALTER TABLE THE.SMP_MIX ADD CONSTRAINT SMPM_PT_FK FOREIGN KEY (PARENT_TREE_ID) REFERENCES THE.PARENT_TREE(PARENT_TREE_ID);
ALTER TABLE THE.SMP_MIX ADD CONSTRAINT SMPM_SEE_FK FOREIGN KEY (SEEDLOT_NUMBER) REFERENCES THE.SEEDLOT(SEEDLOT_NUMBER);


-- THE.SMP_MIX_GEN_QLTY definition

-- DDL generated by DBeaver
-- WARNING: It may differ from actual native database DDL

-- Drop table

-- DROP TABLE THE.SMP_MIX_GEN_QLTY;

CREATE TABLE THE.SMP_MIX_GEN_QLTY (
	SEEDLOT_NUMBER VARCHAR2(5),
	PARENT_TREE_ID NUMBER(10,0),
	GENETIC_TYPE_CODE VARCHAR2(2),
	GENETIC_WORTH_CODE VARCHAR2(3),
	GENETIC_QUALITY_VALUE NUMBER(4,1),
	ESTIMATED_IND VARCHAR2(1),
	REVISION_COUNT NUMBER(5,0),
	CONSTRAINT SMGQ_PK PRIMARY KEY (PARENT_TREE_ID,SEEDLOT_NUMBER,GENETIC_TYPE_CODE,GENETIC_WORTH_CODE),
	CONSTRAINT SYS_C0019384 CHECK ("SEEDLOT_NUMBER" IS NOT NULL),
	CONSTRAINT SYS_C0019385 CHECK ("PARENT_TREE_ID" IS NOT NULL),
	CONSTRAINT SYS_C0019386 CHECK ("GENETIC_TYPE_CODE" IS NOT NULL),
	CONSTRAINT SYS_C0019387 CHECK ("GENETIC_WORTH_CODE" IS NOT NULL),
	CONSTRAINT SYS_C0019388 CHECK ("GENETIC_QUALITY_VALUE" IS NOT NULL),
	CONSTRAINT SYS_C0019389 CHECK ("ESTIMATED_IND" IS NOT NULL),
	CONSTRAINT SYS_C0019390 CHECK ("REVISION_COUNT" IS NOT NULL)
);
CREATE INDEX SMGQ_GTCD_FK_I ON THE.SMP_MIX_GEN_QLTY (GENETIC_TYPE_CODE);
CREATE INDEX SMGQ_GWC_FK_I ON THE.SMP_MIX_GEN_QLTY (GENETIC_WORTH_CODE);
-- CREATE UNIQUE INDEX SMGQ_PK ON THE.SMP_MIX_GEN_QLTY (PARENT_TREE_ID,SEEDLOT_NUMBER,GENETIC_TYPE_CODE,GENETIC_WORTH_CODE);
CREATE INDEX SMGQ_SMPM_FK_I ON THE.SMP_MIX_GEN_QLTY (SEEDLOT_NUMBER,PARENT_TREE_ID);


-- THE.SMP_MIX_GEN_QLTY foreign keys

ALTER TABLE THE.SMP_MIX_GEN_QLTY ADD CONSTRAINT SMGQ_GTCD_FK FOREIGN KEY (GENETIC_TYPE_CODE) REFERENCES THE.GENETIC_TYPE_CODE(GENETIC_TYPE_CODE);
ALTER TABLE THE.SMP_MIX_GEN_QLTY ADD CONSTRAINT SMGQ_GWC_FK FOREIGN KEY (GENETIC_WORTH_CODE) REFERENCES THE.GENETIC_WORTH_CODE(GENETIC_WORTH_CODE);
ALTER TABLE THE.SMP_MIX_GEN_QLTY ADD CONSTRAINT SMGQ_SMPM_FK FOREIGN KEY (SEEDLOT_NUMBER,PARENT_TREE_ID) REFERENCES THE.SMP_MIX(SEEDLOT_NUMBER,PARENT_TREE_ID);