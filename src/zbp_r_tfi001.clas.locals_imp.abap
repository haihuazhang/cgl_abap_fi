CLASS lhc_repayment DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    TYPES : ts_interest  TYPE STRUCTURE FOR READ RESULT zr_tfi001\\interest,
            tt_repayment TYPE TABLE FOR READ RESULT zr_tfi001\\interest\_repayment.

    METHODS checkrepayment FOR VALIDATE ON SAVE
      IMPORTING keys FOR repayment~checkrepayment.
*    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
*      IMPORTING REQUEST requested_authorizations FOR repayment RESULT result.

    METHODS postingofrepayment FOR MODIFY
      IMPORTING keys FOR ACTION repayment~postingofrepayment.
    METHODS getrepaymentpoststatus FOR READ
      IMPORTING keys FOR FUNCTION repayment~getrepaymentpoststatus RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR repayment RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR repayment RESULT result.

    METHODS calculate_accumulatedinterest
      IMPORTING interest                   TYPE ts_interest
                repayments                 TYPE tt_repayment
      RETURNING VALUE(accumulatedinterest) TYPE zzefi014.

ENDCLASS.

CLASS lhc_repayment IMPLEMENTATION.

  METHOD checkrepayment.
    " Check Mandatory Fields
    DATA permission_request TYPE STRUCTURE FOR PERMISSIONS REQUEST zr_tfi002.
    DATA(description_permission_request) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data_ref( REF #( permission_request-%field ) ) ).
    DATA(components_permission_request) = description_permission_request->get_components(  ).

    DATA reported_field LIKE LINE OF reported-repayment.



    LOOP AT components_permission_request INTO DATA(component_permission_request).
      permission_request-%field-(component_permission_request-name) = if_abap_behv=>mk-on.
    ENDLOOP.

*    GET PERMISSIONS ONLY GLOBAL FEATURES ENTITY zhdr_dmp_t_import REQUEST permission_request
*        RESULT DATA(permission_result).

    " Get current field values
    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
    ENTITY repayment
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(repayments)
    BY \_interest
     ALL FIELDS WITH CORRESPONDING #( keys )
     RESULT DATA(interests).


*    READ ENTITIES OF zzi_zt_dtimp_conf IN LOCAL MODE
*        ENTITY Configuration BY \_Structures
*        ALL FIELDS WITH VALUE #( FOR structure IN structures ( %tky-%is_draft = structure-%is_draft
*                                                   %tky-uuid = structure-UUIDConf ) )
*        RESULT DATA(lt_all_structure).

    LOOP AT repayments ASSIGNING FIELD-SYMBOL(<repayment>).
      APPEND VALUE #( %tky        = <repayment>-%tky
              %state_area = if_abap_behv=>state_area_all ) TO reported-repayment.

      GET PERMISSIONS ONLY FEATURES ENTITY zr_tfi002
                FROM VALUE #( ( %tky = <repayment>-%tky ) )
                REQUEST permission_request
                RESULT DATA(permission_result_instance)
                FAILED DATA(failed_permission_result)
                REPORTED DATA(reported_permission_result).

      LOOP AT components_permission_request INTO component_permission_request.

        "permission result for instances (field ( features : instance ) MandFieldInstfeat;) is stored in an internal table.
        "So we have to retrieve the information for the current entity
        "whereas the global information (field ( mandatory ) MandFieldBdef;) is stored in a structure
        IF ( permission_result_instance-instances[ KEY entity uuid = <repayment>-uuid ]-%field-(component_permission_request-name) = if_abap_behv=>fc-f-mandatory OR
             permission_result_instance-global-%field-(component_permission_request-name) = if_abap_behv=>fc-f-mandatory ) AND
             <repayment>-(component_permission_request-name) IS INITIAL.

          APPEND VALUE #( %tky = <repayment>-%tky ) TO failed-repayment.

          "since %element-(component_permission_request-name) = if_abap_behv=>mk-on could not be added using a VALUE statement
          "add the value via assigning value to the field of a structure

          CLEAR reported_field.
          reported_field-%tky = <repayment>-%tky.
          reported_field-%element-(component_permission_request-name) = if_abap_behv=>mk-on.
          reported_field-%msg = new_message( id       = 'SABP_BEHV'
                                                         number   = 100
                                                         severity = if_abap_behv_message=>severity-error
                                                         v1       = |{ component_permission_request-name } is required.| ).
          reported_field-%path =  VALUE #( interest = VALUE #( %is_draft = <repayment>-%tky-%is_draft
                                                                    uuid = <repayment>-uuidinterest ) ).
          reported_field-%state_area = 'VAL_REPAYMENT'.
          APPEND reported_field  TO reported-repayment.

        ENDIF.
      ENDLOOP.

    ENDLOOP.

    DATA : reported_field_interest LIKE LINE OF reported-interest.
    DATA : lv_principal_repayment_total TYPE zzefi021,
           lv_interest_repayment_total  TYPE zzefi021.
    "Get Repayments all by Interest
    READ ENTITIES OF zr_tfi001
        IN LOCAL MODE
        ENTITY interest BY \_repayment
        ALL FIELDS WITH CORRESPONDING #( interests )
        RESULT DATA(repayments_all).

    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
      CLEAR : lv_principal_repayment_total, lv_interest_repayment_total.
      APPEND VALUE #( %tky        = <interest>-%tky
              %state_area = if_abap_behv=>state_area_all ) TO reported-interest.



      LOOP AT repayments_all ASSIGNING <repayment> WHERE uuidinterest = <interest>-uuid.
        CASE <repayment>-repaymenttype1.
          WHEN zzcl_fi_001=>repaymenttype-balance.
            lv_principal_repayment_total += <repayment>-repaymentamount.
          WHEN zzcl_fi_001=>repaymenttype-interest.
            lv_interest_repayment_total += <repayment>-repaymentamount.
        ENDCASE.
      ENDLOOP.
      "Check Total Principal Repayment Amount not greater than Initial Principal



      IF lv_principal_repayment_total > <interest>-initialprincipal.


        APPEND VALUE #( %tky = <interest>-%tky ) TO failed-interest.

        CLEAR reported_field.
        reported_field_interest-%tky = <interest>-%tky.
*        reported_field_interest-%element- = if_abap_behv=>mk-on.
        reported_field_interest-%msg = new_message( id       = 'ZZFI'
                                                       number   = 004
                                                       severity = if_abap_behv_message=>severity-error
                                          ).
        reported_field_interest-%state_area = 'VAL_INTEREST'.
        reported_field_interest-%action-prepare = if_abap_behv=>mk-on.
        APPEND reported_field_interest  TO reported-interest.
      ENDIF.
      "Total Interest Repayment Amount not greater than Accumulated Interest
*      SELECT SINGLE accumulatedinterest
*        FROM zr_tfi001 WITH PRIVILEGED ACCESS
*        WHERE uuid = @<interest>-uuid
*        INTO @DATA(accumulatedinterest).

*      IF lv_interest_repayment_total > <interest>-accumulatedinterest.
      IF lv_interest_repayment_total > calculate_accumulatedinterest(
              interest = <interest>
              repayments = repayments_all
            ).
        APPEND VALUE #( %tky = <interest>-%tky ) TO failed-interest.

        CLEAR reported_field_interest.
        reported_field_interest-%tky = <interest>-%tky.
*        reported_field_interest-%element- = if_abap_behv=>mk-on.
        reported_field_interest-%msg = new_message( id       = 'ZZFI'
                                                       number   = 004
                                                       severity = if_abap_behv_message=>severity-error
                                          ).
        reported_field_interest-%state_area = 'VAL_INTEREST'.
        reported_field_interest-%action-prepare = if_abap_behv=>mk-on.
        APPEND reported_field_interest  TO reported-interest.
      ENDIF.

    ENDLOOP.


  ENDMETHOD.

*  METHOD get_global_authorizations.
*
*  ENDMETHOD.

  METHOD postingofrepayment.

    DATA :
      lt_repayment_u TYPE TABLE FOR UPDATE zr_tfi001\\repayment,
      ls_repayment_u TYPE STRUCTURE FOR UPDATE zr_tfi001\\repayment,
      lv_je_lender   TYPE belnr_d,
      lv_je_borrower TYPE belnr_d,
      lv_fiscalyear  TYPE gjahr,
      lt_message     TYPE bapirettab.


    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
                ENTITY repayment
                EXECUTE getrepaymentpoststatus FROM CORRESPONDING #( keys ) RESULT DATA(repaymentstatus_t)
                ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(repayments)
                BY \_interest ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(interests)

                FAILED failed.


    LOOP AT repayments ASSIGNING FIELD-SYMBOL(<repayment>).
      CLEAR : lv_je_lender , lv_je_borrower ,  ls_repayment_u  , lv_fiscalyear, lt_message.


      DATA(ls_interest) = interests[ KEY id %is_draft = <repayment>-%is_draft %key-uuid = <repayment>-uuidinterest ].
      "Post Journal Entries - Post Lender/Borrower journal entry that is not posted

      zzcl_fi_001=>createjournalentrydoc(
        EXPORTING
            type = SWITCH #(  <repayment>-repaymenttype1
                                WHEN zzcl_fi_001=>repaymenttype-balance THEN zzcl_fi_001=>type-postingofrepaymentbalance
                                WHEN zzcl_fi_001=>repaymenttype-interest THEN zzcl_fi_001=>type-postingofrepaymentinterest
                            )
                            interest = ls_interest
                            repayment = <repayment>
                            inputparams = VALUE #(
                                postingdate = <repayment>-repaymentdate
                            )
*                            inputparams = CORRESPONDING #( keys[ KEY id %tky = <repayment>-%tky ]-%param )
                            lenderstatus = repaymentstatus_t[ KEY id %tky = <repayment>-%tky ]-%param-lenderstatus
                            borrowerstatus = repaymentstatus_t[ KEY id %tky = <repayment>-%tky ]-%param-borrowerstatus
        IMPORTING
            ev_fiscalyear = lv_fiscalyear
            ev_je_lender = lv_je_lender
            ev_je_borrower = lv_je_borrower
            et_message = lt_message
      ).
      IF lv_je_lender IS INITIAL AND lv_je_borrower IS INITIAL.
        APPEND VALUE #(
            %tky = <repayment>-%tky
        ) TO failed-repayment.
      ELSE.
        " Modify repayment
        ls_repayment_u = VALUE #(
            %tky = <repayment>-%tky
                  fiscalyear = lv_fiscalyear
                  postingdate = <repayment>-repaymentdate
*                  postingdate = keys[ KEY id %tky = <repayment>-%tky ]-%param-postingdate
                  journalentrylender = lv_je_lender
                  journalentryborrower = lv_je_borrower
                  lender = ls_interest-lender
                  borrower = ls_interest-borrower
                  lendercompany = ls_interest-lendercompany
                  borrowercompany = ls_interest-borrowercompany
            %control = VALUE #(
              fiscalyear = if_abap_behv=>mk-on
              postingdate = if_abap_behv=>mk-on
              journalentrylender = if_abap_behv=>mk-on
              journalentryborrower = if_abap_behv=>mk-on
              lender = if_abap_behv=>mk-on
              borrower = if_abap_behv=>mk-on
              lendercompany = if_abap_behv=>mk-on
              borrowercompany = if_abap_behv=>mk-on
            )
        ).
        APPEND ls_repayment_u TO lt_repayment_u.
      ENDIF.

      "Process Message
      LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<msgitem>).
        APPEND VALUE #(
          %tky = <repayment>-%tky
          %msg = new_message(
              id = <msgitem>-id
              number = <msgitem>-number
              severity = CONV if_abap_behv_message=>t_severity( <msgitem>-type )
              v1 = <msgitem>-message_v1
              v2 = <msgitem>-message_v2
              v3 = <msgitem>-message_v3
              v4 = <msgitem>-message_v4
           )
        ) TO reported-repayment.
      ENDLOOP.
      .
    ENDLOOP.

    MODIFY ENTITIES OF zr_tfi001
      IN LOCAL MODE
          ENTITY repayment
            UPDATE FROM lt_repayment_u

          REPORTED DATA(reported_n)
          MAPPED DATA(mapped_n)
          FAILED DATA(failed_n).
    reported = CORRESPONDING #( APPENDING ( reported ) reported_n ).
    mapped = CORRESPONDING #( APPENDING ( mapped ) mapped_n ).
    failed = CORRESPONDING #( APPENDING ( failed ) failed_n ).
  ENDMETHOD.

  METHOD getrepaymentpoststatus.
    DATA: ls_repaymentpoststatus TYPE STRUCTURE  FOR FUNCTION RESULT zr_tfi001\\repayment~getrepaymentpoststatus.
    READ ENTITIES OF zr_tfi001
        IN LOCAL MODE
        ENTITY repayment ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(lt_repayment)
        BY \_interest ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(lt_interest).

    LOOP AT lt_repayment ASSIGNING FIELD-SYMBOL(<repayment>).

      READ TABLE lt_interest ASSIGNING FIELD-SYMBOL(<interest>) WITH KEY uuid = <repayment>-uuidinterest
                                                                         %is_draft = <repayment>-%is_draft.
      IF sy-subrc = 0.
        SELECT SINGLE poststatus
        FROM zi_loanplatformcompany WITH PRIVILEGED ACCESS
        WHERE companycode = @<interest>-lender
         INTO @DATA(lender_cannot_post).

        SELECT SINGLE poststatus
          FROM zi_loanplatformcompany WITH PRIVILEGED ACCESS
          WHERE companycode = @<interest>-borrower
          INTO @DATA(borrower_cannot_post).
      ENDIF.



      ls_repaymentpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-notposted.
      ls_repaymentpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-notposted.
      IF lt_interest[ KEY id uuid = <repayment>-uuidinterest %is_draft = <repayment>-%is_draft ]-lender = space OR lender_cannot_post = abap_true .
        ls_repaymentpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-cannotpost.
      ELSEIF <repayment>-jelenderstatuscriticality = zzcl_fi_001=>poststatuscriticality-posted .
*      OR lt_interest[ KEY id uuid = <repayment>-uuidinterest %is_draft = <repayment>-%is_draft ]-lender = space.
        ls_repaymentpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-posted.
      ELSE.
        ls_repaymentpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-notposted.
      ENDIF.


*      IF <repayment>-journalentryborrower IS NOT INITIAL.
      IF lt_interest[ KEY id uuid = <repayment>-uuidinterest %is_draft = <repayment>-%is_draft ]-borrower = space OR borrower_cannot_post = abap_true.
        ls_repaymentpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-cannotpost.
      ELSEIF <repayment>-jeborrowerstatuscriticality = zzcl_fi_001=>poststatuscriticality-posted.
*      OR lt_interest[ KEY id uuid = <repayment>-uuidinterest %is_draft = <repayment>-%is_draft ]-borrower = space.
        ls_repaymentpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted.
      ELSE.
        ls_repaymentpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-notposted.
      ENDIF.
      ls_repaymentpoststatus-%tky = <repayment>-%tky.
      APPEND ls_repaymentpoststatus TO result.

      CLEAR : lender_cannot_post , borrower_cannot_post.
    ENDLOOP.


  ENDMETHOD.

  METHOD get_instance_features.
    " 从自建表ZLoanRepayment中查找Lender's Journal Entry或Borrower's Journal Entry是否有值）
    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
        ENTITY repayment ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(repayments)
        EXECUTE getrepaymentpoststatus FROM
        CORRESPONDING #( keys )
        RESULT DATA(repaymentpoststatuss)
        FAILED failed.

    LOOP AT repaymentpoststatuss ASSIGNING FIELD-SYMBOL(<repaymentpoststatus>).

      APPEND VALUE #(
          %tky                           = <repaymentpoststatus>-%tky
          %action-postingofrepayment = COND #( WHEN ( <repaymentpoststatus>-%param-lenderstatus = zzcl_fi_001=>poststatus-posted AND <repaymentpoststatus>-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted ) OR
                                                        ( repayments[ KEY id %tky = <repaymentpoststatus>-%tky ]-%is_draft = if_abap_behv=>mk-on )
                                                        THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled
              )
           %field-currency = if_abap_behv=>fc-f-read_only
           %update = COND #( WHEN <repaymentpoststatus>-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR <repaymentpoststatus>-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted
                                                        THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled
              )
           %delete = COND #( WHEN <repaymentpoststatus>-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR <repaymentpoststatus>-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted
                                                        THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled
              )
      ) TO result.
    ENDLOOP.

*    result = VALUE #( FOR repaymentpoststatus IN repaymentpoststatuss
*           ( %tky                           = repaymentpoststatus-%tky
*             %action-postingofrepayment = COND #( WHEN ( repaymentpoststatus-%param-lenderstatus = '1' AND repaymentpoststatus-%param-borrowerstatus = '1' )
*                                                          THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled
*                )
*             %field-currency = if_abap_behv=>fc-f-read_only
*             %update = COND #( WHEN repaymentpoststatus-%param-lenderstatus = '1' OR repaymentpoststatus-%param-borrowerstatus = '1'
*                                                          THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled
*                )
*             %delete = COND #( WHEN repaymentpoststatus-%param-lenderstatus = '1' OR repaymentpoststatus-%param-borrowerstatus = '1'
*                                                          THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled
*                )
*          ) ).

  ENDMETHOD.
  METHOD get_instance_authorizations.
*

    DATA: post_repayment_requested               TYPE abap_boolean.

    IF requested_authorizations-%action-postingofrepayment = if_abap_behv=>mk-on.
      post_repayment_requested = abap_true.
    ENDIF.

    READ ENTITIES OF zr_tfi001
    IN LOCAL MODE
        ENTITY repayment ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(repayments)
        BY \_interest ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(loans).

    LOOP AT repayments ASSIGNING FIELD-SYMBOL(<repayment>).
      APPEND VALUE #(
        %tky = <repayment>-%tky
       ) TO result ASSIGNING FIELD-SYMBOL(<repayment_auth>).
      IF post_repayment_requested = abap_true.
        DATA(lender_company) = loans[ KEY id uuid = <repayment>-uuidinterest %is_draft = <repayment>-%is_draft ]-lendercompany.
        DATA(borrower_company) = loans[ KEY id uuid = <repayment>-uuidinterest %is_draft = <repayment>-%is_draft ]-borrowercompany.
        AUTHORITY-CHECK OBJECT 'ZZAOFI002'
                ID 'ZZAFFI002' FIELD lender_company
                ID 'ZZAFFI003' FIELD borrower_company
                ID 'ZZAFFI001' FIELD '3'
                ID 'ACTVT'    FIELD '10'.
        IF sy-subrc NE 0.
          <repayment_auth>-%action-postingofrepayment = if_abap_behv=>auth-unauthorized.
        ELSE.
          <repayment_auth>-%action-postingofrepayment = if_abap_behv=>auth-allowed.
        ENDIF.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD calculate_accumulatedinterest.
    DATA(principal_repayments) = REDUCE zzefi021(  INIT amount TYPE zzefi021
                                                  FOR line IN
*                                                  FILTER #(
                                                    repayments WHERE ( repaymenttype1 = zzcl_fi_001=>repaymenttype-balance AND repaymentdate <= cl_abap_context_info=>get_system_date(  )
                                                                       AND uuidinterest = interest-uuid
*                                                                                  AND
*                                                    AND currency <> space
                                                   )
                                                  NEXT amount = amount + line-repaymentamount
                                                    ).
    DATA principal_balance TYPE zzefi011.

    " Principal balance
    principal_balance = interest-initialprincipal - principal_repayments.
    DATA(days_between) = cl_abap_context_info=>get_system_date(  ) - interest-startdate + 1.

    " Interests calculated by amount not paid
    DATA remain_interests TYPE zzefi014.
    remain_interests = principal_balance * interest-exrates / 365 * days_between.

    " Interests calculated by amount that already paid
    DATA(paid_interests) = REDUCE zzefi014(  INIT amount TYPE zzefi014
                                                FOR line IN repayments WHERE ( repaymenttype1 = zzcl_fi_001=>repaymenttype-balance AND repaymentdate <= cl_abap_context_info=>get_system_date(  )
                                                    AND uuidinterest = interest-uuid
                                                )
                                                NEXT amount = amount + line-repaymentamount * interest-exrates / 365 * ( line-repaymentdate - interest-startdate + 1 )
    ).

    accumulatedinterest = remain_interests + paid_interests.


  ENDMETHOD.

ENDCLASS.

CLASS lhc_zr_tfi001 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR interest
        RESULT result,
      determinationforinterest FOR DETERMINE ON SAVE
        IMPORTING keys FOR interest~determinationforinterest,
      checkinterest FOR VALIDATE ON SAVE
        IMPORTING keys FOR interest~checkinterest,
      getloanpoststatus FOR READ
        IMPORTING keys FOR FUNCTION interest~getloanpoststatus RESULT result,
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR interest RESULT result,
      postingofinitialprincipal FOR MODIFY
        IMPORTING keys FOR ACTION interest~postingofinitialprincipal,
      getcurrentmonthaccrualstatus FOR READ
        IMPORTING keys FOR FUNCTION interest~getcurrentmonthaccrualstatus RESULT result,

      getdefaultsforpip FOR READ
        IMPORTING keys FOR FUNCTION interest~getdefaultsforpip RESULT result,
      getdefaultsforpmai FOR READ
        IMPORTING keys FOR FUNCTION interest~getdefaultsforpmai RESULT result.

    METHODS postingofmonthlyaccrualint FOR MODIFY
      IMPORTING keys FOR ACTION interest~postingofmonthlyaccrualint.
    METHODS precheck_delete FOR PRECHECK
      IMPORTING keys FOR DELETE interest.
    METHODS getdefaultsforrepayment FOR READ
      IMPORTING keys FOR FUNCTION interest~getdefaultsforrepayment RESULT result.
    METHODS getdefaultsforcreate FOR READ
      IMPORTING keys FOR FUNCTION interest~getdefaultsforcreate RESULT result.
*    METHODS determinationforexchangerate FOR DETERMINE ON MODIFY
*      IMPORTING keys FOR interest~determinationforexchangerate.

    METHODS determinationformaturitydate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR interest~determinationformaturitydate.
    METHODS copyloan FOR MODIFY
      IMPORTING keys FOR ACTION interest~copyloan.
    METHODS determinationforcompanycode FOR DETERMINE ON MODIFY
      IMPORTING keys FOR interest~determinationforcompanycode.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR interest RESULT result.
    METHODS determinationforexrate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR interest~determinationforexrate.
ENDCLASS.

CLASS lhc_zr_tfi001 IMPLEMENTATION.
  METHOD get_global_authorizations.
*    if requested_authorizations-
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'ZZAOFI002'
      ID 'ZZAFFI002' DUMMY
      ID 'ZZAFFI003' DUMMY
      ID 'ZZAFFI001' DUMMY
      ID 'ACTVT'  FIELD  '01'.
      IF sy-subrc NE 0.
        result-%create = if_abap_behv=>auth-unauthorized.
      ELSE.
        result-%create = if_abap_behv=>auth-allowed.
      ENDIF.
    ENDIF.

  ENDMETHOD.
  METHOD determinationforinterest.
    DATA : lv_num_3 TYPE n LENGTH 3.

    READ ENTITIES OF zr_tfi001
        IN LOCAL MODE
        ENTITY interest
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_interest).

    DATA(lo_random) = cl_abap_random_int=>create(  ).

    LOOP AT lt_interest ASSIGNING FIELD-SYMBOL(<fs_interest>).
      CLEAR : lv_num_3.
      " Get Month from Start Date
      SELECT SINGLE calendarmonth,
                    calendaryear
        FROM i_calendardate WITH PRIVILEGED ACCESS
        WHERE calendardate = @<fs_interest>-startdate
        INTO @DATA(ls_date).


      DATA(lo_numberrangebuf) = cl_numberrange_buffer=>get_instance( ).
      TRY.
          lo_numberrangebuf->if_numberrange_buffer~number_get_main_memory(
            EXPORTING
                iv_object = 'ZZNR001'
                iv_interval = CONV if_numberrange_buffer=>nr_interval( ls_date-calendarmonth )
                iv_toyear = ls_date-calendaryear
                iv_quantity =  1
            IMPORTING
                ev_number = DATA(lv_number)

          ).
          lv_num_3 = lv_number.
        CATCH cx_number_ranges.
          "handle exception
          lv_num_3 = 000.
      ENDTRY.



      <fs_interest>-contractcode = condense(
            val = |{ <fs_interest>-startdate+4(2) }{ <fs_interest>-startdate+2(2) }_{ lv_num_3 } |
            to = ``
      ).
    ENDLOOP.


    MODIFY ENTITIES OF zr_tfi001
        IN LOCAL MODE
        ENTITY interest
        UPDATE FIELDS ( contractcode )
        WITH CORRESPONDING #( lt_interest ).
  ENDMETHOD.

  METHOD checkinterest.
    " Check Mandatory Fields
    DATA permission_request TYPE STRUCTURE FOR PERMISSIONS REQUEST zr_tfi001.
    DATA(description_permission_request) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data_ref( REF #( permission_request-%field ) ) ).
    DATA(components_permission_request) = description_permission_request->get_components(  ).

    DATA reported_field LIKE LINE OF reported-interest.



    LOOP AT components_permission_request INTO DATA(component_permission_request).
      permission_request-%field-(component_permission_request-name) = if_abap_behv=>mk-on.
    ENDLOOP.

    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
    ENTITY interest
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(interests)

    BY \_repayment
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(repayments).


    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
      APPEND VALUE #( %tky        = <interest>-%tky
                  %state_area = if_abap_behv=>state_area_all ) TO reported-interest.
      GET PERMISSIONS ONLY FEATURES ENTITY zr_tfi001
            FROM VALUE #( ( %tky = <interest>-%tky ) )
            REQUEST permission_request
            RESULT DATA(permission_result_instance)
            FAILED DATA(failed_permission_result)
            REPORTED DATA(reported_permission_result).

      LOOP AT components_permission_request INTO component_permission_request.

        "permission result for instances (field ( features : instance ) MandFieldInstfeat;) is stored in an internal table.
        "So we have to retrieve the information for the current entity
        "whereas the global information (field ( mandatory ) MandFieldBdef;) is stored in a structure
        IF ( permission_result_instance-instances[ KEY entity uuid = <interest>-uuid ]-%field-(component_permission_request-name) = if_abap_behv=>fc-f-mandatory OR
             permission_result_instance-global-%field-(component_permission_request-name) = if_abap_behv=>fc-f-mandatory ) AND
             <interest>-(component_permission_request-name) IS INITIAL.

          APPEND VALUE #( %tky = <interest>-%tky ) TO failed-interest.

          "since %element-(component_permission_request-name) = if_abap_behv=>mk-on could not be added using a VALUE statement
          "add the value via assigning value to the field of a structure

          CLEAR reported_field.
          reported_field-%tky = <interest>-%tky.
          reported_field-%element-(component_permission_request-name) = if_abap_behv=>mk-on.
          reported_field-%msg = new_message( id       = 'SABP_BEHV'
                                                         number   = 100
                                                         severity = if_abap_behv_message=>severity-error
                                                         v1       = |{ component_permission_request-name } is required.| ).
          reported_field-%state_area = 'VAL_INTEREST'.
          reported_field-%action-prepare = if_abap_behv=>mk-on.
          APPEND reported_field  TO reported-interest.

        ENDIF.
      ENDLOOP.


      "Check Total Principal Repayment Amount not greater than Initial Principal
      IF <interest>-principalbalance < 0.
        APPEND VALUE #( %tky = <interest>-%tky ) TO failed-interest.

        CLEAR reported_field.
        reported_field-%tky = <interest>-%tky.
*        reported_field-%element- = if_abap_behv=>mk-on.
        reported_field-%msg = new_message( id       = 'ZZFI'
                                                       number   = 004
                                                       severity = if_abap_behv_message=>severity-error
                                          ).
        reported_field-%state_area = 'VAL_INTEREST'.
        reported_field-%action-prepare = if_abap_behv=>mk-on.
        APPEND reported_field  TO reported-interest.
      ENDIF.
      "Total Interest Repayment Amount not greater than Accumulated Interest
      IF <interest>-interestbalance < 0.
        APPEND VALUE #( %tky = <interest>-%tky ) TO failed-interest.

        CLEAR reported_field.
        reported_field-%tky = <interest>-%tky.
*        reported_field-%element- = if_abap_behv=>mk-on.
        reported_field-%msg = new_message( id       = 'ZZFI'
                                                       number   = 004
                                                       severity = if_abap_behv_message=>severity-error
                                          ).
        reported_field-%state_area = 'VAL_INTEREST'.
        reported_field-%action-prepare = if_abap_behv=>mk-on.
        APPEND reported_field  TO reported-interest.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  "从自建表ZLoanPosting中查找Lender's Journal Entry或Borrower's Journal Entry是否有值）
  METHOD getloanpoststatus.
    DATA: ls_loanpoststatus TYPE STRUCTURE  FOR FUNCTION RESULT zr_tfi001\\interest~getloanpoststatus.
    READ ENTITIES OF zr_tfi001
        IN LOCAL MODE
        ENTITY interest
        ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_interest)
        ENTITY interest BY \_accrual
        ALL FIELDS WITH CORRESPONDING #( keys )
     RESULT DATA(lt_accrual).

    LOOP AT lt_interest ASSIGNING FIELD-SYMBOL(<interest>).
      ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-notposted.
      ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-notposted.

      SELECT SINGLE poststatus
      FROM zi_loanplatformcompany WITH PRIVILEGED ACCESS
      WHERE companycode = @<interest>-lender
       INTO @DATA(lender_cannot_post).

      SELECT SINGLE poststatus
        FROM zi_loanplatformcompany WITH PRIVILEGED ACCESS
        WHERE companycode = @<interest>-borrower
        INTO @DATA(borrower_cannot_post).

      IF  <interest>-lender = space OR lender_cannot_post = abap_true.
        ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-cannotpost.
      ELSE.
        LOOP AT lt_accrual ASSIGNING FIELD-SYMBOL(<accrual>) WHERE uuidinterest = <interest>-uuid
                                                               AND type = zzcl_fi_001=>accrualtype-postingofinitialprincipal.
*          IF  <interest>-lender = space OR lender_cannot_post = abap_true.

*            ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-cannotpost.
          IF <accrual>-jelenderstatuscriticality = zzcl_fi_001=>poststatuscriticality-posted.
*        OR <interest>-lender = space.
            ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-posted.
          ENDIF.
*          IF  <interest>-borrower = space OR borrower_cannot_post = abap_true.
*            ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-cannotpost.
*          ELSEIF <accrual>-jeborrowerstatuscriticality = zzcl_fi_001=>poststatuscriticality-posted .
**        OR <interest>-borrower = space.
*            ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted.
*          ENDIF.

        ENDLOOP.
      ENDIF.

      IF  <interest>-borrower = space OR borrower_cannot_post = abap_true.
        ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-cannotpost.
      ELSE.
        LOOP AT lt_accrual ASSIGNING <accrual> WHERE uuidinterest = <interest>-uuid
                                                               AND type = zzcl_fi_001=>accrualtype-postingofinitialprincipal.
*          IF  <interest>-lender = space OR lender_cannot_post = abap_true.
*
*            ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-cannotpost.
*          ELSEIF <accrual>-jelenderstatuscriticality = zzcl_fi_001=>poststatuscriticality-posted.
**        OR <interest>-lender = space.
*            ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-posted.
*          ENDIF.
*          IF  <interest>-borrower = space OR borrower_cannot_post = abap_true.
*            ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-cannotpost.
*          ELSE
          IF <accrual>-jeborrowerstatuscriticality = zzcl_fi_001=>poststatuscriticality-posted .
*        OR <interest>-borrower = space.
            ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted.
          ENDIF.

        ENDLOOP.
      ENDIF.


      ls_loanpoststatus-%tky = <interest>-%tky.
      APPEND ls_loanpoststatus TO result.

      CLEAR : lender_cannot_post , borrower_cannot_post.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.
    " 从自建表ZLoanPosting中查找Lender's Journal Entry或Borrower's Journal Entry是否有值）
    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
        ENTITY interest
        EXECUTE getloanpoststatus FROM
        CORRESPONDING #( keys )
        RESULT DATA(interests)

        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(interestss)
        FAILED failed.
    result = VALUE #( FOR interest IN interests
           (  %tky                           = interest-%tky
              %delete = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted
                                                          THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
*                 %update = COND #( WHEN file-JobName IS NOT INITIAL
*                                                          THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
*                 %action-Edit = COND #( WHEN file-JobName IS NOT INITIAL
*                                                          THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
              %field-contracttype = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted THEN  if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
              %field-initialprincipal = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted THEN  if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted
)
              %field-currency = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted THEN  if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
*              %field-exchangerate = COND #( WHEN interest-%param-lenderstatus = '1' OR interest-%param-borrowerstatus = '1' THEN  if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
              %field-exrates = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted THEN  if_abap_behv=>fc-f-read_only
              WHEN interestss[ KEY id %tky = interest-%tky ]-contracttype = zzcl_fi_001=>contracttype-interest_free_loan THEN if_abap_behv=>fc-f-read_only
              ELSE
              if_abap_behv=>fc-f-unrestricted )
             %field-housebanklender = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted THEN  if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
             %field-accountidlender = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted THEN  if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
             %field-housebankborrower = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted THEN  if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted
)
             %field-accountidborrower = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted THEN  if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted
)
             %field-cashflowlender = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted THEN  if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
             %field-cashflowborrower = COND #( WHEN interest-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR interest-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted THEN  if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted
)
             %action-postingofinitialprincipal = COND #( WHEN interest-%is_draft = if_abap_behv=>mk-on THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
             %action-postingofmonthlyaccrualint = COND #( WHEN interest-%is_draft = if_abap_behv=>mk-on THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
         ) ).




  ENDMETHOD.

  METHOD getcurrentmonthaccrualstatus.

    DATA: ls_loanpoststatus TYPE STRUCTURE FOR FUNCTION RESULT zr_tfi001\\interest~getcurrentmonthaccrualstatus.
    READ ENTITIES OF zr_tfi001
        IN LOCAL MODE
        ENTITY interest
        ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_interest)
        ENTITY interest BY \_accrual
        ALL FIELDS WITH CORRESPONDING #( keys )
     RESULT DATA(lt_accrual).


    LOOP AT lt_interest ASSIGNING FIELD-SYMBOL(<interest>).
      DATA(lv_date) = keys[ KEY id  %tky = <interest>-%tky ]-%param-postingdate.
      SELECT SINGLE
        firstdayofmonthdate,
        lastdayofmonthdate
        FROM i_calendardate WITH PRIVILEGED ACCESS
        WHERE calendardate = @lv_date
        INTO @DATA(ls_calendardate).

      SELECT SINGLE poststatus
        FROM zi_loanplatformcompany WITH PRIVILEGED ACCESS
        WHERE companycode = @<interest>-lender
        INTO @DATA(lender_cannot_post).

      SELECT SINGLE poststatus
        FROM zi_loanplatformcompany WITH PRIVILEGED ACCESS
        WHERE companycode = @<interest>-borrower
        INTO @DATA(borrower_cannot_post).

      ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-notposted.
      ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-notposted.


      IF <interest>-lender = space OR lender_cannot_post = abap_true.
        ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-cannotpost.
      ELSE.
        LOOP AT lt_accrual ASSIGNING FIELD-SYMBOL(<accrual>) WHERE uuidinterest = <interest>-uuid
                                                               AND type = zzcl_fi_001=>accrualtype-monthlyaccrualofinterest
                                                               AND postingdate >= ls_calendardate-firstdayofmonthdate
                                                               AND postingdate <= ls_calendardate-lastdayofmonthdate.
*        IF <interest>-lender = space OR lender_cannot_post = abap_true.
*          ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-cannotpost.
*        ELSE
          IF <accrual>-jelenderstatuscriticality = zzcl_fi_001=>poststatuscriticality-posted.
*         OR <interest>-lender = space.
            ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-posted.
*          EXIT.
          ENDIF.
*        IF <interest>-borrower = space OR borrower_cannot_post = abap_true.
*          ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-cannotpost.
*        ELSEIF <accrual>-jeborrowerstatuscriticality = zzcl_fi_001=>poststatuscriticality-posted.
**        OR <interest>-borrower = space.
*          ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted.
**          EXIT.
*        ENDIF.
        ENDLOOP.
      ENDIF.


      IF <interest>-borrower = space OR borrower_cannot_post = abap_true.
        ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-cannotpost.
      ELSE.
        LOOP AT lt_accrual ASSIGNING <accrual> WHERE uuidinterest = <interest>-uuid
                                                               AND type = zzcl_fi_001=>accrualtype-monthlyaccrualofinterest
                                                               AND postingdate >= ls_calendardate-firstdayofmonthdate
                                                               AND postingdate <= ls_calendardate-lastdayofmonthdate.
*        IF <interest>-lender = space OR lender_cannot_post = abap_true.
*          ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-cannotpost.
*        ELSEIF <accrual>-jelenderstatuscriticality = zzcl_fi_001=>poststatuscriticality-posted.
**         OR <interest>-lender = space.
*          ls_loanpoststatus-%param-lenderstatus = zzcl_fi_001=>poststatus-posted.
**          EXIT.
*        ENDIF.
*        IF <interest>-borrower = space OR borrower_cannot_post = abap_true.
*          ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-cannotpost.
*        ELSE
          IF <accrual>-jeborrowerstatuscriticality = zzcl_fi_001=>poststatuscriticality-posted.
*        OR <interest>-borrower = space.
            ls_loanpoststatus-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted.
*          EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.


      ls_loanpoststatus-%tky = <interest>-%tky.
      APPEND ls_loanpoststatus TO result.

      CLEAR : lender_cannot_post , borrower_cannot_post.
    ENDLOOP.
  ENDMETHOD.

  METHOD postingofinitialprincipal.
    DATA : lt_accrual_c   TYPE TABLE FOR CREATE zr_tfi001\\interest\_accrual,
           ls_accrual_c   TYPE STRUCTURE FOR CREATE zr_tfi001\\interest\_accrual,
           lt_accrual_u   TYPE TABLE FOR UPDATE zr_tfi001\\accrual,
           ls_accrual_u   TYPE STRUCTURE FOR UPDATE zr_tfi001\\accrual,
           lv_je_lender   TYPE belnr_d,
           lv_je_borrower TYPE belnr_d,
           lv_fiscalyear  TYPE gjahr,
           lt_message     TYPE bapirettab.


    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
                ENTITY interest
                EXECUTE getloanpoststatus FROM CORRESPONDING #( keys ) RESULT DATA(loanpoststatus_t)
                ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(interests)
                BY \_accrual ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(accruals)

                FAILED failed.


    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
      CLEAR : lv_je_lender , lv_je_borrower ,  ls_accrual_u  , ls_accrual_c, lv_fiscalyear , lt_message.

      IF
      ( loanpoststatus_t[ KEY id %tky = <interest>-%tky ]-%param-lenderstatus = zzcl_fi_001=>poststatus-posted
            AND ( loanpoststatus_t[ KEY id %tky = <interest>-%tky ]-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted
                    OR loanpoststatus_t[ KEY id %tky = <interest>-%tky ]-%param-borrowerstatus = zzcl_fi_001=>poststatus-cannotpost
        ) )

        OR ( loanpoststatus_t[ KEY id %tky = <interest>-%tky ]-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted AND (
              loanpoststatus_t[ KEY id %tky = <interest>-%tky ]-%param-lenderstatus = zzcl_fi_001=>poststatus-posted
              OR loanpoststatus_t[ KEY id %tky = <interest>-%tky ]-%param-lenderstatus = zzcl_fi_001=>poststatus-cannotpost
        ) )

        .
        APPEND VALUE #(
            %tky = <interest>-%tky
            %msg = new_message(
                id = 'ZZFI'
                number = '001'
                severity = if_abap_behv_message=>severity-error
             )
         ) TO reported-interest.
        APPEND VALUE #(
            %tky = <interest>-%tky
         ) TO failed-interest.
        CONTINUE.
      ENDIF.

      "Post Journal Entries
      zzcl_fi_001=>createjournalentrydoc(
        EXPORTING
            type = zzcl_fi_001=>type-postingofinitialprincipal
            interest = <interest>
            accruals = accruals
            inputparams = CORRESPONDING #( keys[ KEY id %tky = <interest>-%tky ]-%param )
            lenderstatus = loanpoststatus_t[ KEY id %tky = <interest>-%tky ]-%param-lenderstatus
            borrowerstatus = loanpoststatus_t[ KEY id %tky = <interest>-%tky ]-%param-borrowerstatus
        IMPORTING
            ev_fiscalyear = lv_fiscalyear
            ev_je_lender = lv_je_lender
            ev_je_borrower = lv_je_borrower
            et_message = lt_message
      ).

      IF lv_je_lender IS INITIAL AND lv_je_borrower IS INITIAL.
        APPEND VALUE #(
            %tky = <interest>-%tky
        ) TO failed-interest.
      ELSE.

        " Modify Accural
        IF line_exists( accruals[  uuidinterest = <interest>-uuid type = zzcl_fi_001=>accrualtype-postingofinitialprincipal ] ).
          ls_accrual_u = VALUE #(
              %tky = accruals[  uuidinterest = <interest>-uuid type = zzcl_fi_001=>accrualtype-postingofinitialprincipal ]-%tky
              journalentrylender = lv_je_lender
              journalentryborrower = lv_je_borrower
              lender = <interest>-lender
              borrower = <interest>-borrower
              lendercompany = <interest>-lendercompany
              borrowercompany = <interest>-borrowercompany
              amount = <interest>-initialprincipal
              currency = <interest>-currency
              fiscalyear = lv_fiscalyear
              postingdate = keys[ KEY id %tky = <interest>-%tky ]-%param-postingdate

              %control = VALUE #(
                amount = if_abap_behv=>mk-on
                currency = if_abap_behv=>mk-on
                fiscalyear = if_abap_behv=>mk-on
*                        Type = if_abap_behv=>mk-on
                postingdate = if_abap_behv=>mk-on
                journalentrylender = if_abap_behv=>mk-on
                journalentryborrower = if_abap_behv=>mk-on
                lender = if_abap_behv=>mk-on
                borrower = if_abap_behv=>mk-on
                lendercompany = if_abap_behv=>mk-on
                borrowercompany = if_abap_behv=>mk-on
              )
          ).
          APPEND ls_accrual_u TO lt_accrual_u.
        ELSE.
          ls_accrual_c = VALUE #(

            %tky = <interest>-%tky
            %target = VALUE #(
               (
               %cid = <interest>-uuid
               %data = VALUE #(
                    amount = <interest>-initialprincipal
                    currency = <interest>-currency
*                        CompanyCode =
                    fiscalyear = lv_fiscalyear
                    type = zzcl_fi_001=>accrualtype-postingofinitialprincipal
                    postingdate = keys[ KEY id %tky = <interest>-%tky ]-%param-postingdate
                    journalentrylender = lv_je_lender
                    journalentryborrower = lv_je_borrower
                    lender = <interest>-lender
                    borrower = <interest>-borrower
                    lendercompany = <interest>-lendercompany
                    borrowercompany = <interest>-borrowercompany
               )
               %control = VALUE #(
                    amount = if_abap_behv=>mk-on
                    currency = if_abap_behv=>mk-on
                    fiscalyear = if_abap_behv=>mk-on
                    type = if_abap_behv=>mk-on
                    postingdate = if_abap_behv=>mk-on
                    journalentrylender = if_abap_behv=>mk-on
                    journalentryborrower = if_abap_behv=>mk-on
                    lender = if_abap_behv=>mk-on
                    borrower = if_abap_behv=>mk-on
                    lendercompany = if_abap_behv=>mk-on
                    borrowercompany = if_abap_behv=>mk-on
               )
               )
            )
          ).
          APPEND ls_accrual_c TO lt_accrual_c.


        ENDIF.

      ENDIF.

      "Process Message
      LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<msgitem>).
        APPEND VALUE #(
          %tky = <interest>-%tky
          %msg = new_message(
              id = <msgitem>-id
              number = <msgitem>-number
              severity = CONV if_abap_behv_message=>t_severity( <msgitem>-type )
              v1 = <msgitem>-message_v1
              v2 = <msgitem>-message_v2
              v3 = <msgitem>-message_v3
              v4 = <msgitem>-message_v4
           )
        ) TO reported-interest.
      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF zr_tfi001
      IN LOCAL MODE
          ENTITY accrual
            UPDATE FROM lt_accrual_u
          ENTITY interest
            CREATE BY \_accrual FROM lt_accrual_c
          REPORTED DATA(reported_n)
          MAPPED DATA(mapped_n)
          FAILED DATA(failed_n).
    reported = CORRESPONDING #( APPENDING ( reported ) reported_n ).
    mapped = CORRESPONDING #( APPENDING ( mapped ) mapped_n ).
    failed = CORRESPONDING #( APPENDING ( failed ) failed_n ).


  ENDMETHOD.



  METHOD getdefaultsforpip.
*    DATA(lv_current_date) = cl_abap_context_info=>get_system_date(  ).

*    SELECT SINGLE lastdayofmonthdate
*        FROM i_calendardate WITH PRIVILEGED ACCESS
*        WHERE calendardate = @lv_current_date
*        INTO @DATA(lv_lastdayofmonthdate).
**********************************************************************
*** Changed by HANDZHH change default posting date to start date in loan
**********************************************************************

    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
        ENTITY interest
        FIELDS ( startdate )
        WITH CORRESPONDING #( keys )
        RESULT DATA(interests).
    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
      APPEND VALUE #(
           %tky                          = <interest>-%tky
           %param = VALUE #(
              postingdate = <interest>-startdate
           )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD getdefaultsforpmai.
    DATA(lv_current_date) = cl_abap_context_info=>get_system_date(  ).

    SELECT SINGLE lastdayofmonthdate
        FROM i_calendardate WITH PRIVILEGED ACCESS
        WHERE calendardate = @lv_current_date
        INTO @DATA(lv_lastdayofmonthdate).



    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

      APPEND VALUE #(
           %tky                          = <key>-%tky
           %param = VALUE #(
              postingdate = lv_lastdayofmonthdate
           )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.




  METHOD postingofmonthlyaccrualint.
    DATA : lt_accrual_c   TYPE TABLE FOR CREATE zr_tfi001\\interest\_accrual,
           ls_accrual_c   TYPE STRUCTURE FOR CREATE zr_tfi001\\interest\_accrual,
           lt_accrual_u   TYPE TABLE FOR UPDATE zr_tfi001\\accrual,
           ls_accrual_u   TYPE STRUCTURE FOR UPDATE zr_tfi001\\accrual,
           lv_je_lender   TYPE belnr_d,
           lv_je_borrower TYPE belnr_d,
           lv_fiscalyear  TYPE gjahr,
           lt_message     TYPE bapirettab.


    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
                ENTITY interest
                EXECUTE getcurrentmonthaccrualstatus FROM CORRESPONDING #( keys ) RESULT DATA(currentmonthaccrualstatus_t)
                ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(interests)
                BY \_accrual ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(accruals)

                FAILED failed.


    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
      CLEAR : lv_je_lender , lv_je_borrower ,  ls_accrual_u  , ls_accrual_c, lv_fiscalyear , lt_message.

      IF ( currentmonthaccrualstatus_t[ KEY id %tky = <interest>-%tky ]-%param-lenderstatus = zzcl_fi_001=>poststatus-posted AND
           ( currentmonthaccrualstatus_t[ KEY id %tky = <interest>-%tky ]-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted OR
                currentmonthaccrualstatus_t[ KEY id %tky = <interest>-%tky ]-%param-borrowerstatus = zzcl_fi_001=>poststatus-cannotpost
           ) )
           OR ( currentmonthaccrualstatus_t[ KEY id %tky = <interest>-%tky ]-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted AND
            ( currentmonthaccrualstatus_t[ KEY id %tky = <interest>-%tky ]-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR
                currentmonthaccrualstatus_t[ KEY id %tky = <interest>-%tky ]-%param-lenderstatus = zzcl_fi_001=>poststatus-cannotpost ) ).
        APPEND VALUE #(
            %tky = <interest>-%tky
            %msg = new_message(
                id = 'ZZFI'
                number = '001'
                severity = if_abap_behv_message=>severity-error
             )
         ) TO reported-interest.
        APPEND VALUE #(
            %tky = <interest>-%tky
         ) TO failed-interest.
        CONTINUE.
      ENDIF.

      "Post Journal Entries
      zzcl_fi_001=>createjournalentrydoc(
        EXPORTING
            type = zzcl_fi_001=>type-monthlyaccrualofinterest
            interest = <interest>
            accruals = accruals
            inputparams = CORRESPONDING #( keys[ KEY id %tky = <interest>-%tky ]-%param )
            lenderstatus = currentmonthaccrualstatus_t[ KEY id %tky = <interest>-%tky ]-%param-lenderstatus
            borrowerstatus = currentmonthaccrualstatus_t[ KEY id %tky = <interest>-%tky ]-%param-borrowerstatus
        IMPORTING
            ev_fiscalyear = lv_fiscalyear
            ev_je_lender = lv_je_lender
            ev_je_borrower = lv_je_borrower
            et_message = lt_message
        ).


      IF lv_je_lender IS INITIAL AND lv_je_borrower IS INITIAL.
        APPEND VALUE #(
            %tky = <interest>-%tky
        ) TO failed-interest.
      ELSE.
        " Modify accural
        DATA(lv_postingdate) = keys[ KEY id %tky = <interest>-%tky ]-%param-postingdate.
        SELECT SINGLE monthlyinterestaccrual
            FROM zr_sfi008( p_date = @lv_postingdate )
            WHERE uuid = @<interest>-uuid
            INTO @DATA(lv_monthlyinterestaccrual).

        SELECT SINGLE
           firstdayofmonthdate,
           lastdayofmonthdate
          FROM i_calendardate WITH PRIVILEGED ACCESS
          WHERE calendardate = @lv_postingdate
          INTO @DATA(ls_calendardate).

        DATA : line_exists TYPE abap_boolean,
               ls_accrual  TYPE STRUCTURE FOR READ RESULT zr_tfi001\\interest\_accrual.
        line_exists = abap_false.
        CLEAR : ls_accrual.
*        line_exists( accruals[  uuidinterest = <interest>-uuid type = '2' PostingDate ] )
        LOOP AT accruals INTO ls_accrual WHERE uuidinterest = <interest>-uuid
                                                  AND type = zzcl_fi_001=>accrualtype-monthlyaccrualofinterest
                                                   AND postingdate >= ls_calendardate-firstdayofmonthdate
                                                               AND postingdate <= ls_calendardate-lastdayofmonthdate.
          line_exists = abap_true.
          EXIT.
        ENDLOOP.

        IF line_exists = abap_true.
          ls_accrual_u = VALUE #(
              %tky = ls_accrual-%tky
                    amount = lv_monthlyinterestaccrual
                    currency = <interest>-currency
                    fiscalyear = lv_fiscalyear
                    postingdate = lv_postingdate
                    journalentrylender = lv_je_lender
                    journalentryborrower = lv_je_borrower
                    lender = <interest>-lender
                    borrower = <interest>-borrower
                    lendercompany = <interest>-lendercompany
                    borrowercompany = <interest>-borrowercompany
              %control = VALUE #(
                amount = if_abap_behv=>mk-on
                currency = if_abap_behv=>mk-on
                fiscalyear = if_abap_behv=>mk-on
*                        Type = if_abap_behv=>mk-on
                postingdate = if_abap_behv=>mk-on
                journalentrylender = if_abap_behv=>mk-on
                journalentryborrower = if_abap_behv=>mk-on
                lender = if_abap_behv=>mk-on
                borrower = if_abap_behv=>mk-on
                lendercompany = if_abap_behv=>mk-on
                borrowercompany = if_abap_behv=>mk-on
              )
          ).
          APPEND ls_accrual_u TO lt_accrual_u.
        ELSE.
          ls_accrual_c = VALUE #(

            %tky = <interest>-%tky
            %target = VALUE #(
               (
               %cid = <interest>-uuid
               %data = VALUE #(
                    amount = lv_monthlyinterestaccrual
                    currency = <interest>-currency
*                        CompanyCode =
                    fiscalyear = lv_fiscalyear
                    type = zzcl_fi_001=>type-monthlyaccrualofinterest
                    postingdate = lv_postingdate
                    journalentrylender = lv_je_lender
                    journalentryborrower = lv_je_borrower
                    lender = <interest>-lender
                    borrower = <interest>-borrower
                    lendercompany = <interest>-lendercompany
                    borrowercompany = <interest>-borrowercompany
               )
               %control = VALUE #(
                    amount = if_abap_behv=>mk-on
                    currency = if_abap_behv=>mk-on
                    fiscalyear = if_abap_behv=>mk-on
                    type = if_abap_behv=>mk-on
                    postingdate = if_abap_behv=>mk-on
                    journalentrylender = if_abap_behv=>mk-on
                    journalentryborrower = if_abap_behv=>mk-on
                    lender = if_abap_behv=>mk-on
                    borrower = if_abap_behv=>mk-on
                    lendercompany = if_abap_behv=>mk-on
                    borrowercompany = if_abap_behv=>mk-on
               )
               )
            )
          ).
          APPEND ls_accrual_c TO lt_accrual_c.


        ENDIF.

      ENDIF.

      "Process Message
      LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<msgitem>).
        APPEND VALUE #(
          %tky = <interest>-%tky
          %msg = new_message(
              id = <msgitem>-id
              number = <msgitem>-number
              severity = CONV if_abap_behv_message=>t_severity( <msgitem>-type )
              v1 = <msgitem>-message_v1
              v2 = <msgitem>-message_v2
              v3 = <msgitem>-message_v3
              v4 = <msgitem>-message_v4
           )
        ) TO reported-interest.
      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF zr_tfi001
      IN LOCAL MODE
          ENTITY accrual
            UPDATE FROM lt_accrual_u
          ENTITY interest
            CREATE BY \_accrual FROM lt_accrual_c
          REPORTED DATA(reported_n)
          MAPPED DATA(mapped_n)
          FAILED DATA(failed_n).
    reported = CORRESPONDING #( APPENDING ( reported ) reported_n ).
    mapped = CORRESPONDING #( APPENDING ( mapped ) mapped_n ).
    failed = CORRESPONDING #( APPENDING ( failed ) failed_n ).


  ENDMETHOD.
  METHOD precheck_delete.
    " 从自建表ZLoanPosting中查找Lender's Journal Entry或Borrower's Journal Entry是否有值）
    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
        ENTITY interest
        EXECUTE getloanpoststatus FROM
        CORRESPONDING #( keys )
        RESULT DATA(interests)
        FAILED failed.

    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
      IF <interest>-%param-lenderstatus = zzcl_fi_001=>poststatus-posted OR <interest>-%param-borrowerstatus = zzcl_fi_001=>poststatus-posted.
        APPEND VALUE #(
            %tky = <interest>-%tky
        ) TO failed-interest.

        APPEND VALUE #(
            %tky = <interest>-%tky
            %msg = new_message(
                id = 'ZZFI'
                number = '001'
                severity = if_abap_behv_message=>severity-error
            )
        ) TO reported-interest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD getdefaultsforrepayment.
    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
      ENTITY interest
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(interests).

    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
      APPEND VALUE #( %tky                          = <interest>-%tky
              %param-currency  = <interest>-currency ) TO result.

    ENDLOOP.
  ENDMETHOD.

  METHOD getdefaultsforcreate.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      APPEND VALUE #(
          %cid = <key>-%cid
          %param-exrates = zzcl_fi_001=>exrate
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

*  METHOD determinationforexchangerate.
*    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
*        ENTITY interest
*        ALL FIELDS WITH CORRESPONDING #( keys )
*        RESULT DATA(interests).
*
*    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
**        cl_exchange_rates=>
**        SELECT SINGLE exchangerate
**            FROM I_exchangerate
*      TRY.
*          cl_exchange_rates=>convert_to_local_currency(
*             EXPORTING
*                 date = <interest>-startdate
*                 foreign_amount = 1
*                 foreign_currency = <interest>-currency
*                 local_currency = 'EUR'
*                 rate_type = 'G'
*             IMPORTING
*                 exchange_rate = DATA(lv_rate)
*          ).
*          <interest>-exchangerate = lv_rate.
*
*        CATCH cx_exchange_rates INTO DATA(lx_rate).
**          <interest>-exchangerate = 0.
*          CONTINUE.
**          out->write( lx_rate->get_text(  ) ).
*          "handle exception
*      ENDTRY.
*    ENDLOOP.
*
*    MODIFY ENTITIES OF zr_tfi001
*        IN LOCAL MODE
*        ENTITY interest
*        UPDATE FIELDS ( exchangerate )
*        WITH CORRESPONDING #( interests ).
*
*  ENDMETHOD.

  METHOD determinationformaturitydate.
    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
        ENTITY interest
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(interests).
    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
      IF <interest>-loanmaturitydate IS INITIAL.
        DATA(lo_date) = xco_cp_time=>date(
          iv_year = <interest>-startdate(4)
          iv_month = <interest>-startdate+4(2)
          iv_day = <interest>-startdate+6(2)
       ).
        DATA(lo_end_date) = lo_date->add(
           iv_year = 5
           iv_month = 0
           iv_day = 0
           io_calculation = xco_cp_time=>date_calculation->ultimo
        ).
        DATA(lv_end_date) = lo_end_date->as( io_format = xco_cp_time=>format->abap  )->value.
        <interest>-loanmaturitydate = lv_end_date.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zr_tfi001
        IN LOCAL MODE
        ENTITY interest
        UPDATE FIELDS ( loanmaturitydate )
        WITH CORRESPONDING #( interests ).

  ENDMETHOD.





  METHOD copyloan.
    DATA: loans      TYPE TABLE FOR CREATE zr_tfi001\\interest.
*          repayments TYPE TABLE FOR CREATE zr_tfi001\\interest\_repayment.

    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
        ENTITY interest
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(lt_loans)
*        ENTITY interest BY \_repayment
*            ALL FIELDS WITH CORRESPONDING #( keys )
*            RESULT DATA(lt_repayments)
        FAILED failed.

    LOOP AT lt_loans ASSIGNING FIELD-SYMBOL(<loan>).
      APPEND CORRESPONDING #( <loan> CHANGING CONTROL EXCEPT contractcode uuid )
      TO loans ASSIGNING FIELD-SYMBOL(<new_loan>).
      <new_loan>-%cid = keys[ KEY id %tky = <loan>-%tky ]-%cid.

*      APPEND VALUE #( %cid_ref = keys[ KEY id %tky = <loan>-%tky ]-%cid )
*      TO repayments ASSIGNING FIELD-SYMBOL(<repayment_cba>).
*
*      LOOP AT lt_repayments ASSIGNING FIELD-SYMBOL(<repayment>) WHERE uuidinterest = <loan>-uuid
*                                                                  AND %is_draft = <loan>-%is_draft.
*        APPEND CORRESPONDING #( <repayment> CHANGING CONTROL EXCEPT uuid uuidinterest )
*       TO <repayment_cba>-%target ASSIGNING FIELD-SYMBOL(<new_repayment>).
*        <new_repayment>-%cid = keys[ KEY id %tky = <loan>-%tky ]-%cid && <repayment>-uuid.
*
*      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF zr_tfi001 IN LOCAL MODE
        ENTITY interest CREATE FROM loans
*                        CREATE BY \_repayment FROM repayments
      MAPPED mapped
      FAILED failed
      REPORTED reported.

  ENDMETHOD.

  METHOD determinationforcompanycode.
    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
    ENTITY interest
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(interests).

    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
      SELECT SINGLE companycode
          FROM i_companycode WITH PRIVILEGED ACCESS
          WHERE company = @<interest>-lendercompany
            INTO @<interest>-lender.

      SELECT SINGLE companycode
          FROM i_companycode WITH PRIVILEGED ACCESS
          WHERE company = @<interest>-borrowercompany
            INTO @<interest>-borrower.

    ENDLOOP.

    MODIFY ENTITIES OF zr_tfi001
        IN LOCAL MODE
        ENTITY interest
        UPDATE FIELDS ( lender borrower )
        WITH CORRESPONDING #( interests ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
*    requested_authorizations-
    READ ENTITIES OF zr_tfi001
        IN LOCAL MODE
            ENTITY interest ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(loans).

    DATA: update_requested               TYPE abap_boolean,
          delete_requested               TYPE abap_boolean,
*          edit_requested                TYPE abap_boolean,
          copy_requested                 TYPE abap_boolean,
          postingofinitialprincipal_req  TYPE abap_boolean,
          postingofmonthlyaccrualint_req TYPE abap_boolean.


*    requested_authorizations-%action-PostingOfMonthlyAccrualInt
    update_requested = COND #( WHEN requested_authorizations-%update                = if_abap_behv=>mk-on OR
                                    requested_authorizations-%action-edit           = if_abap_behv=>mk-on
                               THEN abap_true ELSE abap_false ).

    delete_requested = COND #( WHEN requested_authorizations-%delete                = if_abap_behv=>mk-on
                               THEN abap_true ELSE abap_false ).

    copy_requested = COND #( WHEN requested_authorizations-%action-copyloan                = if_abap_behv=>mk-on
                               THEN abap_true ELSE abap_false ).

    postingofinitialprincipal_req = COND #( WHEN requested_authorizations-%action-postingofinitialprincipal                = if_abap_behv=>mk-on
                                   THEN abap_true ELSE abap_false ).

    postingofmonthlyaccrualint_req = COND #( WHEN requested_authorizations-%action-postingofmonthlyaccrualint                = if_abap_behv=>mk-on
                                       THEN abap_true ELSE abap_false ).

    LOOP AT loans ASSIGNING FIELD-SYMBOL(<loan>).
      APPEND VALUE #(
        %tky = <loan>-%tky
      ) TO result ASSIGNING FIELD-SYMBOL(<loan_auth>).
      IF postingofinitialprincipal_req = abap_true.
        AUTHORITY-CHECK OBJECT 'ZZAOFI002'
        ID 'ZZAFFI002' FIELD <loan>-lendercompany
        ID 'ZZAFFI003' FIELD <loan>-borrowercompany
        ID 'ZZAFFI001' FIELD '1'
        ID 'ACTVT' FIELD '10'.
        IF sy-subrc NE 0.
          <loan_auth>-%action-postingofinitialprincipal = if_abap_behv=>auth-unauthorized.
        ELSE.
          <loan_auth>-%action-postingofinitialprincipal = if_abap_behv=>auth-allowed.
        ENDIF.
      ENDIF.

      IF postingofmonthlyaccrualint_req = abap_true.
        AUTHORITY-CHECK OBJECT 'ZZAOFI002'
        ID 'ZZAFFI002' FIELD <loan>-lendercompany
        ID 'ZZAFFI003' FIELD <loan>-borrowercompany
        ID 'ZZAFFI001' FIELD '2'
        ID 'ACTVT' FIELD '10'.
        IF sy-subrc NE 0.
          <loan_auth>-%action-postingofmonthlyaccrualint = if_abap_behv=>auth-unauthorized.
        ELSE.
          <loan_auth>-%action-postingofmonthlyaccrualint = if_abap_behv=>auth-allowed.
        ENDIF.
      ENDIF.

      IF update_requested = abap_true .
        AUTHORITY-CHECK OBJECT 'ZZAOFI002'
        ID 'ZZAFFI002' FIELD <loan>-lendercompany
        ID 'ZZAFFI003' FIELD <loan>-borrowercompany
*        ID 'ZZAFFI001' FIELD '6'
        ID 'ZZAFFI001' DUMMY
        ID 'ACTVT' FIELD '02'.
        IF sy-subrc NE 0.
          <loan_auth>-%action-edit = if_abap_behv=>auth-unauthorized.
          <loan_auth>-%update = if_abap_behv=>auth-unauthorized.
        ELSE.
          <loan_auth>-%action-edit = if_abap_behv=>auth-allowed.
          <loan_auth>-%update = if_abap_behv=>auth-allowed.
        ENDIF.
      ENDIF.

      IF delete_requested = abap_true.
        AUTHORITY-CHECK OBJECT 'ZZAOFI002'
        ID 'ZZAFFI002' FIELD <loan>-lendercompany
        ID 'ZZAFFI003' FIELD <loan>-borrowercompany
        ID 'ZZAFFI001' DUMMY
        ID 'ACTVT'  FIELD  '06'.
        IF sy-subrc NE 0.
          <loan_auth>-%delete = if_abap_behv=>auth-unauthorized.
        ELSE.
          <loan_auth>-%delete = if_abap_behv=>auth-allowed.
        ENDIF.
      ENDIF.

      IF copy_requested = abap_true.
        AUTHORITY-CHECK OBJECT 'ZZAOFI002'
        ID 'ZZAFFI002' FIELD <loan>-lendercompany
        ID 'ZZAFFI003' FIELD <loan>-borrowercompany
        ID 'ZZAFFI001' FIELD '8'
        ID 'ACTVT' FIELD '90'.
        IF sy-subrc NE 0.
          <loan_auth>-%action-copyloan = if_abap_behv=>auth-unauthorized.
        ELSE.
          <loan_auth>-%action-copyloan = if_abap_behv=>auth-allowed.
        ENDIF.
      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD determinationforexrate.
    READ ENTITIES OF zr_tfi001 IN LOCAL MODE
        ENTITY interest
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(interests).
    LOOP AT interests ASSIGNING FIELD-SYMBOL(<interest>).
      IF <interest>-contracttype = zzcl_fi_001=>contracttype-interest_free_loan.
        <interest>-exrates = 0.
      ELSE.
        <interest>-exrates = zzcl_fi_001=>exrate.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF zr_tfi001
        IN LOCAL MODE
        ENTITY interest
        UPDATE FIELDS ( exrates )
        WITH CORRESPONDING #( interests ).

  ENDMETHOD.

ENDCLASS.
