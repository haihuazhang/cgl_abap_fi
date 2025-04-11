CLASS LHC_RAP_TDAT_CTS DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      GET
        RETURNING
          VALUE(RESULT) TYPE REF TO IF_MBC_CP_RAP_TDAT_CTS.

ENDCLASS.

CLASS LHC_RAP_TDAT_CTS IMPLEMENTATION.
  METHOD GET.
    result = mbc_cp_api=>rap_tdat_cts( tdat_name = 'ZMAINTAINTAXCODE'
                                       table_entity_relations = VALUE #(
                                         ( entity = 'MaintainTaxCode' table = 'ZTFI011' )
                                       ) ) ##NO_TEXT.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_MAINTAINTAXCODE_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
        IMPORTING
          KEYS REQUEST requested_features FOR MaintainTaxCodeAll
        RESULT result,
      SELECTCUSTOMIZINGTRANSPTREQ FOR MODIFY
        IMPORTING
          KEYS FOR ACTION MaintainTaxCodeAll~SelectCustomizingTransptReq
        RESULT result,
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR MaintainTaxCodeAll
        RESULT result,
      EDIT FOR MODIFY
        IMPORTING
          KEYS FOR ACTION MaintainTaxCodeAll~edit.
ENDCLASS.

CLASS LHC_ZI_MAINTAINTAXCODE_S IMPLEMENTATION.
  METHOD GET_INSTANCE_FEATURES.
    DATA: edit_flag            TYPE abp_behv_op_ctrl    VALUE if_abap_behv=>fc-o-enabled
         ,transport_feature    TYPE abp_behv_field_ctrl VALUE if_abap_behv=>fc-f-mandatory
         ,selecttransport_flag TYPE abp_behv_op_ctrl    VALUE if_abap_behv=>fc-o-enabled.

    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    IF lhc_rap_tdat_cts=>get( )->is_transport_allowed( ) = abap_false.
      selecttransport_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    IF lhc_rap_tdat_cts=>get( )->is_transport_mandatory( ) = abap_false.
      transport_feature = if_abap_behv=>fc-f-unrestricted.
    ENDIF.
    result = VALUE #( FOR key in keys (
               %TKY = key-%TKY
               %ACTION-edit = edit_flag
               %ASSOC-_MaintainTaxCode = edit_flag
               %FIELD-TransportRequestID = transport_feature
               %ACTION-SelectCustomizingTransptReq = COND #( WHEN key-%IS_DRAFT = if_abap_behv=>mk-off
                                                             THEN if_abap_behv=>fc-o-disabled
                                                             ELSE selecttransport_flag ) ) ).
  ENDMETHOD.
  METHOD SELECTCUSTOMIZINGTRANSPTREQ.
    MODIFY ENTITIES OF ZI_MaintainTaxCode_S IN LOCAL MODE
      ENTITY MaintainTaxCodeAll
        UPDATE FIELDS ( TransportRequestID )
        WITH VALUE #( FOR key IN keys
                        ( %TKY               = key-%TKY
                          TransportRequestID = key-%PARAM-transportrequestid
                         ) ).

    READ ENTITIES OF ZI_MaintainTaxCode_S IN LOCAL MODE
      ENTITY MaintainTaxCodeAll
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(entities).
    result = VALUE #( FOR entity IN entities
                        ( %TKY   = entity-%TKY
                          %PARAM = entity ) ).
  ENDMETHOD.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZI_MAINTAINTAXCODE' ID 'ACTVT' FIELD '02'.
    DATA(is_authorized) = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized ).
    result-%UPDATE      = is_authorized.
    result-%ACTION-Edit = is_authorized.
    result-%ACTION-SelectCustomizingTransptReq = is_authorized.
  ENDMETHOD.
  METHOD EDIT.
    CHECK lhc_rap_tdat_cts=>get( )->is_transport_mandatory( ).
    DATA(transport_request) = lhc_rap_tdat_cts=>get( )->get_transport_request( ).
    IF transport_request IS NOT INITIAL.
      MODIFY ENTITY IN LOCAL MODE ZI_MaintainTaxCode_S
        EXECUTE SelectCustomizingTransptReq FROM VALUE #( ( %IS_DRAFT = if_abap_behv=>mk-on
                                                            SingletonID = 1
                                                            %PARAM-transportrequestid = transport_request ) ).
      reported-MaintainTaxCodeAll = VALUE #( ( %IS_DRAFT = if_abap_behv=>mk-on
                                     SingletonID = 1
                                     %MSG = mbc_cp_api=>message( )->get_transport_selected( transport_request ) ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
CLASS LSC_ZI_MAINTAINTAXCODE_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_SAVER.
  PROTECTED SECTION.
    METHODS:
      SAVE_MODIFIED REDEFINITION.
ENDCLASS.

CLASS LSC_ZI_MAINTAINTAXCODE_S IMPLEMENTATION.
  METHOD SAVE_MODIFIED.
    DATA(transport_from_singleton) = VALUE #( update-MaintainTaxCodeAll[ 1 ]-TransportRequestID OPTIONAL ).
    IF transport_from_singleton IS NOT INITIAL.
      lhc_rap_tdat_cts=>get( )->record_changes(
                                  transport_request = transport_from_singleton
                                  create            = REF #( create )
                                  update            = REF #( update )
                                  delete            = REF #( delete ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_MAINTAINTAXCODE DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_FEATURES FOR GLOBAL FEATURES
        IMPORTING
          REQUEST REQUESTED_FEATURES FOR MaintainTaxCode
        RESULT result,
      COPYMAINTAINTAXCODE FOR MODIFY
        IMPORTING
          KEYS FOR ACTION MaintainTaxCode~CopyMaintainTaxCode,
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR MaintainTaxCode
        RESULT result,
      GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
        IMPORTING
          KEYS REQUEST requested_features FOR MaintainTaxCode
        RESULT result,
      VALIDATETRANSPORTREQUEST FOR VALIDATE ON SAVE
        IMPORTING
          KEYS_MAINTAINTAXCODEALL FOR MaintainTaxCodeAll~ValidateTransportRequest
          KEYS_MAINTAINTAXCODE FOR MaintainTaxCode~ValidateTransportRequest.
ENDCLASS.

CLASS LHC_ZI_MAINTAINTAXCODE IMPLEMENTATION.
  METHOD GET_GLOBAL_FEATURES.
    DATA edit_flag TYPE abp_behv_op_ctrl VALUE if_abap_behv=>fc-o-enabled.
    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    result-%UPDATE = edit_flag.
    result-%DELETE = edit_flag.
  ENDMETHOD.
  METHOD COPYMAINTAINTAXCODE.
    DATA new_MaintainTaxCode TYPE TABLE FOR CREATE ZI_MaintainTaxCode_S\_MaintainTaxCode.

    IF lines( keys ) > 1.
      INSERT mbc_cp_api=>message( )->get_select_only_one_entry( ) INTO TABLE reported-%other.
      failed-MaintainTaxCode = VALUE #( FOR fkey IN keys ( %TKY = fkey-%TKY ) ).
      RETURN.
    ENDIF.

    READ ENTITIES OF ZI_MaintainTaxCode_S IN LOCAL MODE
      ENTITY MaintainTaxCode
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(ref_MaintainTaxCode)
        FAILED DATA(read_failed).

    IF ref_MaintainTaxCode IS NOT INITIAL.
      ASSIGN ref_MaintainTaxCode[ 1 ] TO FIELD-SYMBOL(<ref_MaintainTaxCode>).
      DATA(key) = keys[ KEY draft %TKY = <ref_MaintainTaxCode>-%TKY ].
      DATA(key_cid) = key-%CID.
      APPEND VALUE #(
        %TKY-SingletonID = 1
        %IS_DRAFT = <ref_MaintainTaxCode>-%IS_DRAFT
        %TARGET = VALUE #( (
          %CID = key_cid
          %IS_DRAFT = <ref_MaintainTaxCode>-%IS_DRAFT
          %DATA = CORRESPONDING #( <ref_MaintainTaxCode> EXCEPT
          SingletonID
          Createdby
          Createdat
          Lastchangedby
          Lastchangedat
          Locallastchangedat
        ) ) )
      ) TO new_MaintainTaxCode ASSIGNING FIELD-SYMBOL(<new_MaintainTaxCode>).
      <new_MaintainTaxCode>-%TARGET[ 1 ]-Taxcode = to_upper( key-%PARAM-Taxcode ).
      <new_MaintainTaxCode>-%TARGET[ 1 ]-Taxcounrty = to_upper( key-%PARAM-Taxcounrty ).

      MODIFY ENTITIES OF ZI_MaintainTaxCode_S IN LOCAL MODE
        ENTITY MaintainTaxCodeAll CREATE BY \_MaintainTaxCode
        FIELDS (
                 Taxcode
                 Taxcounrty
                 Taxrate
               ) WITH new_MaintainTaxCode
        MAPPED DATA(mapped_create)
        FAILED failed
        REPORTED reported.

      mapped-MaintainTaxCode = mapped_create-MaintainTaxCode.
    ENDIF.

    INSERT LINES OF read_failed-MaintainTaxCode INTO TABLE failed-MaintainTaxCode.

    IF failed-MaintainTaxCode IS INITIAL.
      reported-MaintainTaxCode = VALUE #( FOR created IN mapped-MaintainTaxCode (
                                                 %CID = created-%CID
                                                 %ACTION-CopyMaintainTaxCode = if_abap_behv=>mk-on
                                                 %MSG = mbc_cp_api=>message( )->get_item_copied( )
                                                 %PATH-MaintainTaxCodeAll-%IS_DRAFT = created-%IS_DRAFT
                                                 %PATH-MaintainTaxCodeAll-SingletonID = 1 ) ).
    ENDIF.
  ENDMETHOD.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZI_MAINTAINTAXCODE' ID 'ACTVT' FIELD '02'.
    DATA(is_authorized) = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized ).
    result-%ACTION-CopyMaintainTaxCode = is_authorized.
  ENDMETHOD.
  METHOD GET_INSTANCE_FEATURES.
    result = VALUE #( FOR row IN keys ( %TKY = row-%TKY
                                        %ACTION-CopyMaintainTaxCode = COND #( WHEN row-%IS_DRAFT = if_abap_behv=>mk-off THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
    ) ).
  ENDMETHOD.
  METHOD VALIDATETRANSPORTREQUEST.
    CHECK keys_MaintainTaxCode IS NOT INITIAL.
    DATA change TYPE REQUEST FOR CHANGE ZI_MaintainTaxCode_S.
    READ ENTITY IN LOCAL MODE ZI_MaintainTaxCode_S
    FIELDS ( TransportRequestID ) WITH CORRESPONDING #( keys_MaintainTaxCodeAll )
    RESULT FINAL(transport_from_singleton).
    lhc_rap_tdat_cts=>get( )->validate_all_changes(
                                transport_request     = VALUE #( transport_from_singleton[ 1 ]-TransportRequestID OPTIONAL )
                                table_validation_keys = VALUE #(
                                                          ( table = 'ZTFI011' keys = REF #( keys_MaintainTaxCode ) )
                                                               )
                                reported              = REF #( reported )
                                failed                = REF #( failed )
                                change                = REF #( change ) ).
  ENDMETHOD.
ENDCLASS.
