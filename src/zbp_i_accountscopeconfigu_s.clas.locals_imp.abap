CLASS LHC_RAP_TDAT_CTS DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      GET
        RETURNING
          VALUE(RESULT) TYPE REF TO IF_MBC_CP_RAP_TDAT_CTS.

ENDCLASS.

CLASS LHC_RAP_TDAT_CTS IMPLEMENTATION.
  METHOD GET.
    result = mbc_cp_api=>rap_tdat_cts( tdat_name = 'ZACCOUNTSCOPECONFIGU'
                                       table_entity_relations = VALUE #(
                                         ( entity = 'AccountScopeConfigu' table = 'ZTFI_IC_ACCT' )
                                       ) ) ##NO_TEXT.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_ACCOUNTSCOPECONFIGU_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
        IMPORTING
          KEYS REQUEST requested_features FOR AccountScopeConfAll
        RESULT result,
      SELECTCUSTOMIZINGTRANSPTREQ FOR MODIFY
        IMPORTING
          KEYS FOR ACTION AccountScopeConfAll~SelectCustomizingTransptReq
        RESULT result,
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR AccountScopeConfAll
        RESULT result,
      EDIT FOR MODIFY
        IMPORTING
          KEYS FOR ACTION AccountScopeConfAll~edit.
ENDCLASS.

CLASS LHC_ZI_ACCOUNTSCOPECONFIGU_S IMPLEMENTATION.
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
               %ASSOC-_AccountScopeConfigu = edit_flag
               %FIELD-TransportRequestID = transport_feature
               %ACTION-SelectCustomizingTransptReq = COND #( WHEN key-%IS_DRAFT = if_abap_behv=>mk-off
                                                             THEN if_abap_behv=>fc-o-disabled
                                                             ELSE selecttransport_flag ) ) ).
  ENDMETHOD.
  METHOD SELECTCUSTOMIZINGTRANSPTREQ.
    MODIFY ENTITIES OF ZI_AccountScopeConfigu_S IN LOCAL MODE
      ENTITY AccountScopeConfAll
        UPDATE FIELDS ( TransportRequestID )
        WITH VALUE #( FOR key IN keys
                        ( %TKY               = key-%TKY
                          TransportRequestID = key-%PARAM-transportrequestid
                         ) ).

    READ ENTITIES OF ZI_AccountScopeConfigu_S IN LOCAL MODE
      ENTITY AccountScopeConfAll
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(entities).
    result = VALUE #( FOR entity IN entities
                        ( %TKY   = entity-%TKY
                          %PARAM = entity ) ).
  ENDMETHOD.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZI_ACCOUNTSCOPECONFIGU' ID 'ACTVT' FIELD '02'.
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
      MODIFY ENTITY IN LOCAL MODE ZI_AccountScopeConfigu_S
        EXECUTE SelectCustomizingTransptReq FROM VALUE #( ( %IS_DRAFT = if_abap_behv=>mk-on
                                                            SingletonID = 1
                                                            %PARAM-transportrequestid = transport_request ) ).
      reported-AccountScopeConfAll = VALUE #( ( %IS_DRAFT = if_abap_behv=>mk-on
                                     SingletonID = 1
                                     %MSG = mbc_cp_api=>message( )->get_transport_selected( transport_request ) ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
CLASS LSC_ZI_ACCOUNTSCOPECONFIGU_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_SAVER.
  PROTECTED SECTION.
    METHODS:
      SAVE_MODIFIED REDEFINITION.
ENDCLASS.

CLASS LSC_ZI_ACCOUNTSCOPECONFIGU_S IMPLEMENTATION.
  METHOD SAVE_MODIFIED.
    DATA(transport_from_singleton) = VALUE #( update-AccountScopeConfAll[ 1 ]-TransportRequestID OPTIONAL ).
    IF transport_from_singleton IS NOT INITIAL.
      lhc_rap_tdat_cts=>get( )->record_changes(
                                  transport_request = transport_from_singleton
                                  create            = REF #( create )
                                  update            = REF #( update )
                                  delete            = REF #( delete ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_ACCOUNTSCOPECONFIGU DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_FEATURES FOR GLOBAL FEATURES
        IMPORTING
          REQUEST REQUESTED_FEATURES FOR AccountScopeConfigu
        RESULT result,
      COPYACCOUNTSCOPECONFIGU FOR MODIFY
        IMPORTING
          KEYS FOR ACTION AccountScopeConfigu~CopyAccountScopeConfigu,
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR AccountScopeConfigu
        RESULT result,
      GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
        IMPORTING
          KEYS REQUEST requested_features FOR AccountScopeConfigu
        RESULT result,
      VALIDATETRANSPORTREQUEST FOR VALIDATE ON SAVE
        IMPORTING
          KEYS_ACCOUNTSCOPECONFALL FOR AccountScopeConfAll~ValidateTransportRequest
          KEYS_ACCOUNTSCOPECONFIGU FOR AccountScopeConfigu~ValidateTransportRequest.
ENDCLASS.

CLASS LHC_ZI_ACCOUNTSCOPECONFIGU IMPLEMENTATION.
  METHOD GET_GLOBAL_FEATURES.
    DATA edit_flag TYPE abp_behv_op_ctrl VALUE if_abap_behv=>fc-o-enabled.
    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    result-%UPDATE = edit_flag.
    result-%DELETE = edit_flag.
  ENDMETHOD.
  METHOD COPYACCOUNTSCOPECONFIGU.
    DATA new_AccountScopeConfigu TYPE TABLE FOR CREATE ZI_AccountScopeConfigu_S\_AccountScopeConfigu.

    IF lines( keys ) > 1.
      INSERT mbc_cp_api=>message( )->get_select_only_one_entry( ) INTO TABLE reported-%other.
      failed-AccountScopeConfigu = VALUE #( FOR fkey IN keys ( %TKY = fkey-%TKY ) ).
      RETURN.
    ENDIF.

    READ ENTITIES OF ZI_AccountScopeConfigu_S IN LOCAL MODE
      ENTITY AccountScopeConfigu
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(ref_AccountScopeConfigu)
        FAILED DATA(read_failed).

    IF ref_AccountScopeConfigu IS NOT INITIAL.
      ASSIGN ref_AccountScopeConfigu[ 1 ] TO FIELD-SYMBOL(<ref_AccountScopeConfigu>).
      DATA(key) = keys[ KEY draft %TKY = <ref_AccountScopeConfigu>-%TKY ].
      DATA(key_cid) = key-%CID.
      APPEND VALUE #(
        %TKY-SingletonID = 1
        %IS_DRAFT = <ref_AccountScopeConfigu>-%IS_DRAFT
        %TARGET = VALUE #( (
          %CID = key_cid
          %IS_DRAFT = <ref_AccountScopeConfigu>-%IS_DRAFT
          %DATA = CORRESPONDING #( <ref_AccountScopeConfigu> EXCEPT
          SingletonID
          Createdby
          Createdat
          Lastchangedby
          Lastchangedat
          Locallastchangedat
        ) ) )
      ) TO new_AccountScopeConfigu ASSIGNING FIELD-SYMBOL(<new_AccountScopeConfigu>).
      <new_AccountScopeConfigu>-%TARGET[ 1 ]-Item = to_upper( key-%PARAM-Item ).
      <new_AccountScopeConfigu>-%TARGET[ 1 ]-Type = to_upper( key-%PARAM-Type ).
      <new_AccountScopeConfigu>-%TARGET[ 1 ]-Sign = to_upper( key-%PARAM-Sign ).
      <new_AccountScopeConfigu>-%TARGET[ 1 ]-Zoption = to_upper( key-%PARAM-Zoption ).
      <new_AccountScopeConfigu>-%TARGET[ 1 ]-Accountfrom = to_upper( key-%PARAM-Accountfrom ).

      MODIFY ENTITIES OF ZI_AccountScopeConfigu_S IN LOCAL MODE
        ENTITY AccountScopeConfAll CREATE BY \_AccountScopeConfigu
        FIELDS (
                 Item
                 Type
                 Sign
                 Zoption
                 Accountfrom
                 Accountto
               ) WITH new_AccountScopeConfigu
        MAPPED DATA(mapped_create)
        FAILED failed
        REPORTED reported.

      mapped-AccountScopeConfigu = mapped_create-AccountScopeConfigu.
    ENDIF.

    INSERT LINES OF read_failed-AccountScopeConfigu INTO TABLE failed-AccountScopeConfigu.

    IF failed-AccountScopeConfigu IS INITIAL.
      reported-AccountScopeConfigu = VALUE #( FOR created IN mapped-AccountScopeConfigu (
                                                 %CID = created-%CID
                                                 %ACTION-CopyAccountScopeConfigu = if_abap_behv=>mk-on
                                                 %MSG = mbc_cp_api=>message( )->get_item_copied( )
                                                 %PATH-AccountScopeConfAll-%IS_DRAFT = created-%IS_DRAFT
                                                 %PATH-AccountScopeConfAll-SingletonID = 1 ) ).
    ENDIF.
  ENDMETHOD.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZI_ACCOUNTSCOPECONFIGU' ID 'ACTVT' FIELD '02'.
    DATA(is_authorized) = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized ).
    result-%ACTION-CopyAccountScopeConfigu = is_authorized.
  ENDMETHOD.
  METHOD GET_INSTANCE_FEATURES.
    result = VALUE #( FOR row IN keys ( %TKY = row-%TKY
                                        %ACTION-CopyAccountScopeConfigu = COND #( WHEN row-%IS_DRAFT = if_abap_behv=>mk-off THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
    ) ).
  ENDMETHOD.
  METHOD VALIDATETRANSPORTREQUEST.
    CHECK keys_AccountScopeConfigu IS NOT INITIAL.
    DATA change TYPE REQUEST FOR CHANGE ZI_AccountScopeConfigu_S.
    READ ENTITY IN LOCAL MODE ZI_AccountScopeConfigu_S
    FIELDS ( TransportRequestID ) WITH CORRESPONDING #( keys_AccountScopeConfAll )
    RESULT FINAL(transport_from_singleton).
    lhc_rap_tdat_cts=>get( )->validate_all_changes(
                                transport_request     = VALUE #( transport_from_singleton[ 1 ]-TransportRequestID OPTIONAL )
                                table_validation_keys = VALUE #(
                                                          ( table = 'ZTFI_IC_ACCT' keys = REF #( keys_AccountScopeConfigu ) )
                                                               )
                                reported              = REF #( reported )
                                failed                = REF #( failed )
                                change                = REF #( change ) ).
  ENDMETHOD.
ENDCLASS.
