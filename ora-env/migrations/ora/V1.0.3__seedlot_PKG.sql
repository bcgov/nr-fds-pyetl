
  CREATE OR REPLACE EDITIONABLE PACKAGE "THE"."CLIENT_UTILS" 
AS
/******************************************************************************
    Package:   CLIENT_UTILS

    Purpose:   Package contains common calls used by the Client Application.

    Revision History

    Person             Date        Comments
    -----------------  ----------  ------------------------------------------
    E.Wong             2007-01-11  Original
******************************************************************************/
  PROCEDURE add_error(
    p_error_message                  IN OUT   sil_error_messages
  , p_db_field                       IN       VARCHAR2
  , p_message                        IN       VARCHAR2
  , p_params                         IN       sil_error_params DEFAULT NULL
  , p_warning_flag                   IN       BOOLEAN          DEFAULT FALSE);

  PROCEDURE append_arrays(
    p_orig_array                     IN OUT   sil_error_messages
  , p_add_array                      IN       sil_error_messages);
END client_utils;
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "THE"."CLIENT_UTILS" 
AS
/******************************************************************************
    Procedure:  add_error

    Purpose:    Adds the error message to the error message array.

******************************************************************************/
  PROCEDURE add_error(
    p_error_message                  IN OUT   sil_error_messages
  , p_db_field                       IN       VARCHAR2
  , p_message                        IN       VARCHAR2
  , p_params                         IN       sil_error_params DEFAULT NULL
  , p_warning_flag                   IN       BOOLEAN          DEFAULT FALSE)
  IS
    v_error_msg                        sil_error_message;
    v_warning_flag                     VARCHAR2(1) := 'N';
  BEGIN
    IF p_warning_flag THEN
      v_warning_flag := 'Y';
    END IF;

    v_error_msg := sil_error_message(p_db_field, p_message, p_params, v_warning_flag);

    IF    p_error_message IS NULL
       OR p_error_message.COUNT = 0 THEN
      p_error_message := sil_error_messages(v_error_msg);
    ELSE
      p_error_message.EXTEND;
      p_error_message(p_error_message.COUNT) := v_error_msg;
    END IF;
  END add_error;

/******************************************************************************
    Procedure:  append_arrays

    Purpose:    appends the second array to the original one.

******************************************************************************/
  PROCEDURE append_arrays(
    p_orig_array                     IN OUT   sil_error_messages
  , p_add_array                      IN       sil_error_messages)
  IS
  BEGIN
    IF    p_orig_array IS NULL
       OR p_orig_array.COUNT = 0 THEN
      p_orig_array := p_add_array;
    ELSE
      IF     p_add_array IS NOT NULL
         AND p_add_array.COUNT > 0 THEN
        FOR i IN p_add_array.FIRST .. p_add_array.LAST LOOP
          p_orig_array.EXTEND;
          p_orig_array(p_orig_array.COUNT) := p_add_array(i);
        END LOOP;
      END IF;
    END IF;
  END append_arrays;
END client_utils;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "THE"."CLIENT_CLIENT_UPDATE_REASON" AS

  PROCEDURE get;

  PROCEDURE init;
  --***START GETTERS
  FUNCTION error_raised RETURN BOOLEAN;

  FUNCTION get_error_message RETURN SIL_ERROR_MESSAGES;

  FUNCTION get_client_update_reason_id RETURN NUMBER;

  FUNCTION get_client_update_action_code RETURN VARCHAR2;

  FUNCTION get_client_update_reason_code RETURN VARCHAR2;

  FUNCTION get_client_type_code RETURN VARCHAR2;

  FUNCTION get_forest_client_audit_id RETURN NUMBER;

  FUNCTION get_update_timestamp RETURN DATE;

  FUNCTION get_update_userid RETURN VARCHAR2;

  FUNCTION get_add_timestamp RETURN DATE;

  FUNCTION get_add_userid RETURN VARCHAR2;
  --***END GETTERS

  --***START SETTERS

  PROCEDURE set_client_update_reason_id(p_value IN NUMBER);

  PROCEDURE set_client_update_action_code(p_value IN VARCHAR2);

  PROCEDURE set_client_update_reason_code(p_value IN VARCHAR2);

  PROCEDURE set_client_type_code(p_value IN VARCHAR2);

  PROCEDURE set_forest_client_audit_id(p_value IN NUMBER);

  PROCEDURE set_update_timestamp(p_value IN DATE);

  PROCEDURE set_update_userid(p_value IN VARCHAR2);

  PROCEDURE set_add_timestamp(p_value IN DATE);

  PROCEDURE set_add_userid(p_value IN VARCHAR2);
  --***END SETTERS

  PROCEDURE validate;

  PROCEDURE add;

  FUNCTION check_client_name
  (p_old_client_name        IN VARCHAR2
  ,p_old_legal_first_name   IN VARCHAR2
  ,p_old_legal_middle_name  IN VARCHAR2
  ,p_new_client_name        IN VARCHAR2
  ,p_new_legal_first_name   IN VARCHAR2
  ,p_new_legal_middle_name  IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION check_address
  (p_old_address_1        IN VARCHAR2
  ,p_old_address_2        IN VARCHAR2
  ,p_old_address_3        IN VARCHAR2
  ,p_old_city             IN VARCHAR2
  ,p_old_province         IN VARCHAR2
  ,p_old_postal_code      IN VARCHAR2
  ,p_old_country          IN VARCHAR2
  ,p_new_address_1        IN VARCHAR2
  ,p_new_address_2        IN VARCHAR2
  ,p_new_address_3        IN VARCHAR2
  ,p_new_city             IN VARCHAR2
  ,p_new_province         IN VARCHAR2
  ,p_new_postal_code      IN VARCHAR2
  ,p_new_country          IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION check_id
  (p_old_client_identification  IN VARCHAR2
  ,p_old_client_id_type_code    IN VARCHAR2
  ,p_new_client_identification  IN VARCHAR2
  ,p_new_client_id_type_code    IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION check_status
  (p_old_client_status_code  IN VARCHAR2
  ,p_new_client_status_code  IN VARCHAR2)
  RETURN VARCHAR2;

END client_client_update_reason;
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "THE"."CLIENT_CLIENT_UPDATE_REASON" AS

  --member vars

  g_error_message                              SIL_ERROR_MESSAGES;

  g_client_update_reason_id                    client_update_reason.client_update_reason_id%TYPE;
  gb_client_update_reason_id                   VARCHAR2(1);

  g_client_update_action_code                  client_update_reason.client_update_action_code%TYPE;
  gb_client_update_action_code                 VARCHAR2(1);

  g_client_update_reason_code                  client_update_reason.client_update_reason_code%TYPE;
  gb_client_update_reason_code                 VARCHAR2(1);

  g_client_type_code                           client_update_reason.client_type_code%TYPE;
  gb_client_type_code                          VARCHAR2(1);

  g_forest_client_audit_id                     client_update_reason.forest_client_audit_id%TYPE;
  gb_forest_client_audit_id                    VARCHAR2(1);

  g_update_timestamp                           client_update_reason.update_timestamp%TYPE;
  gb_update_timestamp                          VARCHAR2(1);

  g_update_userid                              client_update_reason.update_userid%TYPE;
  gb_update_userid                             VARCHAR2(1);

  g_add_timestamp                              client_update_reason.add_timestamp%TYPE;
  gb_add_timestamp                             VARCHAR2(1);

  g_add_userid                                 client_update_reason.add_userid%TYPE;
  gb_add_userid                                VARCHAR2(1);

/******************************************************************************
    Procedure:  get

    Purpose:    SELECT one row from CLIENT_UPDATE_REASON

******************************************************************************/
  PROCEDURE get
  IS
  BEGIN
    SELECT
           client_update_reason_id
         , client_update_action_code
         , client_update_reason_code
         , client_type_code
         , forest_client_audit_id
         , update_timestamp
         , update_userid
         , add_timestamp
         , add_userid
      INTO
           g_client_update_reason_id
         , g_client_update_action_code
         , g_client_update_reason_code
         , g_client_type_code
         , g_forest_client_audit_id
         , g_update_timestamp
         , g_update_userid
         , g_add_timestamp
         , g_add_userid
      FROM client_update_reason
     WHERE client_update_reason_id = g_client_update_reason_id;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
  END get;


/******************************************************************************
    Procedure:  init

    Purpose:    Initialize member variables

******************************************************************************/
  PROCEDURE init
  IS

  BEGIN

    g_error_message := NULL;

    g_client_update_reason_id := NULL;
    gb_client_update_reason_id := 'N';

    g_client_update_action_code := NULL;
    gb_client_update_action_code := 'N';

    g_client_update_reason_code := NULL;
    gb_client_update_reason_code := 'N';

    g_client_type_code := NULL;
    gb_client_type_code := 'N';

    g_forest_client_audit_id := NULL;
    gb_forest_client_audit_id := 'N';

    g_update_timestamp := NULL;
    gb_update_timestamp := 'N';

    g_update_userid := NULL;
    gb_update_userid := 'N';

    g_add_timestamp := NULL;
    gb_add_timestamp := 'N';

    g_add_userid := NULL;
    gb_add_userid := 'N';

  END init;

  --***START GETTERS

  --error raised?
  FUNCTION error_raised RETURN BOOLEAN
  IS
  BEGIN
    RETURN (g_error_message IS NOT NULL);
  END error_raised;

  --get error message
  FUNCTION get_error_message RETURN SIL_ERROR_MESSAGES
  IS
  BEGIN
    RETURN g_error_message;
  END get_error_message;

  --get client_update_reason_id
  FUNCTION get_client_update_reason_id RETURN NUMBER
  IS
  BEGIN
    RETURN g_client_update_reason_id;
  END get_client_update_reason_id;

  --get client_update_action_code
  FUNCTION get_client_update_action_code RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_update_action_code;
  END get_client_update_action_code;

  --get client_update_reason_code
  FUNCTION get_client_update_reason_code RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_update_reason_code;
  END get_client_update_reason_code;

  --get client_type_code
  FUNCTION get_client_type_code RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_type_code;
  END get_client_type_code;

  --get forest_client_audit_id
  FUNCTION get_forest_client_audit_id RETURN NUMBER
  IS
  BEGIN
    RETURN g_forest_client_audit_id;
  END get_forest_client_audit_id;

  --get update_timestamp
  FUNCTION get_update_timestamp RETURN DATE
  IS
  BEGIN
    RETURN g_update_timestamp;
  END get_update_timestamp;

  --get update_userid
  FUNCTION get_update_userid RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_update_userid;
  END get_update_userid;

  --get add_timestamp
  FUNCTION get_add_timestamp RETURN DATE
  IS
  BEGIN
    RETURN g_add_timestamp;
  END get_add_timestamp;

  --get add_userid
  FUNCTION get_add_userid RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_add_userid;
  END get_add_userid;
  --***END GETTERS

  --***START SETTERS

  --set client_update_reason_id
  PROCEDURE set_client_update_reason_id(p_value IN NUMBER)
  IS
  BEGIN
    g_client_update_reason_id := p_value;
    gb_client_update_reason_id := 'Y';
  END set_client_update_reason_id;

  --set client_update_action_code
  PROCEDURE set_client_update_action_code(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_update_action_code := p_value;
    gb_client_update_action_code := 'Y';
  END set_client_update_action_code;

  --set client_update_reason_code
  PROCEDURE set_client_update_reason_code(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_update_reason_code := p_value;
    gb_client_update_reason_code := 'Y';
  END set_client_update_reason_code;

  --set client_type_code
  PROCEDURE set_client_type_code(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_type_code := p_value;
    gb_client_type_code := 'Y';
  END set_client_type_code;

  --set forest_client_audit_id
  PROCEDURE set_forest_client_audit_id(p_value IN NUMBER)
  IS
  BEGIN
    g_forest_client_audit_id := p_value;
    gb_forest_client_audit_id := 'Y';
  END set_forest_client_audit_id;

  --set update_timestamp
  PROCEDURE set_update_timestamp(p_value IN DATE)
  IS
  BEGIN
    g_update_timestamp := p_value;
    gb_update_timestamp := 'Y';
  END set_update_timestamp;

  --set update_userid
  PROCEDURE set_update_userid(p_value IN VARCHAR2)
  IS
  BEGIN
    g_update_userid := p_value;
    gb_update_userid := 'Y';
  END set_update_userid;

  --set add_timestamp
  PROCEDURE set_add_timestamp(p_value IN DATE)
  IS
  BEGIN
    g_add_timestamp := p_value;
    gb_add_timestamp := 'Y';
  END set_add_timestamp;

  --set add_userid
  PROCEDURE set_add_userid(p_value IN VARCHAR2)
  IS
  BEGIN
    g_add_userid := p_value;
    gb_add_userid := 'Y';
  END set_add_userid;
  --***END SETTERS

/******************************************************************************
    Procedure:  validate_mandatories

    Purpose:    Validate optionality

******************************************************************************/
  PROCEDURE validate_mandatories
  IS
  BEGIN
    IF g_client_update_action_code IS NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                         , NULL
                         , 'sil.error.usr.isrequired'
                         , SIL_ERROR_PARAMS('Client Update Action'));
    END IF;
    IF g_client_update_reason_code IS NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                         , NULL
                         , 'sil.error.usr.isrequired'
                         , SIL_ERROR_PARAMS('Client Update Reason'));
    END IF;
    IF g_client_type_code IS NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                         , NULL
                         , 'sil.error.usr.isrequired'
                         , SIL_ERROR_PARAMS('Client Type'));
    END IF;
    IF g_forest_client_audit_id IS NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                         , NULL
                         , 'sil.error.usr.isrequired'
                         , SIL_ERROR_PARAMS('Client Audit ID'));
    END IF;
  END validate_mandatories;

/******************************************************************************
    Procedure:  validate_action_reason_xref

    Purpose:    Validate action/reason combination

******************************************************************************/
  PROCEDURE validate_action_reason_xref
  IS
    CURSOR c_xref
    IS
      SELECT client_update_action_code
        FROM client_action_reason_xref
       WHERE client_update_action_code = g_client_update_action_code
         AND client_update_reason_code = g_client_update_reason_code
         AND client_type_code = g_client_type_code;
    r_xref          c_xref%ROWTYPE;
  BEGIN
    IF g_client_update_action_code IS NOT NULL
    AND g_client_update_reason_code IS NOT NULL
    AND g_client_type_code IS NOT NULL THEN
      OPEN c_xref;
      FETCH c_xref INTO r_xref;
      CLOSE c_xref;

      IF r_xref.client_update_action_code IS NULL THEN
        --reason is not valid for the action specified
        CLIENT_UTILS.add_error(g_error_message
                         , NULL
                         , 'client.web.usr.database.action.reason.xref'
                         , NULL);
      END IF;
    END IF;
  END validate_action_reason_xref;


/******************************************************************************
    Procedure:  validate

    Purpose:    Column validators

******************************************************************************/
  PROCEDURE validate
  IS
  BEGIN
    validate_mandatories;

    validate_action_reason_xref;
  END validate;


/******************************************************************************
    Procedure:  add

    Purpose:    INSERT one row into CLIENT_UPDATE_REASON

******************************************************************************/
  PROCEDURE add
  IS
  BEGIN
    INSERT INTO client_update_reason
       ( client_update_reason_id
       , forest_client_audit_id
       , client_update_action_code
       , client_update_reason_code
       , client_type_code
       , update_timestamp
       , update_userid
       , add_timestamp
       , add_userid
       )
     VALUES
       ( client_update_reason_seq.NEXTVAL
       , g_forest_client_audit_id
       , g_client_update_action_code
       , g_client_update_reason_code
       , g_client_type_code
       , g_update_timestamp
       , g_update_userid
       , g_add_timestamp
       , g_add_userid
       )
      RETURNING client_update_reason_id
           INTO g_client_update_reason_id;
  END add;

/******************************************************************************

  Following procs determine if items have changed.
  If items have changed, an update action code is returned.

******************************************************************************/
  FUNCTION check_client_name
  (p_old_client_name        IN VARCHAR2
  ,p_old_legal_first_name   IN VARCHAR2
  ,p_old_legal_middle_name  IN VARCHAR2
  ,p_new_client_name        IN VARCHAR2
  ,p_new_legal_first_name   IN VARCHAR2
  ,p_new_legal_middle_name  IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    IF NVL(p_old_client_name,CHR(255))||NVL(p_old_legal_first_name,CHR(255))||NVL(p_old_legal_middle_name,CHR(255)) !=
       NVL(p_new_client_name,CHR(255))||NVL(p_new_legal_first_name,CHR(255))||NVL(p_new_legal_middle_name,CHR(255)) THEN
      RETURN 'NAME';
    ELSE
      RETURN NULL;
    END IF;
  END check_client_name;

  FUNCTION check_address
  (p_old_address_1        IN VARCHAR2
  ,p_old_address_2        IN VARCHAR2
  ,p_old_address_3        IN VARCHAR2
  ,p_old_city             IN VARCHAR2
  ,p_old_province         IN VARCHAR2
  ,p_old_postal_code      IN VARCHAR2
  ,p_old_country          IN VARCHAR2
  ,p_new_address_1        IN VARCHAR2
  ,p_new_address_2        IN VARCHAR2
  ,p_new_address_3        IN VARCHAR2
  ,p_new_city             IN VARCHAR2
  ,p_new_province         IN VARCHAR2
  ,p_new_postal_code      IN VARCHAR2
  ,p_new_country          IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    IF NVL(p_old_address_1,CHR(255))
     ||NVL(p_old_address_2,CHR(255))
     ||NVL(p_old_address_3,CHR(255))
     ||NVL(p_old_city,CHR(255))
     ||NVL(p_old_province,CHR(255))
     ||NVL(p_old_postal_code,CHR(255)) !=
     NVL(p_new_address_1,CHR(255))
     ||NVL(p_new_address_2,CHR(255))
     ||NVL(p_new_address_3,CHR(255))
     ||NVL(p_new_city,CHR(255))
     ||NVL(p_new_province,CHR(255))
     ||NVL(p_new_postal_code,CHR(255)) THEN
      RETURN 'ADDR';
    ELSE
      RETURN NULL;
    END IF;
  END check_address;

  FUNCTION check_id
  (p_old_client_identification  IN VARCHAR2
  ,p_old_client_id_type_code    IN VARCHAR2
  ,p_new_client_identification  IN VARCHAR2
  ,p_new_client_id_type_code    IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    IF NVL(p_old_client_identification,CHR(255))||NVL(p_old_client_id_type_code,CHR(255)) !=
       NVL(p_new_client_identification,CHR(255))||NVL(p_new_client_id_type_code,CHR(255)) THEN
      RETURN 'ID';
    ELSE
      RETURN NULL;
    END IF;
  END check_id;

  FUNCTION check_status
  (p_old_client_status_code  IN VARCHAR2
  ,p_new_client_status_code  IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    IF NVL(p_old_client_status_code,CHR(255)) != NVL(p_new_client_status_code,CHR(255)) THEN
      IF p_new_client_status_code = 'SPN' THEN
        RETURN 'SPN';
      ELSIF p_new_client_status_code = 'DAC' THEN
        RETURN 'DAC';
      ELSIF p_old_client_status_code = 'SPN'
      AND p_new_client_status_code = 'ACT' THEN
        RETURN 'USPN';
      ELSIF p_old_client_status_code = 'DEC'
      AND p_new_client_status_code = 'ACT' THEN
        RETURN 'RACT';
      ELSIF p_old_client_status_code = 'DAC'
      AND p_new_client_status_code = 'ACT' THEN
        RETURN 'RACT';
      ELSE
        RETURN NULL;
      END IF;
    ELSE
      RETURN NULL;
    END IF;
  END check_status;

END client_client_update_reason;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "THE"."CLIENT_CODE_LISTS" 
IS
/******************************************************************************
    Package:    CLIENT_CODE_LISTS
    Purpose:    This package contains look-up table store procedures that is
                normally used by drop-down menu or list box in the JSP page of
                the CLIENT screens.

    Revision History
    Person               Date         Comments
    -----------------    ----------   --------------------------------
    Tim McClelland       2006-08-14   Created
    Elaine Wong          2006/12/18   Added Client related code lists.
                         2007/01/25   Added asterisks around expired client locations.
    Tim McClelland       2007/02/20   Added input param 'p_client_type_code to
                                      get_reg_company_type_codes().
    Tim McClelland       2007/08/31   Added p_client_type_code to
                                      get_client_update_reason_codes()
******************************************************************************/
  TYPE client_code_lists_cur IS REF CURSOR;

  PROCEDURE get_reorg_type_codes(
    p_reorg_type_code                IN OUT   client_code_lists_cur);

  PROCEDURE get_reorg_status_codes(
    p_reorg_status_code              IN OUT   client_code_lists_cur);

  PROCEDURE get_client_location_codes(
    p_client_number                  IN OUT   VARCHAR2
  , p_client_location_code           IN OUT   client_code_lists_cur);

  PROCEDURE get_client_status_codes(
    p_client_status_code             IN OUT   client_code_lists_cur);

  PROCEDURE get_client_type_codes(
    p_client_type_code               IN OUT   client_code_lists_cur);

  PROCEDURE get_client_relationship_codes(
    p_client_relationship_code       IN OUT   client_code_lists_cur);

  PROCEDURE get_business_contact_codes(
    p_business_contact_code          IN OUT   client_code_lists_cur);

  PROCEDURE get_reg_company_type_codes(
    p_client_type_code               IN       VARCHAR2
   ,p_reg_company_type_code          IN OUT   client_code_lists_cur);

  PROCEDURE get_client_update_reason_codes(
    p_client_update_action_code      IN      VARCHAR2
   ,p_client_type_code               IN   VARCHAR2
   ,p_client_update_reason_code      IN OUT   client_code_lists_cur);

  PROCEDURE get_client_id_type_codes(
    p_client_id_type_code            IN OUT   client_code_lists_cur);

  FUNCTION get_client_update_action_desc(
    p_client_update_action_code      IN   VARCHAR2)
  RETURN VARCHAR2;

  --ADDRESS
  -->Country
  PROCEDURE get_country(
    p_countries                      IN OUT   client_code_lists_cur);
  -->Prov/State
  PROCEDURE get_prov(
    p_country                        IN       VARCHAR2
  , p_provinces                      IN OUT   client_code_lists_cur);
  -->City
  PROCEDURE get_city(
    p_country                        IN       VARCHAR2
  , p_province                       IN       VARCHAR2
  , p_cities                         IN OUT   client_code_lists_cur);

  PROCEDURE get_valid_relationships
  ( p_client_type_code   IN VARCHAR2
   ,p_relationships      IN OUT client_code_lists_cur);

END client_code_lists;
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "THE"."CLIENT_CODE_LISTS" 
AS
  /*******************************************************************************
   * Procedure:  GET_REORG_TYPE_CODES                                            *
   *                                                                             *
   * Purpose:    To retrieve the list of client reorganization types.            *
   *******************************************************************************/
  PROCEDURE get_reorg_type_codes(
    p_reorg_type_code                IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_reorg_type_code
     FOR
        SELECT DISTINCT client_reorg_type_code reorg_type
            , description
            , sil_convert_to_char(effective_date, 'YYYY-MM-DD') effective_date
            , sil_convert_to_char(expiry_date, 'YYYY-MM-DD') expiry_date
        FROM client_reorg_type_code
        ORDER BY reorg_type;
  END get_reorg_type_codes;

  /*******************************************************************************
   * Procedure:  GET_REORG_STATUS_CODES                                          *
   *                                                                             *
   * Purpose:    To retrieve the list of client reorganization status codes.     *
   *******************************************************************************/
  PROCEDURE get_reorg_status_codes(
    p_reorg_status_code              IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_reorg_status_code
     FOR
        SELECT DISTINCT client_reorg_status_code reorg_status
            , description
            , sil_convert_to_char(effective_date, 'YYYY-MM-DD') effective_date
            , sil_convert_to_char(expiry_date, 'YYYY-MM-DD') expiry_date
        FROM client_reorg_status_code
        ORDER BY reorg_status;
  END get_reorg_status_codes;

  /*******************************************************************************
   * Procedure:  GET_CLIENT_LOCATION_CODES                                       *
   *                                                                             *
   * Purpose:    To retrieve the list of client location codes expired values    *
   *             will contain *s at the front and end of it.                     *
   *******************************************************************************/
  PROCEDURE get_client_location_codes(
     p_client_number             IN OUT   VARCHAR2
   , p_client_location_code              IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_client_location_code
     FOR
        SELECT DISTINCT client_locn_code
             , DECODE(locn_expired_ind, 'Y', '* ', '') ||
               client_locn_code||' - '||client_locn_name ||
               DECODE(locn_expired_ind, 'Y', ' *', '') client_locn_name
          FROM client_location
         WHERE client_number = p_client_number
         ORDER BY client_locn_code;
  END get_client_location_codes;

  /*******************************************************************************
   * Procedure:  GET_CLIENT_STATUS_CODES                                         *
   *                                                                             *
   * Purpose:    To retrieve the list of client status codes.                    *
   *******************************************************************************/
  PROCEDURE get_client_status_codes(
    p_client_status_code             IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_client_status_code
     FOR
       SELECT DISTINCT
              client_status_code
            , description
            , sil_convert_to_char(effective_date, 'YYYY-MM-DD') effective_date
            , sil_convert_to_char(expiry_date, 'YYYY-MM-DD') expiry_date
         FROM client_status_code
        ORDER BY description;
  END get_client_status_codes;

  /*******************************************************************************
   * Procedure:  GET_CLIENT_TYPE_CODES                                           *
   *                                                                             *
   * Purpose:    To retrieve the list of client type codes.                      *
   *******************************************************************************/
  PROCEDURE get_client_type_codes(
    p_client_type_code               IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_client_type_code
     FOR
       SELECT DISTINCT
              client_type_code
            , description
            , sil_convert_to_char(effective_date, 'YYYY-MM-DD') effective_date
            , sil_convert_to_char(expiry_date, 'YYYY-MM-DD') expiry_date
         FROM client_type_code
        ORDER BY description;
  END get_client_type_codes;

  /*******************************************************************************
   * Procedure:  GET_CLIENT_RELATIONSHIP_CODES                                   *
   *                                                                             *
   * Purpose:    To retrieve the list of client relationship codes.              *
   *******************************************************************************/
  PROCEDURE get_client_relationship_codes(
    p_client_relationship_code       IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_client_relationship_code
     FOR
       SELECT DISTINCT
              client_relationship_code
            , description
            , sil_convert_to_char(effective_date, 'YYYY-MM-DD') effective_date
            , sil_convert_to_char(expiry_date, 'YYYY-MM-DD') expiry_date
         FROM client_relationship_code
        ORDER BY description;
  END get_client_relationship_codes;

  /*******************************************************************************
   * Procedure:  GET_BUSINESS_CONTACT_CODES                                      *
   *                                                                             *
   * Purpose:    To retrieve the list of business contact codes.                 *
   *******************************************************************************/
  PROCEDURE get_business_contact_codes(
    p_business_contact_code          IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_business_contact_code
     FOR
       SELECT DISTINCT
              business_contact_code
            , description
            , sil_convert_to_char(effective_date, 'YYYY-MM-DD') effective_date
            , sil_convert_to_char(expiry_date, 'YYYY-MM-DD') expiry_date
         FROM business_contact_code
        ORDER BY description;
  END get_business_contact_codes;

  /*******************************************************************************
   * Procedure:  GET_REGISTRY_COMPANY_CODES                                      *
   *                                                                             *
   * Purpose:    To retrieve the list of registry company type codes.            *
   *******************************************************************************/
  PROCEDURE get_reg_company_type_codes(
    p_client_type_code               IN       VARCHAR2
   ,p_reg_company_type_code          IN OUT   client_code_lists_cur)
  IS
  BEGIN

    IF p_client_type_code IS NULL THEN
      OPEN p_reg_company_type_code
        FOR
         SELECT DISTINCT
                r.registry_company_type_code code
              , r.description description
              , sil_convert_to_char(effective_date, 'YYYY-MM-DD') effective_date
              , sil_convert_to_char(expiry_date, 'YYYY-MM-DD') expiry_date
           FROM registry_company_type_code r
          ORDER BY r.registry_company_type_code;
       ELSE
      OPEN p_reg_company_type_code
        FOR
         SELECT DISTINCT
                r.registry_company_type_code code
              , r.description description
              , sil_convert_to_char(effective_date, 'YYYY-MM-DD') effective_date
              , sil_convert_to_char(expiry_date, 'YYYY-MM-DD') expiry_date
           FROM client_type_company_xref x
              , registry_company_type_code r
          WHERE x.client_type_code = p_client_type_code
            AND r.registry_company_type_code = x.registry_company_type_code
          ORDER BY r.registry_company_type_code;
       END IF;
  END get_reg_company_type_codes;

  /*******************************************************************************
   * Procedure:  GET_CLIENT_UPDATE_REASON_CODES                                  *
   *                                                                             *
   * Purpose:    To retrieve the list of update reason codes for a given action  *
   *******************************************************************************/
  PROCEDURE get_client_update_reason_codes(
    p_client_update_action_code      IN       VARCHAR2
   ,p_client_type_code               IN       VARCHAR2
   ,p_client_update_reason_code      IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_client_update_reason_code
     FOR
       SELECT c.client_update_reason_code code
            , c.description description
            , sil_convert_to_char(c.effective_date, 'YYYY-MM-DD') effective_date
            , sil_convert_to_char(c.expiry_date, 'YYYY-MM-DD') expiry_date
         FROM client_action_reason_xref x
            , client_update_reason_code c
        WHERE x.client_update_action_code = p_client_update_action_code
          AND x.client_type_code = p_client_type_code
          AND c.client_update_reason_code = x.client_update_reason_code
        ORDER BY c.description;
  END get_client_update_reason_codes;

  /*******************************************************************************
   * Procedure:  GET_CLIENT_ID_TYPE_CODES                                        *
   *                                                                             *
   * Purpose:    To retrieve the list of client id type codes.                   *
   *******************************************************************************/
  PROCEDURE get_client_id_type_codes(
    p_client_id_type_code            IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_client_id_type_code
     FOR
       SELECT DISTINCT
              client_id_type_code
            , description
            , sil_convert_to_char(effective_date, 'YYYY-MM-DD') effective_date
            , sil_convert_to_char(expiry_date, 'YYYY-MM-DD') expiry_date
         FROM client_id_type_code
        ORDER BY description;
  END get_client_id_type_codes;

  /*******************************************************************************
   * Procedure:  GET_CLIENT_UPDATE_ACTION_DESC                                   *
   *                                                                             *
   * Purpose:    To retrieve the list of client id type codes.                   *
   *******************************************************************************/
  FUNCTION get_client_update_action_desc(
    p_client_update_action_code            IN   VARCHAR2)
  RETURN VARCHAR2
  IS
    CURSOR c_desc
    IS
      SELECT description
        FROM client_update_action_code
       WHERE client_update_action_code = p_client_update_action_code;
    r_desc        c_desc%ROWTYPE;
  BEGIN
    IF p_client_update_action_code IS NOT NULL THEN
      OPEN c_desc;
      FETCH c_desc INTO r_desc;
      CLOSE c_desc;
    END IF;
    RETURN r_desc.description;
  END get_client_update_action_desc;

  --ADDRESS
  -->Country
  PROCEDURE get_country(
    p_countries                      IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_countries
    FOR
      SELECT country_code code
           , country_name description
           , '0001-01-01' effective_date
           , '9999-12-31' expiry_date
        FROM mailing_country
       ORDER BY country_name;
  END get_country;
  -->Prov/State
  PROCEDURE get_prov(
    p_country                        IN       VARCHAR2
  , p_provinces                      IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_provinces
    FOR
      SELECT NVL(province_state_code,province_state_name) code
           , province_state_name||DECODE(province_state_code,NULL,NULL,'('||province_state_code||')') description
           , '0001-01-01' effective_date
           , '9999-12-31' expiry_date
        FROM mailing_province_state
       WHERE country_name = p_country
       ORDER BY province_state_name;
  END get_prov;
  -->City
  PROCEDURE get_city(
    p_country                        IN       VARCHAR2
  , p_province                       IN       VARCHAR2
  , p_cities                         IN OUT   client_code_lists_cur)
  IS
  BEGIN
    OPEN p_cities
    FOR
        SELECT city_name code
             , city_name description
             , '0001-01-01' effective_date
             , '9999-12-31' expiry_date
          FROM mailing_province_state p
             , mailing_city c
         WHERE c.country_name = p_country
           AND p.country_name = c.country_name
           AND p.province_state_name = c.province_state_name
           --because province could be the code or the name (if there is no code)
           AND (c.province_state_name = p_province
               OR p.province_state_code = p_province)
         ORDER BY city_name;
  END get_city;

 /******************************************************************************
    Procedure:  get_valid_relationships

    Purpose:    Get a list of relationships that are valid for a particular
                primary client type.
  ******************************************************************************/
  PROCEDURE get_valid_relationships (
     p_client_type_code IN VARCHAR2,
     p_relationships    IN OUT client_code_lists_cur)
  IS
  BEGIN
     OPEN p_relationships FOR
        SELECT distinct
               crc.client_relationship_code code,
               crc.description,
               crc.effective_date,
               crc.expiry_date
          FROM client_type_code ctc,
               client_relationship_type_xref crtx,
               client_relationship_code crc
         WHERE ctc.client_type_code = crtx.primary_client_type_code
           AND crc.client_relationship_code = crtx.client_relationship_code
           AND UPPER (ctc.client_type_code) = UPPER (p_client_type_code)
           ORDER BY crc.description ASC;

  END get_valid_relationships;


END client_code_lists;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "THE"."CLIENT_CLIENT_LOCATION" AS

  PROCEDURE get;

  PROCEDURE init
  ( p_client_number             IN VARCHAR2 DEFAULT NULL
  , p_client_locn_code          IN VARCHAR2 DEFAULT NULL);

  --***START GETTERS
  FUNCTION error_raised RETURN BOOLEAN;

  FUNCTION get_error_message RETURN SIL_ERROR_MESSAGES;

  FUNCTION get_client_number RETURN VARCHAR2;

  FUNCTION get_client_locn_code RETURN VARCHAR2;

  FUNCTION get_client_locn_name RETURN VARCHAR2;

  FUNCTION get_hdbs_company_code RETURN VARCHAR2;

  FUNCTION get_address_1 RETURN VARCHAR2;

  FUNCTION get_address_2 RETURN VARCHAR2;

  FUNCTION get_address_3 RETURN VARCHAR2;

  FUNCTION get_city RETURN VARCHAR2;

  FUNCTION get_province RETURN VARCHAR2;

  FUNCTION get_postal_code RETURN VARCHAR2;

  FUNCTION get_country RETURN VARCHAR2;

  FUNCTION get_business_phone RETURN VARCHAR2;

  FUNCTION get_home_phone RETURN VARCHAR2;

  FUNCTION get_cell_phone RETURN VARCHAR2;

  FUNCTION get_fax_number RETURN VARCHAR2;

  FUNCTION get_email_address RETURN VARCHAR2;

  FUNCTION get_locn_expired_ind RETURN VARCHAR2;

  FUNCTION get_returned_mail_date RETURN DATE;

  FUNCTION get_trust_location_ind RETURN VARCHAR2;

  FUNCTION get_cli_locn_comment RETURN VARCHAR2;

  FUNCTION get_update_timestamp RETURN DATE;

  FUNCTION get_update_userid RETURN VARCHAR2;

  FUNCTION get_update_org_unit RETURN NUMBER;

  FUNCTION get_add_timestamp RETURN DATE;

  FUNCTION get_add_userid RETURN VARCHAR2;

  FUNCTION get_add_org_unit RETURN NUMBER;

  FUNCTION get_revision_count RETURN NUMBER;

  FUNCTION get_ur_reason_addr RETURN VARCHAR2;
  --***END GETTERS

  --***START SETTERS

  PROCEDURE set_client_number(p_value IN VARCHAR2);

  PROCEDURE set_client_locn_code(p_value IN VARCHAR2);

  PROCEDURE set_client_locn_name(p_value IN VARCHAR2);

  PROCEDURE set_hdbs_company_code(p_value IN VARCHAR2);

  PROCEDURE set_address_1(p_value IN VARCHAR2);

  PROCEDURE set_address_2(p_value IN VARCHAR2);

  PROCEDURE set_address_3(p_value IN VARCHAR2);

  PROCEDURE set_city(p_value IN VARCHAR2);

  PROCEDURE set_province(p_value IN VARCHAR2);

  PROCEDURE set_postal_code(p_value IN VARCHAR2);

  PROCEDURE set_country(p_value IN VARCHAR2);

  PROCEDURE set_business_phone(p_value IN VARCHAR2);

  PROCEDURE set_home_phone(p_value IN VARCHAR2);

  PROCEDURE set_cell_phone(p_value IN VARCHAR2);

  PROCEDURE set_fax_number(p_value IN VARCHAR2);

  PROCEDURE set_email_address(p_value IN VARCHAR2);

  PROCEDURE set_locn_expired_ind(p_value IN VARCHAR2);

  PROCEDURE set_returned_mail_date(p_value IN DATE);

  PROCEDURE set_trust_location_ind(p_value IN VARCHAR2);

  PROCEDURE set_cli_locn_comment(p_value IN VARCHAR2);

  PROCEDURE set_update_timestamp(p_value IN DATE);

  PROCEDURE set_update_userid(p_value IN VARCHAR2);

  PROCEDURE set_update_org_unit(p_value IN NUMBER);

  PROCEDURE set_add_timestamp(p_value IN DATE);

  PROCEDURE set_add_userid(p_value IN VARCHAR2);

  PROCEDURE set_add_org_unit(p_value IN NUMBER);

  PROCEDURE set_revision_count(p_value IN NUMBER);
  --***END SETTERS

  PROCEDURE process_update_reasons
  (p_ur_action_addr         IN OUT VARCHAR2
  ,p_ur_reason_addr         IN OUT VARCHAR2);

  PROCEDURE validate;

  PROCEDURE validate_remove;

  PROCEDURE add;

  PROCEDURE change;

  PROCEDURE remove;

  PROCEDURE expire_nonexpired_locns
  ( p_client_number       IN VARCHAR2
  , p_update_userid       IN VARCHAR2
  , p_update_timestamp    IN DATE
  , p_update_org_unit_no  IN NUMBER);

  PROCEDURE unexpire_locns
  ( p_client_number       IN VARCHAR2
  , p_date_deactivated    IN DATE
  , p_update_userid       IN VARCHAR2
  , p_update_timestamp    IN DATE
  , p_update_org_unit_no  IN NUMBER
  , p_deactivated_date    IN DATE);

END client_client_location;
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "THE"."CLIENT_CLIENT_LOCATION" AS

  --member vars

  g_error_message                              SIL_ERROR_MESSAGES;

  g_client_number                              client_location.client_number%TYPE;
  gb_client_number                             VARCHAR2(1);

  g_client_locn_code                           client_location.client_locn_code%TYPE;
  gb_client_locn_code                          VARCHAR2(1);

  g_client_locn_name                           client_location.client_locn_name%TYPE;
  gb_client_locn_name                          VARCHAR2(1);

  g_hdbs_company_code                          client_location.hdbs_company_code%TYPE;
  gb_hdbs_company_code                         VARCHAR2(1);

  g_address_1                                  client_location.address_1%TYPE;
  gb_address_1                                 VARCHAR2(1);

  g_address_2                                  client_location.address_2%TYPE;
  gb_address_2                                 VARCHAR2(1);

  g_address_3                                  client_location.address_3%TYPE;
  gb_address_3                                 VARCHAR2(1);

  g_city                                       client_location.city%TYPE;
  gb_city                                      VARCHAR2(1);

  g_province                                   client_location.province%TYPE;
  gb_province                                  VARCHAR2(1);

  g_postal_code                                client_location.postal_code%TYPE;
  gb_postal_code                               VARCHAR2(1);

  g_country                                    client_location.country%TYPE;
  gb_country                                   VARCHAR2(1);

  g_business_phone                             client_location.business_phone%TYPE;
  gb_business_phone                            VARCHAR2(1);

  g_home_phone                                 client_location.home_phone%TYPE;
  gb_home_phone                                VARCHAR2(1);

  g_cell_phone                                 client_location.cell_phone%TYPE;
  gb_cell_phone                                VARCHAR2(1);

  g_fax_number                                 client_location.fax_number%TYPE;
  gb_fax_number                                VARCHAR2(1);

  g_email_address                              client_location.email_address%TYPE;
  gb_email_address                             VARCHAR2(1);

  g_locn_expired_ind                           client_location.locn_expired_ind%TYPE;
  gb_locn_expired_ind                          VARCHAR2(1);

  g_returned_mail_date                         client_location.returned_mail_date%TYPE;
  gb_returned_mail_date                        VARCHAR2(1);

  g_trust_location_ind                         client_location.trust_location_ind%TYPE;
  gb_trust_location_ind                        VARCHAR2(1);

  g_cli_locn_comment                           client_location.cli_locn_comment%TYPE;
  gb_cli_locn_comment                          VARCHAR2(1);

  g_update_timestamp                           client_location.update_timestamp%TYPE;
  gb_update_timestamp                          VARCHAR2(1);

  g_update_userid                              client_location.update_userid%TYPE;
  gb_update_userid                             VARCHAR2(1);

  g_update_org_unit                            client_location.update_org_unit%TYPE;
  gb_update_org_unit                           VARCHAR2(1);

  g_add_timestamp                              client_location.add_timestamp%TYPE;
  gb_add_timestamp                             VARCHAR2(1);

  g_add_userid                                 client_location.add_userid%TYPE;
  gb_add_userid                                VARCHAR2(1);

  g_add_org_unit                               client_location.add_org_unit%TYPE;
  gb_add_org_unit                              VARCHAR2(1);

  g_revision_count                             client_location.revision_count%TYPE;
  gb_revision_count                            VARCHAR2(1);

  --update reasons
  --> address change reason
  g_ur_action_addr                             client_action_reason_xref.client_update_action_code%TYPE;
  g_ur_reason_addr                             client_action_reason_xref.client_update_reason_code%TYPE;

  r_previous                                   client_location%ROWTYPE;

  C_MAX_CLIENT_LOCN_CODE              CONSTANT NUMBER := 99;

/******************************************************************************
    Procedure:  formatted_locn_code

    Purpose:    Format a numeric location code

******************************************************************************/
  FUNCTION formatted_locn_code
  (p_client_locn_code     IN NUMBER)
  RETURN VARCHAR2
  IS
  BEGIN

    RETURN TO_CHAR(p_client_locn_code,'FM00');

  END formatted_locn_code;

/******************************************************************************
    Procedure:  get_previous

    Purpose:    Get current client location info if not already retrieved

******************************************************************************/
  PROCEDURE get_previous
  IS
  BEGIN
    IF r_previous.client_number IS NULL THEN
      SELECT *
        INTO r_previous
        FROM client_location
       WHERE client_number = g_client_number
         AND client_locn_code = g_client_locn_code;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END get_previous;


/******************************************************************************
    Procedure:  get

    Purpose:    SELECT one row from CLIENT_LOCATION

******************************************************************************/
  PROCEDURE get
  IS
  BEGIN
    SELECT
           client_number
         , client_locn_code
         , client_locn_name
         , hdbs_company_code
         , address_1
         , address_2
         , address_3
         , city
         , province
         , postal_code
         , country
         , business_phone
         , home_phone
         , cell_phone
         , fax_number
         , email_address
         , locn_expired_ind
         , returned_mail_date
         , trust_location_ind
         , cli_locn_comment
         , update_timestamp
         , update_userid
         , update_org_unit
         , add_timestamp
         , add_userid
         , add_org_unit
         , revision_count
      INTO
           g_client_number
         , g_client_locn_code
         , g_client_locn_name
         , g_hdbs_company_code
         , g_address_1
         , g_address_2
         , g_address_3
         , g_city
         , g_province
         , g_postal_code
         , g_country
         , g_business_phone
         , g_home_phone
         , g_cell_phone
         , g_fax_number
         , g_email_address
         , g_locn_expired_ind
         , g_returned_mail_date
         , g_trust_location_ind
         , g_cli_locn_comment
         , g_update_timestamp
         , g_update_userid
         , g_update_org_unit
         , g_add_timestamp
         , g_add_userid
         , g_add_org_unit
         , g_revision_count
      FROM client_location
     WHERE client_number = g_client_number
       AND client_locn_code = g_client_locn_code;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;

  END get;

  --***START GETTERS

  --error raised?
  FUNCTION error_raised RETURN BOOLEAN
  IS
  BEGIN
    RETURN (g_error_message IS NOT NULL);
  END error_raised;

  --get error message
  FUNCTION get_error_message RETURN SIL_ERROR_MESSAGES
  IS
  BEGIN
    RETURN g_error_message;
  END get_error_message;

  --get client_number
  FUNCTION get_client_number RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_number;
  END get_client_number;

  --get client_locn_code
  FUNCTION get_client_locn_code RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_locn_code;
  END get_client_locn_code;

  --get client_locn_name
  FUNCTION get_client_locn_name RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_locn_name;
  END get_client_locn_name;

  --get hdbs_company_code
  FUNCTION get_hdbs_company_code RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_hdbs_company_code;
  END get_hdbs_company_code;

  --get address_1
  FUNCTION get_address_1 RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_address_1;
  END get_address_1;

  --get address_2
  FUNCTION get_address_2 RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_address_2;
  END get_address_2;

  --get address_3
  FUNCTION get_address_3 RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_address_3;
  END get_address_3;

  --get city
  FUNCTION get_city RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_city;
  END get_city;

  --get province
  FUNCTION get_province RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_province;
  END get_province;

  --get postal_code
  FUNCTION get_postal_code RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_postal_code;
  END get_postal_code;

  --get country
  FUNCTION get_country RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_country;
  END get_country;

  --get business_phone
  FUNCTION get_business_phone RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_business_phone;
  END get_business_phone;

  --get home_phone
  FUNCTION get_home_phone RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_home_phone;
  END get_home_phone;

  --get cell_phone
  FUNCTION get_cell_phone RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_cell_phone;
  END get_cell_phone;

  --get fax_number
  FUNCTION get_fax_number RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_fax_number;
  END get_fax_number;

  --get email_address
  FUNCTION get_email_address RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_email_address;
  END get_email_address;

  --get locn_expired_ind
  FUNCTION get_locn_expired_ind RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_locn_expired_ind;
  END get_locn_expired_ind;

  --get returned_mail_date
  FUNCTION get_returned_mail_date RETURN DATE
  IS
  BEGIN
    RETURN g_returned_mail_date;
  END get_returned_mail_date;

  --get trust_location_ind
  FUNCTION get_trust_location_ind RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_trust_location_ind;
  END get_trust_location_ind;

  --get cli_locn_comment
  FUNCTION get_cli_locn_comment RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_cli_locn_comment;
  END get_cli_locn_comment;

  --get update_timestamp
  FUNCTION get_update_timestamp RETURN DATE
  IS
  BEGIN
    RETURN g_update_timestamp;
  END get_update_timestamp;

  --get update_userid
  FUNCTION get_update_userid RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_update_userid;
  END get_update_userid;

  --get update_org_unit
  FUNCTION get_update_org_unit RETURN NUMBER
  IS
  BEGIN
    RETURN g_update_org_unit;
  END get_update_org_unit;

  --get add_timestamp
  FUNCTION get_add_timestamp RETURN DATE
  IS
  BEGIN
    RETURN g_add_timestamp;
  END get_add_timestamp;

  --get add_userid
  FUNCTION get_add_userid RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_add_userid;
  END get_add_userid;

  --get add_org_unit
  FUNCTION get_add_org_unit RETURN NUMBER
  IS
  BEGIN
    RETURN g_add_org_unit;
  END get_add_org_unit;

  --get revision_count
  FUNCTION get_revision_count RETURN NUMBER
  IS
  BEGIN
    RETURN g_revision_count;
  END get_revision_count;

  --get update reason code for address change
  FUNCTION get_ur_reason_addr RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_ur_reason_addr;
  END get_ur_reason_addr;
  --***END GETTERS

  --***START SETTERS

  --set client_number
  PROCEDURE set_client_number(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_number := p_value;
    gb_client_number := 'Y';
  END set_client_number;

  --set client_locn_code
  PROCEDURE set_client_locn_code(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_locn_code := p_value;
    gb_client_locn_code := 'Y';
  END set_client_locn_code;

  --set client_locn_name
  PROCEDURE set_client_locn_name(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_locn_name := p_value;
    gb_client_locn_name := 'Y';
  END set_client_locn_name;

  --set hdbs_company_code
  PROCEDURE set_hdbs_company_code(p_value IN VARCHAR2)
  IS
  BEGIN
    g_hdbs_company_code := p_value;
    gb_hdbs_company_code := 'Y';
  END set_hdbs_company_code;

  --set address_1
  PROCEDURE set_address_1(p_value IN VARCHAR2)
  IS
  BEGIN
    g_address_1 := p_value;
    gb_address_1 := 'Y';
  END set_address_1;

  --set address_2
  PROCEDURE set_address_2(p_value IN VARCHAR2)
  IS
  BEGIN
    g_address_2 := p_value;
    gb_address_2 := 'Y';
  END set_address_2;

  --set address_3
  PROCEDURE set_address_3(p_value IN VARCHAR2)
  IS
  BEGIN
    g_address_3 := p_value;
    gb_address_3 := 'Y';
  END set_address_3;

  --set city
  PROCEDURE set_city(p_value IN VARCHAR2)
  IS
  BEGIN
    g_city := p_value;
    gb_city := 'Y';
  END set_city;

  --set province
  PROCEDURE set_province(p_value IN VARCHAR2)
  IS
  BEGIN
    g_province := p_value;
    gb_province := 'Y';
  END set_province;

  --set postal_code
  PROCEDURE set_postal_code(p_value IN VARCHAR2)
  IS
  BEGIN
    g_postal_code := p_value;
    gb_postal_code := 'Y';
  END set_postal_code;

  --set country
  PROCEDURE set_country(p_value IN VARCHAR2)
  IS
  BEGIN
    g_country := p_value;
    gb_country := 'Y';
  END set_country;

  --set business_phone
  PROCEDURE set_business_phone(p_value IN VARCHAR2)
  IS
  BEGIN
    g_business_phone := p_value;
    gb_business_phone := 'Y';
  END set_business_phone;

  --set home_phone
  PROCEDURE set_home_phone(p_value IN VARCHAR2)
  IS
  BEGIN
    g_home_phone := p_value;
    gb_home_phone := 'Y';
  END set_home_phone;

  --set cell_phone
  PROCEDURE set_cell_phone(p_value IN VARCHAR2)
  IS
  BEGIN
    g_cell_phone := p_value;
    gb_cell_phone := 'Y';
  END set_cell_phone;

  --set fax_number
  PROCEDURE set_fax_number(p_value IN VARCHAR2)
  IS
  BEGIN
    g_fax_number := p_value;
    gb_fax_number := 'Y';
  END set_fax_number;

  --set email_address
  PROCEDURE set_email_address(p_value IN VARCHAR2)
  IS
  BEGIN
    g_email_address := p_value;
    gb_email_address := 'Y';
  END set_email_address;

  --set locn_expired_ind
  PROCEDURE set_locn_expired_ind(p_value IN VARCHAR2)
  IS
  BEGIN
    g_locn_expired_ind := p_value;
    gb_locn_expired_ind := 'Y';
  END set_locn_expired_ind;

  --set returned_mail_date
  PROCEDURE set_returned_mail_date(p_value IN DATE)
  IS
  BEGIN
    g_returned_mail_date := p_value;
    gb_returned_mail_date := 'Y';
  END set_returned_mail_date;

  --set trust_location_ind
  PROCEDURE set_trust_location_ind(p_value IN VARCHAR2)
  IS
  BEGIN
    g_trust_location_ind := p_value;
    gb_trust_location_ind := 'Y';
  END set_trust_location_ind;

  --set cli_locn_comment
  PROCEDURE set_cli_locn_comment(p_value IN VARCHAR2)
  IS
  BEGIN
    g_cli_locn_comment := p_value;
    gb_cli_locn_comment := 'Y';
  END set_cli_locn_comment;

  --set update_timestamp
  PROCEDURE set_update_timestamp(p_value IN DATE)
  IS
  BEGIN
    g_update_timestamp := p_value;
    gb_update_timestamp := 'Y';
  END set_update_timestamp;

  --set update_userid
  PROCEDURE set_update_userid(p_value IN VARCHAR2)
  IS
  BEGIN
    g_update_userid := p_value;
    gb_update_userid := 'Y';
  END set_update_userid;

  --set update_org_unit
  PROCEDURE set_update_org_unit(p_value IN NUMBER)
  IS
  BEGIN
    g_update_org_unit := p_value;
    gb_update_org_unit := 'Y';
  END set_update_org_unit;

  --set add_timestamp
  PROCEDURE set_add_timestamp(p_value IN DATE)
  IS
  BEGIN
    g_add_timestamp := p_value;
    gb_add_timestamp := 'Y';
  END set_add_timestamp;

  --set add_userid
  PROCEDURE set_add_userid(p_value IN VARCHAR2)
  IS
  BEGIN
    g_add_userid := p_value;
    gb_add_userid := 'Y';
  END set_add_userid;

  --set add_org_unit
  PROCEDURE set_add_org_unit(p_value IN NUMBER)
  IS
  BEGIN
    g_add_org_unit := p_value;
    gb_add_org_unit := 'Y';
  END set_add_org_unit;

  --set revision_count
  PROCEDURE set_revision_count(p_value IN NUMBER)
  IS
  BEGIN
    g_revision_count := p_value;
    gb_revision_count := 'Y';
  END set_revision_count;
  --***END SETTERS

/******************************************************************************
    Procedure:  init

    Purpose:    Initialize member variables

******************************************************************************/
  PROCEDURE init
  ( p_client_number             IN VARCHAR2 DEFAULT NULL
  , p_client_locn_code          IN VARCHAR2 DEFAULT NULL)
  IS
    r_previous_empty      client_location%ROWTYPE;
  BEGIN

    g_error_message := NULL;

    g_client_number := NULL;
    gb_client_number := 'N';

    g_client_locn_code := NULL;
    gb_client_locn_code := 'N';

    g_client_locn_name := NULL;
    gb_client_locn_name := 'N';

    g_hdbs_company_code := NULL;
    gb_hdbs_company_code := 'N';

    g_address_1 := NULL;
    gb_address_1 := 'N';

    g_address_2 := NULL;
    gb_address_2 := 'N';

    g_address_3 := NULL;
    gb_address_3 := 'N';

    g_city := NULL;
    gb_city := 'N';

    g_province := NULL;
    gb_province := 'N';

    g_postal_code := NULL;
    gb_postal_code := 'N';

    g_country := NULL;
    gb_country := 'N';

    g_business_phone := NULL;
    gb_business_phone := 'N';

    g_home_phone := NULL;
    gb_home_phone := 'N';

    g_cell_phone := NULL;
    gb_cell_phone := 'N';

    g_fax_number := NULL;
    gb_fax_number := 'N';

    g_email_address := NULL;
    gb_email_address := 'N';

    g_locn_expired_ind := NULL;
    gb_locn_expired_ind := 'N';

    g_returned_mail_date := NULL;
    gb_returned_mail_date := 'N';

    g_trust_location_ind := NULL;
    gb_trust_location_ind := 'N';

    g_cli_locn_comment := NULL;
    gb_cli_locn_comment := 'N';

    g_update_timestamp := NULL;
    gb_update_timestamp := 'N';

    g_update_userid := NULL;
    gb_update_userid := 'N';

    g_update_org_unit := NULL;
    gb_update_org_unit := 'N';

    g_add_timestamp := NULL;
    gb_add_timestamp := 'N';

    g_add_userid := NULL;
    gb_add_userid := 'N';

    g_add_org_unit := NULL;
    gb_add_org_unit := 'N';

    g_revision_count := NULL;
    gb_revision_count := 'N';

    g_ur_action_addr := NULL;
    g_ur_reason_addr := NULL;

    r_previous := r_previous_empty;

    IF p_client_locn_code IS NOT NULL
    OR p_client_number IS NOT NULL THEN
      set_client_number(p_client_number);
      set_client_locn_code(p_client_locn_code);
      get;
    END IF;
  END init;

/******************************************************************************
    Procedure:  validate_trust

    Purpose:    Validate trust location indicator

******************************************************************************/
  PROCEDURE validate_trust
  IS
  BEGIN

    IF g_trust_location_ind = 'Y' THEN

      IF g_locn_expired_ind != 'Y' THEN
        --Trust Location must be Expired
        client_utils.add_error(g_error_message
                             , 'trust_location_ind'
                             , 'client.web.usr.database.trust.exp');
      END IF;

      IF g_client_locn_code = '00' THEN
        --cannot set 00 location as trust location
        client_utils.add_error(g_error_message
                             , 'trust_location_ind'
                             , 'client.web.usr.database.trust.00');
      END IF;
    END IF;

  END validate_trust;

/******************************************************************************
    Procedure:  validate_locn_expired_ind

    Purpose:    Validate location expired ind

******************************************************************************/
  PROCEDURE validate_locn_expired_ind
  IS
    CURSOR c_00
    IS
      SELECT l.locn_expired_ind
           , c.client_status_code
        FROM client_location l
           , forest_client c
       WHERE l.client_number = g_client_number
         AND l.client_locn_code = '00'
         AND c.client_number = l.client_number;
    r_00 c_00%ROWTYPE;
  BEGIN

    IF g_locn_expired_ind = 'Y' THEN
      IF r_previous.locn_expired_ind = 'N' AND g_client_locn_code = '00' THEN
        --cannot expire 00 location
        client_utils.add_error(g_error_message
                             , 'locn_expired_ind'
                             , 'client.web.usr.database.exp.00');
      END IF;
    ELSE --exp=N
      --unexpiring
      IF r_previous.locn_expired_ind = 'Y' THEN
        --cannot unexpire if 00 locn is expired
        OPEN c_00;
        FETCH c_00 INTO r_00;
        CLOSE c_00;
        IF r_00.locn_expired_ind = 'Y' THEN
          --cannot unexpire when 00 location is expired
          client_utils.add_error(g_error_message
                               , 'locn_expired_ind'
                               , 'client.web.usr.database.unexp.00');
        END IF;
        IF r_00.client_status_code = 'DAC' THEN
          --cannot expire 00 location
          client_utils.add_error(g_error_message
                               , 'locn_expired_ind'
                               , 'client.web.usr.database.unexp.dac');
        END IF;
      END IF;
    END IF;

  END validate_locn_expired_ind;


/******************************************************************************
    Procedure:  phone_number_is_valid

    Purpose:    Apply phone number mask and return TRUE if passed telephone
                number is valid, otherwise return FALSE.

******************************************************************************/
  FUNCTION phone_number_is_valid
  (p_phone  IN VARCHAR2)
  RETURN BOOLEAN
  IS
  BEGIN

    IF p_phone IS NULL THEN
      RETURN NULL;
    ELSIF TRANSLATE(p_phone,'1234567890','NNNNNNNNNN') != 'NNNNNNNNNN' THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;

  END phone_number_is_valid;


/******************************************************************************
    Procedure:  validate_telephone

    Purpose:    Validate telephone numbers

******************************************************************************/
  PROCEDURE validate_telephone
  IS
  BEGIN
    IF NOT phone_number_is_valid(g_business_phone) THEN
        client_utils.add_error(g_error_message
                         , 'business_phone'
                         , 'client.web.usr.database.phone'
                         , sil_error_params('Business Phone'));
    END IF;
    IF NOT phone_number_is_valid(g_home_phone) THEN
        client_utils.add_error(g_error_message
                         , 'home_phone'
                         , 'client.web.usr.database.phone'
                         , sil_error_params('Residence Phone'));
    END IF;
    IF NOT phone_number_is_valid(g_cell_phone) THEN
        client_utils.add_error(g_error_message
                         , 'cell_phone'
                         , 'client.web.usr.database.phone'
                         , sil_error_params('Cell Phone'));
    END IF;
    IF NOT phone_number_is_valid(g_fax_number) THEN
        client_utils.add_error(g_error_message
                         , 'fax_number'
                         , 'client.web.usr.database.phone'
                         , sil_error_params('Fax Number'));
    END IF;

  END validate_telephone;


/******************************************************************************
    Procedure:  validate_postal_code

    Purpose:    Apply postal code masks for known countries

******************************************************************************/
  PROCEDURE validate_postal_code
  IS
  BEGIN

    IF g_country = 'CANADA'
    AND TRANSLATE(g_postal_code,'1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ','NNNNNNNNNNAAAAAAAAAAAAAAAAAAAAAAAAAA') != 'ANANAN' THEN
        client_utils.add_error(g_error_message
                         , 'country'
                         , 'client.web.usr.database.postal.code.mask'
                         , sil_error_params(g_country));
    ELSIF g_country = 'U.S.A.'
    AND TRANSLATE(g_postal_code,'1234567890','NNNNNNNNNN') NOT IN ('NNNNN','NNNNN-NNNN') THEN
        client_utils.add_error(g_error_message
                         , 'country'
                         , 'client.web.usr.database.postal.code.mask'
                         , sil_error_params(g_country));
    END IF;

  END validate_postal_code;


/******************************************************************************
    Procedure:  validate_address

    Purpose:    Validate city, prov/state, country combinations

******************************************************************************/
  PROCEDURE validate_address
  IS
    CURSOR c_country
    IS
      SELECT c.country_name
           , COUNT(mps.province_state_code) prov_count
           , COUNT(DECODE(mps.province_state_code,g_province,1,NULL)) matches_found
        FROM mailing_country c
           , mailing_province_state mps
       WHERE c.country_name = g_country
         AND mps.country_name(+) = c.country_name
       GROUP BY c.country_name;
    r_country                 c_country%ROWTYPE;

    CURSOR c_city
    IS
      SELECT COUNT(1) city_count
           , COUNT(DECODE(city_name,g_city,1,NULL)) matches_found
        FROM mailing_city
       WHERE country_name = g_country
         AND province_state_name = g_province
       GROUP BY country_name
              , province_state_name;
    r_city                    c_city%ROWTYPE;

  BEGIN
    IF g_country IS NOT NULL THEN
      OPEN c_country;
      FETCH c_country INTO r_country;
      CLOSE c_country;

      --if country not found
      IF r_country.country_name IS NULL THEN
        client_utils.add_error(g_error_message
                         , 'country'
                         , 'client.web.usr.database.country.nrf');
      ELSE
        --COUNTRY IS VALID
        -->if any provinces/states exist for the country then the province specified must exist (else freeform)
        IF r_country.prov_count > 0 THEN
          IF r_country.matches_found = 0 THEN
            -->province/state could not be found for the country
            client_utils.add_error(g_error_message
                         , 'province'
                         , 'client.web.usr.database.state.nrf');
          ELSE
            -->if any cities exist for the province/state and country then city specified must exist (else freeform)
            OPEN c_city;
            FETCH c_city INTO r_city;
            CLOSE c_city;

            IF r_city.city_count > 0
            AND r_city.matches_found = 0 THEN
              --city could not be found for the province/state
                client_utils.add_error(g_error_message
                         , 'city'
                         , 'client.web.usr.database.city.nrf');
            END IF;
          END IF;
        END IF;

        validate_postal_code;
      END IF;


    END IF;


  END validate_address;


/******************************************************************************
    Procedure:  validate_mandatories

    Purpose:    Validate optionality

******************************************************************************/
  PROCEDURE validate_mandatories
  IS
  BEGIN
/* Because Client and Location validations are combined on CLIENT02,
   this message was confusing users when client validations failed and a
   number was not generated and passed-on.

    IF g_client_number IS NULL THEN
        client_utils.add_error(g_error_message
                         , 'client_number'
                         , 'sil.error.usr.isrequired'
                         , sil_error_params('Client Number'));
    END IF;
*/

/* Location Code generated so don't validate here */

/* Will default to a space if not provided so don't validate here
    IF g_hdbs_company_code IS NULL THEN
        client_utils.add_error(g_error_message
                         , 'hdbs_company_code'
                         , 'sil.error.usr.isrequired'
                         , sil_error_params('HDBS Company Code'));
    END IF;
*/
    IF g_address_1 IS NULL THEN
        client_utils.add_error(g_error_message
                         , 'address_1'
                         , 'sil.error.usr.isrequired'
                         , sil_error_params('Address'));
    END IF;
    IF g_city IS NULL THEN
        client_utils.add_error(g_error_message
                         , 'city'
                         , 'sil.error.usr.isrequired'
                         , sil_error_params('City'));
    END IF;
    IF g_country IS NULL THEN
        client_utils.add_error(g_error_message
                         , 'country'
                         , 'sil.error.usr.isrequired'
                         , sil_error_params('Country'));
    END IF;

/* Indicators will default
    IF g_locn_expired_ind IS NULL THEN
        client_utils.add_error(g_error_message
                         , 'locn_expired_ind'
                         , 'sil.error.usr.isrequired'
                         , sil_error_params('Location Expired Ind'));
    END IF;
    IF g_trust_location_ind IS NULL THEN
        client_utils.add_error(g_error_message
                         , 'trust_location_ind'
                         , 'sil.error.usr.isrequired'
                         , sil_error_params('Trust Location Ind'));
    END IF;
*/
  END validate_mandatories;


/******************************************************************************
    Procedure:  process_update_reasons

    Purpose:    Certain changes require a reason to be specified

******************************************************************************/
  PROCEDURE process_update_reasons
  (p_ur_action_addr         IN OUT VARCHAR2
  ,p_ur_reason_addr        IN OUT VARCHAR2)
  IS
    v_client_update_action_code  client_update_reason.client_update_action_code%TYPE;
    e_reason_not_required        EXCEPTION;
  BEGIN
    --Only for updates
    IF g_client_number IS NOT NULL
    AND g_client_locn_code IS NOT NULL
    AND g_revision_count IS NOT NULL THEN
      get_previous;

      --set globals
      g_ur_action_addr := p_ur_action_addr;
      g_ur_reason_addr := p_ur_reason_addr;

      --Address changes
      v_client_update_action_code := NULL;
      IF gb_address_1 = 'Y'
      OR gb_address_2 = 'Y'
      OR gb_address_3 = 'Y'
      OR gb_city = 'Y'
      OR gb_province = 'Y'
      OR gb_country = 'Y' THEN
        v_client_update_action_code := client_client_update_reason.check_address
                                      (--old
                                       r_previous.address_1
                                      ,r_previous.address_2
                                      ,r_previous.address_3
                                      ,r_previous.city
                                      ,r_previous.province
                                      ,r_previous.postal_code
                                      ,r_previous.country
                                       --new
                                      ,g_address_1
                                      ,g_address_2
                                      ,g_address_3
                                      ,g_city
                                      ,g_province
                                      ,g_postal_code
                                      ,g_country);
        IF v_client_update_action_code IS NOT NULL THEN
          g_ur_action_addr := v_client_update_action_code;
          IF g_ur_reason_addr IS NULL THEN
            --"Please provide an update reason for the following change: {0}"
            client_utils.add_error(g_error_message
                            , 'address_1'
                            , 'client.web.error.update.reason'
                            , sil_error_params(client_code_lists.get_client_update_action_desc(v_client_update_action_code)));
          END IF;
        ELSIF g_ur_reason_addr IS NOT NULL THEN
          RAISE e_reason_not_required;
        END IF;
      END IF;

      --return globals
      p_ur_action_addr := g_ur_action_addr;
      p_ur_reason_addr := g_ur_reason_addr;

    END IF; --if updating

  EXCEPTION
    WHEN e_reason_not_required THEN
      RAISE_APPLICATION_ERROR(-20200,'Reason provided but no corresponding change noted.');

  END process_update_reasons;

/******************************************************************************
    Procedure:  validate

    Purpose:    Column validators

******************************************************************************/
  PROCEDURE validate
  IS
  BEGIN
    get_previous;

    validate_mandatories;

    validate_address;

    validate_telephone;

    validate_locn_expired_ind;

    validate_trust;

  END validate;


/******************************************************************************
    Procedure:  validate_remove

    Purpose:    DELETE validations - check for child records, etc.

******************************************************************************/
  PROCEDURE validate_remove
  IS
  BEGIN
    --Cannot delete client locations - expire it instead
    RAISE_APPLICATION_ERROR(-20200,'client_client_location.validate_remove: Client Locations may not be deleted');
  END validate_remove;


/******************************************************************************
    Procedure:  get_next_location

    Purpose:    Derive next client location code for insert

******************************************************************************/
  FUNCTION get_next_location
  RETURN VARCHAR2
  IS
    CURSOR c_next
    IS
      SELECT TO_NUMBER(MAX(client_locn_code)) + 1 client_locn_code
        FROM client_location
       WHERE client_number = g_client_number;
    r_next                c_next%ROWTYPE;

  BEGIN

    OPEN c_next;
    FETCH c_next INTO r_next;
    CLOSE c_next;

    IF r_next.client_locn_code IS NULL THEN
      --00 location
      r_next.client_locn_code := 0;
    ELSIF r_next.client_locn_code > C_MAX_CLIENT_LOCN_CODE THEN
      --will not fit in 2 chars - cannot generate
      RAISE_APPLICATION_ERROR(-20200,'Cannot generate next Client Location Code - max has been reached.');
    END IF;

    RETURN formatted_locn_code(r_next.client_locn_code);

  END get_next_location;


/******************************************************************************
    Procedure:  add

    Purpose:    INSERT one row into CLIENT_LOCATION

******************************************************************************/
  PROCEDURE add
  IS
    v_client_locn_code              client_location.client_locn_code%TYPE;
  BEGIN
    v_client_locn_code := get_next_location;

    --So as not to impact HBS, set HDBS Company Code to a space if not provided
    --as it would have been in CLI
    g_hdbs_company_code := NVL(g_hdbs_company_code,' ');

    --Default indicators if not provided
    g_locn_expired_ind := NVL(g_locn_expired_ind,'N');
    g_trust_location_ind := NVL(g_trust_location_ind,'N');


    INSERT INTO client_location
       ( client_number
       , client_locn_code
       , client_locn_name
       , hdbs_company_code
       , address_1
       , address_2
       , address_3
       , city
       , province
       , postal_code
       , country
       , business_phone
       , home_phone
       , cell_phone
       , fax_number
       , email_address
       , locn_expired_ind
       , returned_mail_date
       , trust_location_ind
       , cli_locn_comment
       , update_timestamp
       , update_userid
       , update_org_unit
       , add_timestamp
       , add_userid
       , add_org_unit
       , revision_count
       )
     VALUES
       ( g_client_number
       , v_client_locn_code
       , g_client_locn_name
       , g_hdbs_company_code
       , g_address_1
       , g_address_2
       , g_address_3
       , g_city
       , g_province
       , g_postal_code
       , g_country
       , g_business_phone
       , g_home_phone
       , g_cell_phone
       , g_fax_number
       , g_email_address
       , g_locn_expired_ind
       , g_returned_mail_date
       , g_trust_location_ind
       , g_cli_locn_comment
       , g_update_timestamp
       , g_update_userid
       , g_update_org_unit
       , g_add_timestamp
       , g_add_userid
       , g_add_org_unit
       , g_revision_count
      )
      RETURNING client_number
              , client_locn_code
           INTO g_client_number
              , g_client_locn_code;
  END add;


/******************************************************************************
    Procedure:  change

    Purpose:    UPDATE one row in CLIENT_LOCATION

******************************************************************************/
  PROCEDURE change
  IS
  BEGIN
    UPDATE client_location
       SET client_locn_name = DECODE(gb_client_locn_name,'Y',g_client_locn_name,client_locn_name)
--      IGNORING SO AS NOT TO IMPACT HBS
--      , hdbs_company_code = DECODE(gb_hdbs_company_code,'Y',g_hdbs_company_code,hdbs_company_code)
         , address_1 = DECODE(gb_address_1,'Y',g_address_1,address_1)
         , address_2 = DECODE(gb_address_2,'Y',g_address_2,address_2)
         , address_3 = DECODE(gb_address_3,'Y',g_address_3,address_3)
         , city = DECODE(gb_city,'Y',g_city,city)
         , province = DECODE(gb_province,'Y',g_province,province)
         , postal_code = DECODE(gb_postal_code,'Y',g_postal_code,postal_code)
         , country = DECODE(gb_country,'Y',g_country,country)
         , business_phone = DECODE(gb_business_phone,'Y',g_business_phone,business_phone)
         , home_phone = DECODE(gb_home_phone,'Y',g_home_phone,home_phone)
         , cell_phone = DECODE(gb_cell_phone,'Y',g_cell_phone,cell_phone)
         , fax_number = DECODE(gb_fax_number,'Y',g_fax_number,fax_number)
         , email_address = DECODE(gb_email_address,'Y',g_email_address,email_address)
         , locn_expired_ind = DECODE(gb_locn_expired_ind,'Y',g_locn_expired_ind,locn_expired_ind)
         , returned_mail_date = DECODE(gb_returned_mail_date,'Y',g_returned_mail_date,returned_mail_date)
         , trust_location_ind = DECODE(gb_trust_location_ind,'Y',g_trust_location_ind,trust_location_ind)
         , cli_locn_comment = DECODE(gb_cli_locn_comment,'Y',g_cli_locn_comment,cli_locn_comment)
         , update_timestamp = g_update_timestamp
         , update_userid = g_update_userid
         , update_org_unit = DECODE(gb_update_org_unit,'Y',g_update_org_unit,update_org_unit)
         , revision_count = revision_count + 1
     WHERE client_number = g_client_number
       AND client_locn_code = g_client_locn_code
       AND revision_count = g_revision_count
     RETURNING revision_count
          INTO g_revision_count;
  END change;


/******************************************************************************
    Procedure:  remove

    Purpose:    DELETE one row from CLIENT_LOCATION

******************************************************************************/
  PROCEDURE remove
  IS
  BEGIN
    --Cannot delete client locations - expire it instead
    RAISE_APPLICATION_ERROR(-20200,'client_client_location.remove: Client Locations may not be deleted');
  END remove;

--*START STATIC METHODS

/******************************************************************************
    Procedure:  expire_nonexpired_locns

    Purpose:    Set locn_expired_ind for all nonexpired locations of p_client_number

******************************************************************************/
  PROCEDURE expire_nonexpired_locns
  ( p_client_number       IN VARCHAR2
  , p_update_userid       IN VARCHAR2
  , p_update_timestamp    IN DATE
  , p_update_org_unit_no  IN NUMBER)
  IS
  BEGIN
    UPDATE client_location
       SET locn_expired_ind = 'Y'
         , update_timestamp = p_update_timestamp
         , update_userid = p_update_userid
         , update_org_unit = p_update_org_unit_no
         , revision_count = revision_count + 1
     WHERE client_number = p_client_number
       AND locn_expired_ind = 'N';

  END expire_nonexpired_locns;

/******************************************************************************
    Procedure:  unexpire_locns

    Purpose:    Set locn_expired_ind for all locations expired on a certain
                date.
                *The assumption is that the client cannot be updated
                once it is set to DAC so the update_timestamp on the client
                record should match the update_timestamp on the expired
                locations.
                * This assumption is no longer valid since deactivated clients can
                now be updated.  We have to look to the audit table to get the
                appropriate date in which the client was deactivated, and compare
                it with the location expiry date.

******************************************************************************/
  PROCEDURE unexpire_locns
  ( p_client_number       IN VARCHAR2
  , p_date_deactivated    IN DATE
  , p_update_userid       IN VARCHAR2
  , p_update_timestamp    IN DATE
  , p_update_org_unit_no  IN NUMBER
  , p_deactivated_date    IN DATE)
  IS
  BEGIN

    UPDATE client_location
       SET locn_expired_ind = 'N'
         , update_timestamp = p_update_timestamp
         , update_userid = p_update_userid
         , update_org_unit = p_update_org_unit_no
         , revision_count = revision_count + 1
     WHERE client_number = p_client_number
       AND locn_expired_ind = 'Y'
       AND client_locn_code IN
       (SELECT client_locn_code
          FROM cli_locn_audit
         WHERE client_number = p_client_number
           AND locn_expired_ind = 'Y'
           AND update_timestamp = p_deactivated_date);

  END unexpire_locns;

--*END STATIC METHODS

END client_client_location;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "THE"."CLIENT_FOREST_CLIENT" AS

  --Client type constants
  C_CLIENT_TYPE_INDIVIDUAL      CONSTANT forest_client.client_type_code%TYPE := 'I';
  C_CLIENT_TYPE_ASSOCIATION     CONSTANT forest_client.client_type_code%TYPE := 'A';
  C_CLIENT_TYPE_CORPORATION     CONSTANT forest_client.client_type_code%TYPE := 'C';
  C_CLIENT_TYPE_SOCIETY         CONSTANT forest_client.client_type_code%TYPE := 'S';

  --Client id type constants
  C_CLIENT_ID_TYPE_BC_DRIVERS   CONSTANT forest_client.client_id_type_code%TYPE := 'BCDL';

  --Can be used to declare standard client name
  std_client_name_type              VARCHAR2(125);

  PROCEDURE get;

  PROCEDURE init
  (p_client_number          IN VARCHAR2 DEFAULT NULL);

  --***START GETTERS
  FUNCTION error_raised RETURN BOOLEAN;

  FUNCTION get_error_message RETURN SIL_ERROR_MESSAGES;

  FUNCTION get_client_number RETURN VARCHAR2;

  FUNCTION get_client_name RETURN VARCHAR2;

  FUNCTION get_legal_first_name RETURN VARCHAR2;

  FUNCTION get_legal_middle_name RETURN VARCHAR2;

  FUNCTION get_client_status_code RETURN VARCHAR2;

  FUNCTION get_client_type_code RETURN VARCHAR2;

  FUNCTION get_birthdate RETURN DATE;

  FUNCTION get_client_id_type_code RETURN VARCHAR2;

  FUNCTION get_client_identification RETURN VARCHAR2;

  FUNCTION get_registry_company_type_code RETURN VARCHAR2;

  FUNCTION get_corp_regn_nmbr RETURN VARCHAR2;

  FUNCTION get_client_acronym RETURN VARCHAR2;

  FUNCTION get_wcb_firm_number RETURN VARCHAR2;

  FUNCTION get_ocg_supplier_nmbr RETURN VARCHAR2;

  FUNCTION get_client_comment RETURN VARCHAR2;

  FUNCTION get_add_timestamp RETURN DATE;

  FUNCTION get_add_userid RETURN VARCHAR2;

  FUNCTION get_add_org_unit RETURN NUMBER;

  FUNCTION get_update_timestamp RETURN DATE;

  FUNCTION get_update_userid RETURN VARCHAR2;

  FUNCTION get_update_org_unit RETURN NUMBER;

  FUNCTION get_revision_count RETURN NUMBER;

  FUNCTION get_ur_reason_status RETURN VARCHAR2;
  FUNCTION get_ur_reason_name RETURN VARCHAR2;
  FUNCTION get_ur_reason_id RETURN VARCHAR2;

  --***END GETTERS

  --***START SETTERS
  FUNCTION get_client_display_name
  (p_client_number              IN VARCHAR2 DEFAULT NULL)
  RETURN std_client_name_type%TYPE;

  PROCEDURE set_client_number(p_value IN VARCHAR2);

  PROCEDURE set_client_name(p_value IN VARCHAR2);

  PROCEDURE set_legal_first_name(p_value IN VARCHAR2);

  PROCEDURE set_legal_middle_name(p_value IN VARCHAR2);

  PROCEDURE set_client_status_code(p_value IN VARCHAR2);

  PROCEDURE set_client_type_code(p_value IN VARCHAR2);

  PROCEDURE set_birthdate(p_value IN DATE);

  PROCEDURE set_client_id_type_code(p_value IN VARCHAR2);

  PROCEDURE set_client_identification(p_value IN VARCHAR2);

  PROCEDURE set_registry_company_type_code(p_value IN VARCHAR2);

  PROCEDURE set_corp_regn_nmbr(p_value IN VARCHAR2);

  PROCEDURE set_client_acronym(p_value IN VARCHAR2);

  PROCEDURE set_wcb_firm_number(p_value IN VARCHAR2);

  PROCEDURE set_ocg_supplier_nmbr(p_value IN VARCHAR2);

  PROCEDURE set_client_comment(p_value IN VARCHAR2);

  PROCEDURE set_add_timestamp(p_value IN DATE);

  PROCEDURE set_add_userid(p_value IN VARCHAR2);

  PROCEDURE set_add_org_unit(p_value IN NUMBER);

  PROCEDURE set_update_timestamp(p_value IN DATE);

  PROCEDURE set_update_userid(p_value IN VARCHAR2);

  PROCEDURE set_update_org_unit(p_value IN NUMBER);

  PROCEDURE set_revision_count(p_value IN NUMBER);

  --***END SETTERS

  FUNCTION formatted_client_number
  (p_client_number IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION formatted_client_number
  (p_client_number IN NUMBER)
  RETURN VARCHAR2;

  PROCEDURE process_update_reasons
  (p_ur_action_status       IN OUT VARCHAR2
  ,p_ur_reason_status       IN OUT VARCHAR2
  ,p_ur_action_name         IN OUT VARCHAR2
  ,p_ur_reason_name         IN OUT VARCHAR2
  ,p_ur_action_id           IN OUT VARCHAR2
  ,p_ur_reason_id           IN OUT VARCHAR2);

  PROCEDURE validate;

  PROCEDURE validate_remove;

  PROCEDURE add;

  PROCEDURE change;

  PROCEDURE remove;

END client_forest_client;
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "THE"."CLIENT_FOREST_CLIENT" AS

  --member vars

  g_error_message                              SIL_ERROR_MESSAGES;

  g_client_number                              forest_client.client_number%TYPE;
  gb_client_number                             VARCHAR2(1);

  g_client_name                                forest_client.client_name%TYPE;
  gb_client_name                               VARCHAR2(1);

  g_legal_first_name                           forest_client.legal_first_name%TYPE;
  gb_legal_first_name                          VARCHAR2(1);

  g_legal_middle_name                          forest_client.legal_middle_name%TYPE;
  gb_legal_middle_name                         VARCHAR2(1);

  g_client_status_code                         forest_client.client_status_code%TYPE;
  gb_client_status_code                        VARCHAR2(1);

  g_client_type_code                           forest_client.client_type_code%TYPE;
  gb_client_type_code                          VARCHAR2(1);

  g_birthdate                                  forest_client.birthdate%TYPE;
  gb_birthdate                                 VARCHAR2(1);

  g_client_id_type_code                        forest_client.client_id_type_code%TYPE;
  gb_client_id_type_code                       VARCHAR2(1);

  g_client_identification                      forest_client.client_identification%TYPE;
  gb_client_identification                     VARCHAR2(1);

  g_registry_company_type_code                 forest_client.registry_company_type_code%TYPE;
  gb_registry_company_type_code                VARCHAR2(1);

  g_corp_regn_nmbr                             forest_client.corp_regn_nmbr%TYPE;
  gb_corp_regn_nmbr                            VARCHAR2(1);

  g_client_acronym                             forest_client.client_acronym%TYPE;
  gb_client_acronym                            VARCHAR2(1);

  g_wcb_firm_number                            forest_client.wcb_firm_number%TYPE;
  gb_wcb_firm_number                           VARCHAR2(1);

  g_ocg_supplier_nmbr                          forest_client.ocg_supplier_nmbr%TYPE;
  gb_ocg_supplier_nmbr                         VARCHAR2(1);

  g_client_comment                             forest_client.client_comment%TYPE;
  gb_client_comment                            VARCHAR2(1);

  g_add_timestamp                              forest_client.add_timestamp%TYPE;
  gb_add_timestamp                             VARCHAR2(1);

  g_add_userid                                 forest_client.add_userid%TYPE;
  gb_add_userid                                VARCHAR2(1);

  g_add_org_unit                               forest_client.add_org_unit%TYPE;
  gb_add_org_unit                              VARCHAR2(1);

  g_update_timestamp                           forest_client.update_timestamp%TYPE;
  gb_update_timestamp                          VARCHAR2(1);

  g_update_userid                              forest_client.update_userid%TYPE;
  gb_update_userid                             VARCHAR2(1);

  g_update_org_unit                            forest_client.update_org_unit%TYPE;
  gb_update_org_unit                           VARCHAR2(1);

  g_revision_count                             forest_client.revision_count%TYPE;
  gb_revision_count                            VARCHAR2(1);

  --update reasons
  --> status change reason
  g_ur_action_status                           client_action_reason_xref.client_update_action_code%TYPE;
  g_ur_reason_status                           client_action_reason_xref.client_update_reason_code%TYPE;
  --> name change reason
  g_ur_action_name                             client_action_reason_xref.client_update_action_code%TYPE;
  g_ur_reason_name                             client_action_reason_xref.client_update_reason_code%TYPE;
  --> id change reason
  g_ur_action_id                               client_action_reason_xref.client_update_action_code%TYPE;
  g_ur_reason_id                               client_action_reason_xref.client_update_reason_code%TYPE;

  r_previous                                   forest_client%ROWTYPE;


  --***START GETTERS

  --error raised?
  FUNCTION error_raised RETURN BOOLEAN
  IS
  BEGIN
    RETURN (g_error_message IS NOT NULL);
  END error_raised;

  --get error message
  FUNCTION get_error_message RETURN SIL_ERROR_MESSAGES
  IS
  BEGIN
    RETURN g_error_message;
  END get_error_message;

  --get client_number
  FUNCTION get_client_number RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_number;
  END get_client_number;

  --get client_name
  FUNCTION get_client_name RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_name;
  END get_client_name;

  --get legal_first_name
  FUNCTION get_legal_first_name RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_legal_first_name;
  END get_legal_first_name;

  --get legal_middle_name
  FUNCTION get_legal_middle_name RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_legal_middle_name;
  END get_legal_middle_name;

  --get client_status_code
  FUNCTION get_client_status_code RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_status_code;
  END get_client_status_code;

  --get client_type_code
  FUNCTION get_client_type_code RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_type_code;
  END get_client_type_code;

  --get birthdate
  FUNCTION get_birthdate RETURN DATE
  IS
  BEGIN
    RETURN g_birthdate;
  END get_birthdate;

  --get client_id_type_code
  FUNCTION get_client_id_type_code RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_id_type_code;
  END get_client_id_type_code;

  --get client_identification
  FUNCTION get_client_identification RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_identification;
  END get_client_identification;

  --get registry_company_type_code
  FUNCTION get_registry_company_type_code RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_registry_company_type_code;
  END get_registry_company_type_code;

  --get corp_regn_nmbr
  FUNCTION get_corp_regn_nmbr RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_corp_regn_nmbr;
  END get_corp_regn_nmbr;

  --get client_acronym
  FUNCTION get_client_acronym RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_acronym;
  END get_client_acronym;

  --get wcb_firm_number
  FUNCTION get_wcb_firm_number RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_wcb_firm_number;
  END get_wcb_firm_number;

  --get ocg_supplier_nmbr
  FUNCTION get_ocg_supplier_nmbr RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_ocg_supplier_nmbr;
  END get_ocg_supplier_nmbr;

  --get client_comment
  FUNCTION get_client_comment RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_client_comment;
  END get_client_comment;

  --get add_timestamp
  FUNCTION get_add_timestamp RETURN DATE
  IS
  BEGIN
    RETURN g_add_timestamp;
  END get_add_timestamp;

  --get add_userid
  FUNCTION get_add_userid RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_add_userid;
  END get_add_userid;

  --get add_org_unit
  FUNCTION get_add_org_unit RETURN NUMBER
  IS
  BEGIN
    RETURN g_add_org_unit;
  END get_add_org_unit;

  --get update_timestamp
  FUNCTION get_update_timestamp RETURN DATE
  IS
  BEGIN
    RETURN g_update_timestamp;
  END get_update_timestamp;

  --get update_userid
  FUNCTION get_update_userid RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_update_userid;
  END get_update_userid;

  --get update_org_unit
  FUNCTION get_update_org_unit RETURN NUMBER
  IS
  BEGIN
    RETURN g_update_org_unit;
  END get_update_org_unit;

  --get revision_count
  FUNCTION get_revision_count RETURN NUMBER
  IS
  BEGIN
    RETURN g_revision_count;
  END get_revision_count;

  --get update reason code for status change
  FUNCTION get_ur_reason_status RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_ur_reason_status;
  END get_ur_reason_status;
  --get update reason code for name change
  FUNCTION get_ur_reason_name RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_ur_reason_name;
  END get_ur_reason_name;
  --get update reason code for id change
  FUNCTION get_ur_reason_id RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_ur_reason_id;
  END get_ur_reason_id;

  --***END GETTERS

  --***START SETTERS

  --set client_number
  PROCEDURE set_client_number(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_number := p_value;
    gb_client_number := 'Y';
  END set_client_number;

  --set client_name
  PROCEDURE set_client_name(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_name := p_value;
    gb_client_name := 'Y';
  END set_client_name;

  --set legal_first_name
  PROCEDURE set_legal_first_name(p_value IN VARCHAR2)
  IS
  BEGIN
    g_legal_first_name := p_value;
    gb_legal_first_name := 'Y';
  END set_legal_first_name;

  --set legal_middle_name
  PROCEDURE set_legal_middle_name(p_value IN VARCHAR2)
  IS
  BEGIN
    g_legal_middle_name := p_value;
    gb_legal_middle_name := 'Y';
  END set_legal_middle_name;

  --set client_status_code
  PROCEDURE set_client_status_code(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_status_code := p_value;
    gb_client_status_code := 'Y';
  END set_client_status_code;

  --set client_type_code
  PROCEDURE set_client_type_code(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_type_code := p_value;
    gb_client_type_code := 'Y';
  END set_client_type_code;

  --set birthdate
  PROCEDURE set_birthdate(p_value IN DATE)
  IS
  BEGIN
    g_birthdate := p_value;
    gb_birthdate := 'Y';
  END set_birthdate;

  --set client_id_type_code
  PROCEDURE set_client_id_type_code(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_id_type_code := p_value;
    gb_client_id_type_code := 'Y';
  END set_client_id_type_code;

  --set client_identification
  PROCEDURE set_client_identification(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_identification := p_value;
    gb_client_identification := 'Y';
  END set_client_identification;

  --set registry_company_type_code
  PROCEDURE set_registry_company_type_code(p_value IN VARCHAR2)
  IS
  BEGIN
    g_registry_company_type_code := p_value;
    gb_registry_company_type_code := 'Y';
  END set_registry_company_type_code;

  --set corp_regn_nmbr
  PROCEDURE set_corp_regn_nmbr(p_value IN VARCHAR2)
  IS
  BEGIN
    g_corp_regn_nmbr := p_value;
    gb_corp_regn_nmbr := 'Y';
  END set_corp_regn_nmbr;

  --set client_acronym
  PROCEDURE set_client_acronym(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_acronym := p_value;
    gb_client_acronym := 'Y';
  END set_client_acronym;

  --set wcb_firm_number
  PROCEDURE set_wcb_firm_number(p_value IN VARCHAR2)
  IS
  BEGIN
    g_wcb_firm_number := p_value;
    gb_wcb_firm_number := 'Y';
  END set_wcb_firm_number;

  --set ocg_supplier_nmbr
  PROCEDURE set_ocg_supplier_nmbr(p_value IN VARCHAR2)
  IS
  BEGIN
    g_ocg_supplier_nmbr := p_value;
    gb_ocg_supplier_nmbr := 'Y';
  END set_ocg_supplier_nmbr;

  --set client_comment
  PROCEDURE set_client_comment(p_value IN VARCHAR2)
  IS
  BEGIN
    g_client_comment := p_value;
    gb_client_comment := 'Y';
  END set_client_comment;

  --set add_timestamp
  PROCEDURE set_add_timestamp(p_value IN DATE)
  IS
  BEGIN
    g_add_timestamp := p_value;
    gb_add_timestamp := 'Y';
  END set_add_timestamp;

  --set add_userid
  PROCEDURE set_add_userid(p_value IN VARCHAR2)
  IS
  BEGIN
    g_add_userid := p_value;
    gb_add_userid := 'Y';
  END set_add_userid;

  --set add_org_unit
  PROCEDURE set_add_org_unit(p_value IN NUMBER)
  IS
  BEGIN
    g_add_org_unit := p_value;
    gb_add_org_unit := 'Y';
  END set_add_org_unit;

  --set update_timestamp
  PROCEDURE set_update_timestamp(p_value IN DATE)
  IS
  BEGIN
    g_update_timestamp := p_value;
    gb_update_timestamp := 'Y';
  END set_update_timestamp;

  --set update_userid
  PROCEDURE set_update_userid(p_value IN VARCHAR2)
  IS
  BEGIN
    g_update_userid := p_value;
    gb_update_userid := 'Y';
  END set_update_userid;

  --set update_org_unit
  PROCEDURE set_update_org_unit(p_value IN NUMBER)
  IS
  BEGIN
    g_update_org_unit := p_value;
    gb_update_org_unit := 'Y';
  END set_update_org_unit;

  --set revision_count
  PROCEDURE set_revision_count(p_value IN NUMBER)
  IS
  BEGIN
    g_revision_count := p_value;
    gb_revision_count := 'Y';
  END set_revision_count;

  --***END SETTERS

/******************************************************************************
    Procedure:  get_previous

    Purpose:    Load current version of client record for comparisons

******************************************************************************/
  PROCEDURE get_previous
  IS
  BEGIN
    --If record already populated, don't requery
    IF r_previous.client_number IS NULL THEN
      SELECT *
        INTO r_previous
        FROM forest_client
       WHERE client_number = g_client_number;
    END IF;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;

  END get_previous;

/******************************************************************************
    Procedure:  get_client_display_name

    Purpose:    Derive standard client display name.
                If client number is not passed, current package vars will be used.

******************************************************************************/
  FUNCTION get_client_display_name
  (p_client_number              IN VARCHAR2 DEFAULT NULL)
  RETURN std_client_name_type%TYPE
  IS
  BEGIN
    IF p_client_number IS NOT NULL THEN
      RETURN client_get_client_name(p_client_number);
    ELSE
      RETURN sil_std_client_name(g_client_name,g_legal_first_name,g_legal_middle_name);
    END IF;

  END get_client_display_name;

/******************************************************************************
    Procedure:  client_must_be_registered

    Purpose:    Return TRUE if client is of a type that must be registered.

******************************************************************************/
  FUNCTION client_must_be_registered
  (p_client_number              IN VARCHAR2 DEFAULT NULL)
  RETURN BOOLEAN
  IS
    CURSOR c_cli
    IS
      SELECT client_type_code
        FROM forest_client
       WHERE client_number = p_client_number;
    r_cli                          c_cli%ROWTYPE;
  BEGIN

    IF p_client_number IS NOT NULL THEN
      OPEN c_cli;
      FETCH c_cli INTO r_cli;
      CLOSE c_cli;
    ELSE
      r_cli.client_type_code := g_client_type_code;
    END IF;

    RETURN (r_cli.client_type_code IN (C_CLIENT_TYPE_CORPORATION
                                      ,C_CLIENT_TYPE_ASSOCIATION
                                      ,C_CLIENT_TYPE_SOCIETY));

  END client_must_be_registered;

/******************************************************************************
    Procedure:  client_is_individual

    Purpose:    Return TRUE if client is an individual, otherwise FALSE.

******************************************************************************/
  FUNCTION client_is_individual
  (p_client_number              IN VARCHAR2 DEFAULT NULL)
  RETURN BOOLEAN
  IS
    CURSOR c_cli
    IS
      SELECT client_type_code
        FROM forest_client
       WHERE client_number = p_client_number;
    r_cli                          c_cli%ROWTYPE;
  BEGIN

    IF p_client_number IS NOT NULL THEN
      OPEN c_cli;
      FETCH c_cli INTO r_cli;
      CLOSE c_cli;
    ELSE
      r_cli.client_type_code := g_client_type_code;
    END IF;

    RETURN (r_cli.client_type_code = C_CLIENT_TYPE_INDIVIDUAL);

  END client_is_individual;

/******************************************************************************
    Procedure:  get

    Purpose:    SELECT one row from FOREST_CLIENT

******************************************************************************/
  PROCEDURE get
  IS
  BEGIN
    SELECT
           client_number
         , client_name
         , legal_first_name
         , legal_middle_name
         , client_status_code
         , client_type_code
         , birthdate
         , client_id_type_code
         , client_identification
         , registry_company_type_code
         , corp_regn_nmbr
         , client_acronym
         , wcb_firm_number
         , ocg_supplier_nmbr
         , client_comment
         , add_timestamp
         , add_userid
         , add_org_unit
         , update_timestamp
         , update_userid
         , update_org_unit
         , revision_count
      INTO
           g_client_number
         , g_client_name
         , g_legal_first_name
         , g_legal_middle_name
         , g_client_status_code
         , g_client_type_code
         , g_birthdate
         , g_client_id_type_code
         , g_client_identification
         , g_registry_company_type_code
         , g_corp_regn_nmbr
         , g_client_acronym
         , g_wcb_firm_number
         , g_ocg_supplier_nmbr
         , g_client_comment
         , g_add_timestamp
         , g_add_userid
         , g_add_org_unit
         , g_update_timestamp
         , g_update_userid
         , g_update_org_unit
         , g_revision_count
      FROM forest_client
     WHERE client_number = g_client_number;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         NULL;
  END get;


/******************************************************************************
    Procedure:  init

    Purpose:    Initialize member variables

******************************************************************************/
  PROCEDURE init
  (p_client_number          IN VARCHAR2 DEFAULT NULL)
  IS
    r_empty                         forest_client%ROWTYPE;
  BEGIN

    g_error_message := NULL;

    g_client_number := NULL;
    gb_client_number := 'N';

    g_client_name := NULL;
    gb_client_name := 'N';

    g_legal_first_name := NULL;
    gb_legal_first_name := 'N';

    g_legal_middle_name := NULL;
    gb_legal_middle_name := 'N';

    g_client_status_code := NULL;
    gb_client_status_code := 'N';

    g_client_type_code := NULL;
    gb_client_type_code := 'N';

    g_birthdate := NULL;
    gb_birthdate := 'N';

    g_client_id_type_code := NULL;
    gb_client_id_type_code := 'N';

    g_client_identification := NULL;
    gb_client_identification := 'N';

    g_registry_company_type_code := NULL;
    gb_registry_company_type_code := 'N';

    g_corp_regn_nmbr := NULL;
    gb_corp_regn_nmbr := 'N';

    g_client_acronym := NULL;
    gb_client_acronym := 'N';

    g_wcb_firm_number := NULL;
    gb_wcb_firm_number := 'N';

    g_ocg_supplier_nmbr := NULL;
    gb_ocg_supplier_nmbr := 'N';

    g_client_comment := NULL;
    gb_client_comment := 'N';

    g_add_timestamp := NULL;
    gb_add_timestamp := 'N';

    g_add_userid := NULL;
    gb_add_userid := 'N';

    g_add_org_unit := NULL;
    gb_add_org_unit := 'N';

    g_update_timestamp := NULL;
    gb_update_timestamp := 'N';

    g_update_userid := NULL;
    gb_update_userid := 'N';

    g_update_org_unit := NULL;
    gb_update_org_unit := 'N';

    g_ur_action_status := NULL;
    g_ur_reason_status := NULL;
    g_ur_action_name := NULL;
    g_ur_reason_name := NULL;
    g_ur_action_id := NULL;
    g_ur_reason_id := NULL;

    r_previous := r_empty;

    IF p_client_number IS NOT NULL THEN
      set_client_number(p_client_number);
      get;
    END IF;

  END init;


/******************************************************************************
    Procedure:  formatted_client_number

    Purpose:    Returns the passed-in client number, formatted

******************************************************************************/
  FUNCTION formatted_client_number
  (p_client_number IN VARCHAR2)
  RETURN VARCHAR2
  IS
    v_client_number          forest_client.client_number%TYPE;
  BEGIN
    --strip spaces
    v_client_number := TRIM(p_client_number);

    --strip leading 0's
    v_client_number := TRIM(LEADING '0' FROM v_client_number);

    BEGIN
      v_client_number := TO_CHAR(TO_NUMBER(v_client_number,'99999999'),'FM00000000');
    EXCEPTION
      WHEN value_error THEN
        RAISE_APPLICATION_ERROR(-20200,'client_forest_client.formatted_client_number: client number is not numeric or not of correct structure');
    END;

    RETURN v_client_number;

  END formatted_client_number;
  /* OVERLOADED TO ACCEPT NUMERIC INPUT */
  FUNCTION formatted_client_number
  (p_client_number IN NUMBER)
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN formatted_client_number(TO_CHAR(p_client_number));
  END formatted_client_number;

/******************************************************************************
    Procedure:  is_individual

    Purpose:    Returns TRUE if client is an individual.
                If key passed, performs lookup, else acts on current client.

******************************************************************************/
  FUNCTION is_individual
  (p_client_number IN VARCHAR2 DEFAULT NULL)
  RETURN BOOLEAN
  IS
    CURSOR c_client
    IS
      SELECT client_type_code
        FROM forest_client
       WHERE client_number = p_client_number;

    e_client_type               EXCEPTION;
    b_is_individual             BOOLEAN;
    v_client_type_code          forest_client.client_type_code%TYPE;
  BEGIN
    b_is_individual := FALSE;

    --use client number passed-in if present
    IF p_client_number IS NOT NULL THEN
      OPEN c_client;
      FETCH c_client INTO v_client_type_code;
      CLOSE c_client;
    ELSE
      v_client_type_code := g_client_type_code;
    END IF;

    IF v_client_type_code = C_CLIENT_TYPE_INDIVIDUAL THEN
      b_is_individual := TRUE;
    ELSIF v_client_type_code IS NULL THEN
      RAISE e_client_type;
    END IF;

    RETURN b_is_individual;

    EXCEPTION
      WHEN e_client_type THEN
        RAISE_APPLICATION_ERROR(-20200,'forest_client.is_individual: client type could not be derived');
        --Add RETURN to remove PLSQL warnings
        RETURN b_is_individual;

  END is_individual;


/******************************************************************************
    Procedure:  validate_reg_type

    Purpose:    Validate Corp Registry Company Type

******************************************************************************/
  PROCEDURE validate_reg_type
  IS
    CURSOR c_xref
    IS
      SELECT client_type_code
        FROM client_type_company_xref
       WHERE client_type_code = g_client_type_code
         AND registry_company_type_code = g_registry_company_type_code;
    r_xref                         c_xref%ROWTYPE;
  BEGIN

    IF g_client_type_code IS NOT NULL
    AND g_registry_company_type_code IS NOT NULL THEN
      OPEN c_xref;
      FETCH c_xref INTO r_xref;
      CLOSE c_xref;

      IF r_xref.client_type_code IS NULL THEN
        --Registration Type is not valid for the Client Type specified.
        CLIENT_UTILS.add_error(g_error_message
                             , NULL
                             , 'client.web.usr.database.reg.type.xref'
                             , NULL);
      END IF;
    END IF;

  END validate_reg_type;

/******************************************************************************
    Procedure:  validate_reg_id

    Purpose:    Validate Corp Registry Number

******************************************************************************/
  PROCEDURE validate_reg_id
  IS
    CURSOR c_dup
    IS
      SELECT client_number
        FROM forest_client
       WHERE corp_regn_nmbr = g_corp_regn_nmbr
       AND registry_company_type_code = g_registry_company_type_code;
    r_dup               c_dup%ROWTYPE;
  BEGIN

    IF g_corp_regn_nmbr IS NOT NULL THEN

      --dup check
      OPEN c_dup;
      FETCH c_dup INTO r_dup;
      CLOSE c_dup;
      IF r_dup.client_number != NVL(g_client_number,'~') THEN
        --reg id already exists
        CLIENT_UTILS.add_error(g_error_message
                             , 'corp_regn_nmbr'
                             , 'client.web.usr.database.dup.for.client'
                             , SIL_ERROR_PARAMS('Registration Type/Id', r_dup.client_number));
      END IF;
    END IF;

  END validate_reg_id;


/******************************************************************************
    Procedure:  validate_birthdate

    Purpose:    Validate birthdate

******************************************************************************/
  PROCEDURE validate_birthdate
  IS

  BEGIN

    IF g_birthdate IS NOT NULL THEN
      --cannot be in the future
      IF TRUNC(g_birthdate) > TRUNC(SYSDATE) THEN
        CLIENT_UTILS.add_error(g_error_message
                             , 'birthdate'
                             , 'client.web.usr.database.date.future'
                             , SIL_ERROR_PARAMS('Birth Date'));

      END IF;
    END IF;

    IF NOT client_is_individual THEN
      --birthdate not applicable
      IF g_birthdate IS NOT NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                             , 'birthdate'
                             , 'client.web.usr.database.not.applicable'
                             , SIL_ERROR_PARAMS('Birth Date', 'Organizations'));
      END IF;
    END IF;

  END validate_birthdate;


/******************************************************************************
    Procedure:  validate_name

    Purpose:    Validate name components (does not include optionality)

******************************************************************************/
  PROCEDURE validate_name
  IS

  BEGIN

    IF NOT client_is_individual THEN
      --first name not applicable
      IF g_legal_first_name IS NOT NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                             , 'legal_first_name'
                             , 'client.web.usr.database.not.applicable'
                             , SIL_ERROR_PARAMS('First Name', 'Organizations'));
      END IF;
      --middle name not applicable
      IF g_legal_middle_name IS NOT NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                             , 'legal_middle_name'
                             , 'client.web.usr.database.not.applicable'
                             , SIL_ERROR_PARAMS('Middle Name', 'Organizations'));
      END IF;
    END IF;

  END validate_name;


/******************************************************************************
    Procedure:  validate_reg_info

    Purpose:    Validate company type and registration number

******************************************************************************/
  PROCEDURE validate_reg_info
  IS
  BEGIN
    validate_reg_id;

    validate_reg_type;

    --cross-validations
    IF client_is_individual THEN
      --reg info not allowed for individual
      IF g_registry_company_type_code IS NOT NULL THEN
        --reg type not applicable to individuals
        CLIENT_UTILS.add_error(g_error_message
                             , 'registry_company_type_code'
                             , 'client.web.usr.database.not.applicable'
                             , SIL_ERROR_PARAMS('Registration Type', 'Individuals'));
      END IF;
      IF g_corp_regn_nmbr IS NOT NULL THEN
        --reg id not applicable to individuals
        CLIENT_UTILS.add_error(g_error_message
                             , 'corp_regn_nmbr'
                             , 'client.web.usr.database.not.applicable'
                             , SIL_ERROR_PARAMS('Registration Id', 'Individuals'));
      END IF;
    ELSIF NOT client_is_individual THEN
      --if type specified, id must be specified
      IF g_registry_company_type_code IS NOT NULL
      AND g_corp_regn_nmbr IS NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                             , 'corp_regn_nmbr'
                             , 'sil.error.usr.date.compare.required'
                             , SIL_ERROR_PARAMS('Id', 'Registration Type'));
      END IF;
    END IF;

  END validate_reg_info;


/******************************************************************************
    Procedure:  validate_client_id

    Purpose:    Validate Client Identification Number

******************************************************************************/
  PROCEDURE validate_client_id
  IS
  BEGIN

    IF g_client_identification IS NOT NULL THEN
      IF g_client_identification =  C_CLIENT_ID_TYPE_BC_DRIVERS
      AND (LENGTH(g_client_identification) != 9
           OR TRIM(TRANSLATE(g_client_identification,'1234567890','          X')) IS NOT NULL) THEN
        --BCDL must be 9 numeric characters
        CLIENT_UTILS.add_error(g_error_message
                             , 'client_identification'
                             , 'client.web.usr.database.client.id.typelen'
                             , NULL);
      END IF;
    END IF;

  END validate_client_id;


/******************************************************************************
    Procedure:  validate_identification

    Purpose:    Validate client id and type

******************************************************************************/
  PROCEDURE validate_identification
  IS
    CURSOR c_dup
    IS
      SELECT client_number
        FROM forest_client
       WHERE client_id_type_code = g_client_id_type_code
         AND client_identification = g_client_identification;
    r_dup               c_dup%ROWTYPE;
    v_field             VARCHAR2(30);
  BEGIN

    validate_client_id;

    --dup check
    OPEN c_dup;
    FETCH c_dup INTO r_dup;
    CLOSE c_dup;
    IF r_dup.client_number != NVL(g_client_number,'~') THEN
      --client type/id already exists
        CLIENT_UTILS.add_error(g_error_message
                             , 'client_identification'
                             , 'client.web.usr.database.dup.for.client'
                             , SIL_ERROR_PARAMS('Client Identification Type/Id', r_dup.client_number));
    END IF;

    --cross-validations
    IF NOT client_is_individual THEN
      --client id type not allowed for organizations
      IF g_client_id_type_code IS NOT NULL THEN
        --client id type not applicable to organizations
        CLIENT_UTILS.add_error(g_error_message
                             , 'client_id_type_code'
                             , 'client.web.usr.database.not.applicable'
                             , SIL_ERROR_PARAMS('Client Id Type', 'Organizations'));
      END IF;
      IF g_client_identification IS NOT NULL THEN
        --client id not applicable to organizations
        CLIENT_UTILS.add_error(g_error_message
                             , 'client_identification'
                             , 'client.web.usr.database.not.applicable'
                             , SIL_ERROR_PARAMS('Client Id', 'Organizations'));
      END IF;
    ELSIF client_is_individual THEN
      --if type or id specified, both must be specified
      IF COALESCE(g_client_id_type_code,g_client_identification) IS NOT NULL
      AND (g_client_id_type_code IS NULL
          OR g_client_identification IS NULL) THEN
        IF g_client_id_type_code IS NULL THEN
          v_field := 'client_id_type_code';
        ELSE
          v_field := 'client_identification';
        END IF;

        CLIENT_UTILS.add_error(g_error_message
                              , v_field
                              , 'sil.error.usr.field.and'
                              , SIL_ERROR_PARAMS('Client Type', 'Id'));
      END IF;
    END IF;

  END validate_identification;

/******************************************************************************
    Procedure:  validate_status

    Purpose:    Status validations

******************************************************************************/
  PROCEDURE validate_status
  IS
    l_flag VARCHAR2(1);
  BEGIN

    --At this time all status validations are handled in the front-end as
    --they revolve around which roles can update certain statuses.
    --Add assignment to remove PLSQL warning for unreachable code
    l_flag := 'Y';

  END validate_status;

/******************************************************************************
    Procedure:  validate_acronym

    Purpose:    Acronym validations

******************************************************************************/
  PROCEDURE validate_acronym
  IS
    CURSOR c_acronym
    IS
      SELECT client_number
        FROM forest_client
       WHERE client_acronym = g_client_acronym;
    r_acronym                 c_acronym%ROWTYPE;

  BEGIN

    IF g_client_acronym IS NOT NULL THEN
      --acronym must be unique
      OPEN c_acronym;
      FETCH c_acronym INTO r_acronym;
      CLOSE c_acronym;
      IF r_acronym.client_number != NVL(g_client_number,'~') THEN
          CLIENT_UTILS.add_error(g_error_message
                         , 'client_acronym'
                         , 'client.web.usr.database.dup.for.client'
                         , SIL_ERROR_PARAMS('Acronym', r_acronym.client_number));
      END IF;
    END IF;

  END validate_acronym;

/******************************************************************************
    Procedure:  validate_mandatories

    Purpose:    Validate optionality

******************************************************************************/
  PROCEDURE validate_mandatories
  IS
  BEGIN
    /*
      g_client_number is generated on INSERT so do not check
    */

    IF g_client_type_code IS NULL THEN
      CLIENT_UTILS.add_error(g_error_message
                     , 'client_type_code'
                     , 'sil.error.usr.isrequired'
                     , SIL_ERROR_PARAMS('Client Type'));

    --Type=Individual
    ELSIF client_is_individual THEN
      IF g_client_name IS NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                     , 'client_name'
                     , 'sil.error.usr.isrequired'
                     , SIL_ERROR_PARAMS('Surname'));
      END IF;
      IF g_legal_first_name IS NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                     , 'legal_first_name'
                     , 'sil.error.usr.isrequired'
                     , SIL_ERROR_PARAMS('First Name'));
      END IF;

    --Type=other than Individual
    ELSE
      IF g_client_name IS NULL THEN
          CLIENT_UTILS.add_error(g_error_message
                     , 'client_name'
                     , 'sil.error.usr.isrequired'
                     , SIL_ERROR_PARAMS('Oganization Name'));
      END IF;
    END IF;
/* Rule: Corp Registration info always optional for CLIENT_CHANGE_NAME role
         - cannont validate role info in db
    IF client_must_be_registered THEN
      IF g_corp_regn_nmbr IS NULL THEN
          CLIENT_UTILS.add_error(g_error_message
                     , 'corp_regn_nmbr'
                     , 'sil.error.usr.isrequired'
                     , SIL_ERROR_PARAMS('Registration ID'));
      END IF;
      IF g_registry_company_type_code IS NULL THEN
          CLIENT_UTILS.add_error(g_error_message
                     , 'registry_company_type_code'
                     , 'sil.error.usr.isrequired'
                     , SIL_ERROR_PARAMS('Registration Type'));
      END IF;
    END IF;
*/
    IF g_client_status_code IS NULL THEN
        CLIENT_UTILS.add_error(g_error_message
                     , 'client_status_code'
                     , 'sil.error.usr.isrequired'
                     , SIL_ERROR_PARAMS('Client Status'));
    END IF;

  END validate_mandatories;

/******************************************************************************
    Procedure:  process_update_reasons

    Purpose:    Certain changes require a reason to be specified

******************************************************************************/
  PROCEDURE process_update_reasons
  (p_ur_action_status       IN OUT VARCHAR2
  ,p_ur_reason_status       IN OUT VARCHAR2
  ,p_ur_action_name         IN OUT VARCHAR2
  ,p_ur_reason_name         IN OUT VARCHAR2
  ,p_ur_action_id           IN OUT VARCHAR2
  ,p_ur_reason_id           IN OUT VARCHAR2)
  IS
    v_client_update_action_code  client_update_reason.client_update_action_code%TYPE;
    e_reason_not_required        EXCEPTION;
  BEGIN
    --Only for updates
    IF g_client_number IS NOT NULL
    AND g_revision_count IS NOT NULL THEN

      get_previous;

      --set globals
      g_ur_action_status := p_ur_action_status;
      g_ur_reason_status := p_ur_reason_status;
      g_ur_action_name := p_ur_action_name;
      g_ur_reason_name := p_ur_reason_name;
      g_ur_action_id := p_ur_action_id;
      g_ur_reason_id := p_ur_reason_id;

      --Status changes
      v_client_update_action_code := NULL;
      IF gb_client_status_code = 'Y' THEN
        v_client_update_action_code := client_client_update_reason.check_status
                                       (--old
                                        r_previous.client_status_code
                                        --new
                                       ,g_client_status_code);
        IF v_client_update_action_code IS NOT NULL THEN
          g_ur_action_status := v_client_update_action_code;
          IF g_ur_reason_status IS NULL THEN
            --"Please provide an update reason for the following change: {0}"
            client_utils.add_error(g_error_message
                            , 'client_status_code'
                            , 'client.web.error.update.reason'
                            , sil_error_params(client_code_lists.get_client_update_action_desc(v_client_update_action_code)));
          END IF;
        ELSIF g_ur_reason_status IS NOT NULL THEN
          RAISE e_reason_not_required;
        END IF;
      END IF;

      --Name changes
      --Change to Select statement to remove PLSQL warning for unreachable code
      SELECT NULL INTO v_client_update_action_code FROM DUAL;

      IF gb_client_name = 'Y'
      OR gb_legal_first_name = 'Y'
      OR gb_legal_middle_name = 'Y' THEN
        v_client_update_action_code := client_client_update_reason.check_client_name
                                       (--old
                                        r_previous.client_name
                                       ,r_previous.legal_first_name
                                       ,r_previous.legal_middle_name
                                        --new
                                       ,g_client_name
                                       ,g_legal_first_name
                                       ,g_legal_middle_name);
        IF v_client_update_action_code IS NOT NULL THEN
          g_ur_action_name := v_client_update_action_code;
          IF g_ur_reason_name IS NULL THEN
            --"Please provide an update reason for the following change: {0}"
            client_utils.add_error(g_error_message
                            , 'client_name'
                            , 'client.web.error.update.reason'
                            , sil_error_params(client_code_lists.get_client_update_action_desc(v_client_update_action_code)));
          END IF;
        ELSIF g_ur_reason_name IS NOT NULL THEN
          RAISE e_reason_not_required;
        END IF;
      END IF;

      --ID changes
      --Change to Select statement to remove PLSQL warning for unreachable code
      SELECT NULL INTO v_client_update_action_code FROM DUAL;

      IF gb_client_identification = 'Y'
      OR gb_client_id_type_code = 'Y' THEN
        v_client_update_action_code := client_client_update_reason.check_id
                                       (--old
                                        r_previous.client_identification
                                       ,r_previous.client_id_type_code
                                        --new
                                       ,g_client_identification
                                       ,g_client_id_type_code);
        IF v_client_update_action_code IS NOT NULL THEN
          g_ur_action_id := v_client_update_action_code;
          IF g_ur_reason_id IS NULL THEN
            --"Please provide an update reason for the following change: {0}"
            client_utils.add_error(g_error_message
                            , 'client_identification'
                            , 'client.web.error.update.reason'
                            , sil_error_params(client_code_lists.get_client_update_action_desc(v_client_update_action_code)));
          END IF;
        ELSIF g_ur_reason_id IS NOT NULL THEN
          RAISE e_reason_not_required;
        END IF;
      END IF;

      --return globals
      p_ur_action_status := g_ur_action_status;
      p_ur_reason_status := g_ur_reason_status;
      p_ur_action_name := g_ur_action_name;
      p_ur_reason_name := g_ur_reason_name;
      p_ur_action_id := g_ur_action_id;
      p_ur_reason_id := g_ur_reason_id;
    END IF; --if updating

  EXCEPTION
    WHEN e_reason_not_required THEN
      RAISE_APPLICATION_ERROR(-20200,'Reason provided but no corresponding change noted.');

  END process_update_reasons;

/******************************************************************************
    Procedure:  validate

    Purpose:    Column validators.
                Update reasons interface is mandatory.

******************************************************************************/
  PROCEDURE validate
  IS
  BEGIN
    get_previous;

    validate_mandatories;

    validate_status;

    validate_name;

    validate_acronym;

    validate_birthdate;

    --reg id/type
    validate_reg_info;

    --client id/type
    validate_identification;

  END validate;


/******************************************************************************
    Procedure:  validate_remove

    Purpose:    DELETE validations - check for child records, etc.

******************************************************************************/
  PROCEDURE validate_remove
  IS
  BEGIN
    --Cannot delete clients - set status to DAC instead
    CLIENT_UTILS.add_error(g_error_message
                 , NULL
                 , 'client.web.usr.database.client.del'
                 , NULL);
  END validate_remove;

/******************************************************************************
    Procedure:  reserve_client_number

    Purpose:    Get the next client number and return it formatted

******************************************************************************/
  FUNCTION reserve_client_number
  RETURN VARCHAR2
  IS
    v_client_number     forest_client.client_number%TYPE;
  BEGIN

    --update table to get next number and return it
    UPDATE max_client_nmbr
       SET client_number = formatted_client_number(TO_NUMBER(client_number) + 1)
     RETURNING client_number
          INTO v_client_number;

    RETURN v_client_number;

  END reserve_client_number;

/******************************************************************************
    Procedure:  add

    Purpose:    INSERT one row into FOREST_CLIENT

******************************************************************************/
  PROCEDURE add
  IS
  BEGIN
    IF g_client_number IS NULL THEN
      set_client_number(reserve_client_number);
    END IF;

    INSERT INTO forest_client
       ( client_number
       , client_name
       , legal_first_name
       , legal_middle_name
       , client_status_code
       , client_type_code
       , birthdate
       , client_id_type_code
       , client_identification
       , registry_company_type_code
       , corp_regn_nmbr
       , client_acronym
       , wcb_firm_number
       , ocg_supplier_nmbr
       , client_comment
       , add_timestamp
       , add_userid
       , add_org_unit
       , update_timestamp
       , update_userid
       , update_org_unit
       , revision_count
       )
     VALUES
       ( g_client_number
       , g_client_name
       , g_legal_first_name
       , g_legal_middle_name
       , g_client_status_code
       , g_client_type_code
       , g_birthdate
       , g_client_id_type_code
       , g_client_identification
       , g_registry_company_type_code
       , g_corp_regn_nmbr
       , g_client_acronym
       , g_wcb_firm_number
       , g_ocg_supplier_nmbr
       , g_client_comment
       , g_add_timestamp
       , g_add_userid
       , g_add_org_unit
       , g_update_timestamp
       , g_update_userid
       , g_update_org_unit
       , g_revision_count
       );
  END add;

/******************************************************************************
    Procedure:  before_change_processing

    Purpose:    Any pre-update processing

******************************************************************************/
  PROCEDURE before_change_processing
  IS
  BEGIN
    get_previous;

    --If status changed to Deactivated, Expire all locations
    IF r_previous.client_status_code != 'DAC'
    AND g_client_status_code = 'DAC' THEN
      --expire locns
      client_client_location.expire_nonexpired_locns
      ( g_client_number
      , g_update_userid
      , g_update_timestamp
      , g_update_org_unit );

    END IF;

  END before_change_processing;

/******************************************************************************
    Procedure:  after_change_processing

    Purpose:    Any post-update processing

******************************************************************************/
  PROCEDURE after_change_processing
  (p_deactivated_date       IN OUT DATE)
  IS
  BEGIN
    get_previous;

    --If status changed from Deactivated to anything else, unexpired those
    --locations that were expired when the status was set to DAC
    --(the assumption here is that the client cannot be updated when status is DAC
    -- so timestamps on the client record and the expired locns should line-up.)
    IF r_previous.client_status_code = 'DAC'
    AND g_client_status_code != 'DAC' THEN
      --unexpire locns
      client_client_location.unexpire_locns
      ( g_client_number
      , r_previous.update_timestamp -- date DAC took place
      , g_update_userid
      , g_update_timestamp
      , g_update_org_unit
      , p_deactivated_date );

    END IF;

  END after_change_processing;

/******************************************************************************
    Procedure:  change

    Purpose:    UPDATE one row in FOREST_CLIENT

******************************************************************************/
  PROCEDURE change
  IS
       v_ts             date;
  BEGIN

       /* Get the most recent date in which this client was deactivated.
        * This will be passed to after_change_processing in case we're re-activating
        * the client.  This is used to determine which locations were expired at the
        * time of deactivation
        */
       SELECT MIN(update_timestamp) INTO v_ts
       FROM  for_cli_audit
       WHERE client_number = g_client_number
       AND   client_status_code = 'DAC'
       AND   update_timestamp >
          (SELECT MAX(fca.update_timestamp)
             FROM for_cli_audit fca
            WHERE fca.client_number = g_client_number
              AND fca.client_status_code != 'DAC');

    before_change_processing;

    UPDATE forest_client
       SET client_name = DECODE(gb_client_name,'Y',g_client_name,client_name)
         , legal_first_name = DECODE(gb_legal_first_name,'Y',g_legal_first_name,legal_first_name)
         , legal_middle_name = DECODE(gb_legal_middle_name,'Y',g_legal_middle_name,legal_middle_name)
         , client_status_code = DECODE(gb_client_status_code,'Y',g_client_status_code,client_status_code)
         , client_type_code = DECODE(gb_client_type_code,'Y',g_client_type_code,client_type_code)
         , birthdate = DECODE(gb_birthdate,'Y',g_birthdate,birthdate)
         , client_id_type_code = DECODE(gb_client_id_type_code,'Y',g_client_id_type_code,client_id_type_code)
         , client_identification = DECODE(gb_client_identification,'Y',g_client_identification,client_identification)
         , registry_company_type_code = DECODE(gb_registry_company_type_code,'Y',g_registry_company_type_code,registry_company_type_code)
         , corp_regn_nmbr = DECODE(gb_corp_regn_nmbr,'Y',g_corp_regn_nmbr,corp_regn_nmbr)
         , client_acronym = DECODE(gb_client_acronym,'Y',g_client_acronym,client_acronym)
         , wcb_firm_number = DECODE(gb_wcb_firm_number,'Y',g_wcb_firm_number,wcb_firm_number)
         , ocg_supplier_nmbr = DECODE(gb_ocg_supplier_nmbr,'Y',g_ocg_supplier_nmbr,ocg_supplier_nmbr)
         , client_comment = DECODE(gb_client_comment,'Y',g_client_comment,client_comment)
         , update_timestamp = g_update_timestamp
         , update_userid = g_update_userid
         , update_org_unit = DECODE(gb_update_org_unit,'Y',g_update_org_unit,update_org_unit)
         , revision_count = revision_count + 1
     WHERE client_number = g_client_number
       AND revision_count = g_revision_count
     RETURNING revision_count
          INTO g_revision_count;

    after_change_processing(v_ts);

  END change;


/******************************************************************************
    Procedure:  remove

    Purpose:    DELETE one row from FOREST_CLIENT

******************************************************************************/
  PROCEDURE remove
  IS
  BEGIN
    --Cannot delete clients - set status to DAC instead
    RAISE_APPLICATION_ERROR(-20200,'client_forest_client.remove: Clients may not be deleted');
  END remove;

END client_forest_client;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "THE"."CLIENT_CONSTANTS" AS

/******************************************************************************
    Package:	client_constants

    Purpose:	Package contains constants and types used by the Client
              Application

    Revision History

    Person             Date        Comments
    -----------------  ----------  ------------------------------------------
    R.A.Robb           2006-08-08  Original
******************************************************************************/

  TYPE REF_CUR_T IS REF CURSOR;

  --Audit codes
  C_AUDIT_INSERT                       CONSTANT VARCHAR2(3) := 'INS';
  C_AUDIT_UPDATE                       CONSTANT VARCHAR2(3) := 'UPD';
  C_AUDIT_DELETE                       CONSTANT VARCHAR2(3) := 'DEL';


END client_constants;
/

