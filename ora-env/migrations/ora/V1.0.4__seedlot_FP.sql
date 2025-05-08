
  CREATE OR REPLACE EDITIONABLE FUNCTION "THE"."CLIENT_GET_CLIENT_NAME" 
/******************************************************************************
Purpose:   Retrieve Client Name, return null if none found

REVISIONS:
Ver          Date        Author           Description
---------   ----------   ---------------  ------------------------------------
1.0        July 25/2008  T. Blanchard    Original.- created to replace
                                         sil_get_client_name which has a defect

******************************************************************************/
(
  p_client_number                  IN       VARCHAR2)
  RETURN VARCHAR2
IS
  v_client_name                         VARCHAR2(150);
  v_first_name                          VARCHAR2(60);
  v_middle_name                         VARCHAR2(60);
BEGIN
  SELECT client_name
       , legal_first_name
       , legal_middle_name
    INTO v_client_name
       , v_first_name
       , v_middle_name
    FROM v_client_public
   WHERE client_number = p_client_number;

  IF    (TRIM(v_first_name) IS NOT NULL)
     OR (TRIM(v_middle_name) IS NOT NULL) THEN
    v_client_name := v_client_name || ', ' || v_first_name || ' ' || v_middle_name;
  END IF;

  RETURN(v_client_name);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN(NULL);                                                                  -- no name found
END client_get_client_name;
/

  CREATE OR REPLACE EDITIONABLE FUNCTION "THE"."SIL_STD_CLIENT_NAME" 
/******************************************************************************
Purpose:   Returns standard client name given:
             FOREST_CLIENT.CLIENT_NAME
             FOREST_CLIENT.LEGAL_FIRST_NAME
             FOREST_CLIENT.LEGAL_MIDDLE_NAME

REVISIONS:
Date        Author           Description
----------  ---------------  --------------------------------------------------
2006-08-08 R.A.Rob           Taken from SIL_GET_CLIENT_NAME
******************************************************************************/
(
  p_client_name                    IN       VARCHAR2
, p_legal_first_name               IN       VARCHAR2
, p_legal_middle_name              IN       VARCHAR2)
  RETURN VARCHAR2
IS
  v_client_name                      VARCHAR2(200);
BEGIN
  IF (TRIM(p_legal_first_name) IS NOT NULL)
     OR(TRIM(p_legal_middle_name) IS NOT NULL) THEN
    v_client_name := p_client_name || ', ' || p_legal_first_name || ' ' || p_legal_middle_name;
  ELSE
    v_client_name := p_client_name;
  END IF;

  RETURN(v_client_name);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN(NULL);   -- no name found
END sil_std_client_name;
/

  CREATE OR REPLACE EDITIONABLE FUNCTION "THE"."SIL_CONVERT_TO_CHAR" ( p_value IN DATE, p_format IN VARCHAR2) RETURN VARCHAR2 IS

dateStr VARCHAR2(25);


BEGIN

    dateStr := TO_CHAR(p_value, p_format);
    RETURN (dateStr);


EXCEPTION
    WHEN OTHERS THEN
      RAISE;
END;
/
