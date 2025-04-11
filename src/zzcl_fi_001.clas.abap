CLASS zzcl_fi_001 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .
  PUBLIC SECTION.
    INTERFACES: if_irm_destruction_object_exec.
    TYPES : tt_accruals_asso TYPE TABLE FOR READ RESULT zr_tfi001\\interest\_accrual,
            t_interest       TYPE STRUCTURE FOR READ RESULT zr_tfi001\\interest,
            t_repayment      TYPE STRUCTURE FOR READ RESULT zr_tfi001\\repayment.
    CLASS-METHODS:
      processpayloadofjournalentry
        IMPORTING
                  simulate          TYPE abap_boolean DEFAULT abap_false
                  interest          TYPE zr_tfi001 OPTIONAL
                  repayment         TYPE zr_tfi002 OPTIONAL
                  lenderstatus      TYPE zzefi035
                  borrowerstatus    TYPE zzefi035
                  type              TYPE zzefi036
                  inputparams       TYPE zr_sfi016
        RETURNING VALUE(es_payload) TYPE zjournal_entry_bulk_create_req,
      getaccountconfig
        IMPORTING
*        Interest         TYPE zr_tfi001
                  type             TYPE zzefi020
                  lenderorborrower TYPE zzefi033
                  currency         TYPE waers
                  cashflow         TYPE zzefi999
        RETURNING VALUE(es_fi004)  TYPE zr_tfi004,
      processjournalentryitems
        IMPORTING
          companycode      TYPE bukrs
          o_companycode    TYPE bukrs
          o_company        TYPE rcomp_d
*          interest           TYPE zr_tfi001
          currency         TYPE waers
          amount           TYPE zzefi008
          cashflow         TYPE zzefi999
          type             TYPE zzefi036
          lenderorborrower TYPE zzefi033
          housebank        TYPE zzefi023
          accountid        TYPE zzefi024
          contractcode     TYPE zzefi002
          headertext       TYPE string
        EXPORTING
          et_item          TYPE zjournal_entry_create_req_tab3
          et_debitor       TYPE zjournal_entry_create_req_tab4
          et_creditor      TYPE zjournal_entry_create_req_tab5,

      getjournalentryitem
        IMPORTING
          companycode      TYPE bukrs
          o_companycode    TYPE bukrs
          o_company        TYPE rcomp_d
          currency         TYPE waers
          amount           TYPE zzefi008
          glaccount        TYPE hkont
          reasoncode       TYPE zzefi032
          type             TYPE zzefi036
          lenderorborrower TYPE zzefi033
          debitor_creditor TYPE shkzg
          housebank        TYPE zzefi023
          accountid        TYPE zzefi024
          contractcode     TYPE zzefi002
          headertext       TYPE string
        EXPORTING
          es_item          TYPE zjournal_entry_create_request9
          es_debitor       TYPE zjournal_entry_create_reques13
          es_creditor      TYPE zjournal_entry_create_reques16,

      createjournalentrydoc
        IMPORTING
          interest       TYPE t_interest OPTIONAL
          repayment      TYPE t_repayment OPTIONAL
          accruals       TYPE tt_accruals_asso OPTIONAL

          lenderstatus   TYPE zzefi035
          borrowerstatus TYPE zzefi035
          type           TYPE zzefi036
          inputparams    TYPE zr_sfi016
        EXPORTING
          ev_je_lender   TYPE belnr_d
          ev_je_borrower TYPE belnr_d
          ev_fiscalyear  TYPE gjahr
          et_message     TYPE bapirettab,

      simulatejournalentrydoc
        IMPORTING
          interest       TYPE t_interest OPTIONAL
          repayment      TYPE t_repayment OPTIONAL
          accruals       TYPE tt_accruals_asso OPTIONAL

          lenderstatus   TYPE zzefi035
          borrowerstatus TYPE zzefi035
          type           TYPE zzefi036
          inputparams    TYPE zr_sfi016
        EXPORTING
*          ev_je_lender   TYPE belnr_d
*          ev_je_borrower TYPE belnr_d
*          ev_fiscalyear  TYPE gjahr
          et_message     TYPE bapirettab,
      convertlogtobapimsg
        IMPORTING
                  log        TYPE zlog_item
        RETURNING VALUE(msg) TYPE bapiret2,
      convertcurrencytoexternal
        IMPORTING amount            TYPE wrbtr
                  currency          TYPE waers
        RETURNING VALUE(amount_out) TYPE decfloat34.

    CONSTANTS : BEGIN OF poststatus,
                  posted     TYPE c VALUE '1',
                  notposted  TYPE c VALUE '2',
                  cannotpost TYPE c VALUE '3',
                END OF poststatus,
                BEGIN OF type,
                  postingofinitialprincipal  TYPE zzefi020 VALUE '1',
                  monthlyaccrualofinterest   TYPE zzefi020 VALUE '2',
                  postingofrepaymentbalance  TYPE zzefi020 VALUE '3',
                  postingofrepaymentinterest TYPE zzefi020 VALUE '4',
                END OF type,
                BEGIN OF repaymenttype,
                  balance  TYPE zzefi018 VALUE '1',
                  interest TYPE zzefi018 VALUE '2',
                END OF repaymenttype,
                BEGIN OF accrualtype,
                  postingofinitialprincipal TYPE zzefi020 VALUE '1',
                  monthlyaccrualofinterest  TYPE zzefi020 VALUE '2',
                END OF accrualtype,
                BEGIN OF poststatuscriticality,
                  reversed TYPE i VALUE 1,
                  posted   TYPE i VALUE 3,
                  empty    TYPE i VALUE 0,
                END OF poststatuscriticality,
                BEGIN OF lenderorborrower,
                  lender   TYPE zzefi033 VALUE '1',
                  borrower TYPE zzefi033 VALUE '2',
                END OF  lenderorborrower,
                BEGIN OF contracttype,
                  interest_free_loan    TYPE zzefi001 VALUE '1',
                  interest_bearing_loan TYPE zzefi001 VALUE '2',
                END OF contracttype,
                exrate TYPE zzefi013 VALUE '0.065'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zzcl_fi_001 IMPLEMENTATION.


  METHOD convertlogtobapimsg.
    msg =
      VALUE #(
                              type = SWITCH #( log-severity_code
                                  WHEN '1' THEN if_abap_behv_message=>severity-success
                                  WHEN '2' THEN if_abap_behv_message=>severity-warning
                                  WHEN '3' THEN if_abap_behv_message=>severity-error
                              )
                  id = 'ZZFI'
                  number = 003
*                  message_v1 = log-note(50)
*                  message_v2 = SWITCH #(
*                    strlen( log-note )
*                    when > 50
*                   )
                ).
    DATA(length) = strlen( log-note ).

    IF length <= 50.
      msg-message_v1 = log-note(length).
    ELSEIF length > 50 AND length <= 100.
      DATA(length_v2) = length - 50.
      msg-message_v1 = log-note(50).
      msg-message_v2 = log-note+50(length_v2).
    ELSEIF length > 100 AND length <= 150.
      DATA(length_v3) = length - 100.
      msg-message_v1 = log-note(50).
      msg-message_v2 = log-note+50(50).
      msg-message_v3 = log-note+100(length_v3).
    ELSE.
      DATA(length_v4) = length - 150.
      msg-message_v1 = log-note(50).
      msg-message_v2 = log-note+50(50).
      msg-message_v3 = log-note+100(50).
      msg-message_v4 = log-note+150(length_v4).
    ENDIF.
  ENDMETHOD.


  METHOD createjournalentrydoc.
    "Get existing posted journal entry
    IF inputparams-postingdate < interest-startdate.
      APPEND VALUE #(
        type = 'E'
        id = 'ZZFI'
        number = 014
       ) TO et_message.
      RETURN.
    ENDIF.


    simulatejournalentrydoc(
      EXPORTING
          type = type
          interest = interest
          accruals = accruals
          repayment = repayment
          inputparams = inputparams
          lenderstatus = lenderstatus
          borrowerstatus = borrowerstatus
      IMPORTING
*            ev_fiscalyear = lv_fiscalyear
*            ev_je_lender = lv_je_lender
*            ev_je_borrower = lv_je_borrower
          et_message = et_message
    ).
    IF line_exists( et_message[ type = if_abap_behv_message=>severity-error ] ).
      RETURN.
    ELSE.
      CLEAR et_message.
    ENDIF.

    IF type = zzcl_fi_001=>type-monthlyaccrualofinterest.
      SELECT SINGLE
        firstdayofmonthdate,
        lastdayofmonthdate
        FROM i_calendardate WITH PRIVILEGED ACCESS
      WHERE calendardate = @inputparams-postingdate
        INTO @DATA(ls_calendardate).
    ENDIF.


    IF lenderstatus = zzcl_fi_001=>poststatus-posted.
      CASE type.
        WHEN zzcl_fi_001=>type-postingofinitialprincipal.
          ev_je_lender = accruals[  uuidinterest = interest-uuid type = zzcl_fi_001=>accrualtype-postingofinitialprincipal ]-journalentrylender.
          ev_fiscalyear = accruals[  uuidinterest = interest-uuid type = zzcl_fi_001=>accrualtype-postingofinitialprincipal ]-fiscalyear.
        WHEN zzcl_fi_001=>type-monthlyaccrualofinterest.
*          ev_je_lender = accruals[  uuidinterest = interest-uuid type = '2' postingdate >= ls_calendardate-firstdayofmonthdate  ]-journalentrylender.
          LOOP AT accruals ASSIGNING FIELD-SYMBOL(<accrual>) WHERE uuidinterest = interest-uuid
                                                               AND type = zzcl_fi_001=>accrualtype-monthlyaccrualofinterest
                                                               AND postingdate >= ls_calendardate-firstdayofmonthdate
                                                               AND postingdate <= ls_calendardate-lastdayofmonthdate.
            ev_je_lender = <accrual>-journalentrylender.
            ev_fiscalyear = <accrual>-fiscalyear.
          ENDLOOP.

        WHEN zzcl_fi_001=>type-postingofrepaymentbalance OR zzcl_fi_001=>type-postingofrepaymentinterest.
          ev_je_lender = repayment-journalentrylender.
          ev_fiscalyear = repayment-fiscalyear.
      ENDCASE.

    ENDIF.

    IF borrowerstatus = zzcl_fi_001=>poststatus-posted.
      CASE type.
        WHEN zzcl_fi_001=>type-postingofinitialprincipal.
          ev_je_borrower = accruals[  uuidinterest = interest-uuid type = zzcl_fi_001=>accrualtype-postingofinitialprincipal ]-journalentryborrower.
          ev_fiscalyear = accruals[  uuidinterest = interest-uuid type = zzcl_fi_001=>accrualtype-postingofinitialprincipal ]-fiscalyear.
        WHEN zzcl_fi_001=>type-monthlyaccrualofinterest.
*          ev_je_borrower = accruals[  uuidinterest = interest-uuid type = '2' ]-journalentryborrower.
          LOOP AT accruals ASSIGNING <accrual> WHERE uuidinterest = interest-uuid
                                                               AND type = zzcl_fi_001=>accrualtype-monthlyaccrualofinterest
                                                               AND postingdate >= ls_calendardate-firstdayofmonthdate
                                                               AND postingdate <= ls_calendardate-lastdayofmonthdate.
            ev_je_borrower = <accrual>-journalentryborrower.
            ev_fiscalyear = <accrual>-fiscalyear.
          ENDLOOP.
        WHEN zzcl_fi_001=>type-postingofrepaymentbalance OR zzcl_fi_001=>type-postingofrepaymentinterest.
          ev_je_borrower = repayment-journalentryborrower.
          ev_fiscalyear = repayment-fiscalyear.
      ENDCASE.
    ENDIF.


    "Post Journal Entries - Post Lender/Borrower journal entry that is not posted
    TRY.

        DATA(destination) = cl_soap_destination_provider=>create_by_comm_arrangement(
               comm_scenario  = 'ZZCS_FI_001'
               service_id     = 'ZZOS_FI_001_SPRX'
               comm_system_id = 'SELF'
          ).



        DATA(proxy) = NEW zco_journal_entry_create_reque( destination = destination ).

        " fill request
        DATA(request) = zzcl_fi_001=>processpayloadofjournalentry(
                          type = type
                          interest = interest-%data
                          repayment = repayment-%data
                          inputparams = inputparams
                          lenderstatus = lenderstatus
                          borrowerstatus = borrowerstatus
                        ).
        proxy->journal_entry_create_request_c(
          EXPORTING
            input = request
          IMPORTING
            output = DATA(response)
        ).

        " Process response
        IF lines( response-journal_entry_bulk_create_conf-journal_entry_create_confirmat ) > 0.
          LOOP AT response-journal_entry_bulk_create_conf-journal_entry_create_confirmat ASSIGNING FIELD-SYMBOL(<fs_je>).
            IF <fs_je>-journal_entry_create_confirmat-accounting_document <> '0000000000'.
              IF <fs_je>-journal_entry_create_confirmat-company_code = interest-lender.
                ev_je_lender = <fs_je>-journal_entry_create_confirmat-accounting_document.
              ELSE.
                ev_je_borrower = <fs_je>-journal_entry_create_confirmat-accounting_document.
              ENDIF.
              ev_fiscalyear = <fs_je>-journal_entry_create_confirmat-fiscal_year.
            ENDIF.
            "Process Message
            LOOP AT <fs_je>-log-item ASSIGNING FIELD-SYMBOL(<msgitem>).
              APPEND convertlogtobapimsg( log = <msgitem> ) TO et_message.
**              APPEND VALUE #(
**                            type = SWITCH #( <msgitem>-severity_code
**                                WHEN '1' THEN if_abap_behv_message=>severity-success
**                                WHEN '2' THEN if_abap_behv_message=>severity-warning
**                                WHEN '3' THEN if_abap_behv_message=>severity-error
**                            )
**                id = 'SABP_BEHV'
**                number = 100
**                message_v1 = <msgitem>-note
**              ) TO et_message.
            ENDLOOP.
          ENDLOOP.
        ENDIF.

      CATCH cx_soap_destination_error cx_ai_system_fault INTO DATA(lx_system).
*        APPEND VALUE #(
*          %tky = <interest>-%tky
*        ) TO failed-interest.
*        APPEND VALUE #(
*          %tky = <interest>-%tky
*          %msg = new_message_with_text(
*              severity = if_abap_behv_message=>severity-error
*              text = lx_system->get_text(  )
*          )
*          %action-postingofinitialprincipal = if_abap_behv=>mk-on
*        ) TO reported-interest.
        APPEND convertlogtobapimsg( log = VALUE #(
            severity_code = '3'
            note = lx_system->get_text(  )
            )
        ) TO et_message.
*        APPEND VALUE #(
*            type = if_abap_behv_message=>severity-error
*            id = 'SABP_BEHV'
*            number = 100
*            message_v1 = lx_system->get_text(  )
*        ) TO et_message.



        " handle error
    ENDTRY.
  ENDMETHOD.


  METHOD getaccountconfig.

    IF type = zzcl_fi_001=>type-monthlyaccrualofinterest.
      SELECT SINGLE * FROM
      zr_tfi004 WITH PRIVILEGED ACCESS
      WHERE type = @type
        AND bolen = @lenderorborrower
*        AND cashflow = @
*        AND currency = @currency
     INTO @es_fi004.
    ELSE.
      IF cashflow = abap_true.
        SELECT SINGLE * FROM
            zr_tfi004 WITH PRIVILEGED ACCESS
            WHERE type = @type
              AND bolen = @lenderorborrower
              AND cashflow = @abap_true
              AND currency = @currency
           INTO @es_fi004.

      ELSE.
        SELECT SINGLE * FROM
            zr_tfi004 WITH PRIVILEGED ACCESS
            WHERE type = @type
              AND bolen = @lenderorborrower
              AND cashflow = @abap_false
*            AND Currency = @interest-Currency
           INTO @es_fi004.
      ENDIF.
    ENDIF.


  ENDMETHOD.


  METHOD getjournalentryitem.
    "目前逻辑未使用
    "Type
    "Lender or Borrower


    SELECT SINGLE reconciliationaccounttype
       FROM i_glaccount WITH PRIVILEGED ACCESS
       WHERE companycode = @companycode
       AND glaccount = @glaccount
       INTO @DATA(lv_gl_type).

*    CASE type.
*      WHEN '1'.
    CASE lv_gl_type.
      WHEN 'S' OR space.
        es_item = VALUE #(
            glaccount = VALUE #(
                content = glaccount
            )
            value_date = cl_abap_context_info=>get_system_date(  )
            debit_credit_code = debitor_creditor
            house_bank = SWITCH #( type WHEN zzcl_fi_001=>type-monthlyaccrualofinterest THEN '' ELSE housebank )
            house_bank_account = SWITCH #( type WHEN zzcl_fi_001=>type-monthlyaccrualofinterest THEN '' ELSE accountid )
            account_assignment = VALUE #(
                profit_center = | { companycode }10|
             )
            amount_in_transaction_currency = VALUE #(
                currency_code = currency
                content = SWITCH #( debitor_creditor
                    WHEN 'S' THEN convertcurrencytoexternal( amount = amount currency = currency )
                    ELSE 0 - convertcurrencytoexternal( amount = amount currency = currency )
                )
             )
*             reason_code = reasoncode
             financial_transaction_type = reasoncode
             assignment_reference = contractcode
             document_item_text = headertext
        ).
*            APPEND ls_item TO et_item.
      WHEN 'K'.
        SELECT SINGLE supplier
         FROM i_supplier WITH PRIVILEGED ACCESS
              JOIN i_globalcompany WITH PRIVILEGED ACCESS ON i_globalcompany~company = i_supplier~tradingpartner
              WHERE i_globalcompany~company = @o_company
*            JOIN i_companycode WITH PRIVILEGED ACCESS ON i_companycode~company = i_supplier~tradingpartner
*         WHERE i_companycode~companycode = @o_companycode
         INTO @DATA(lv_supplier).

        es_creditor = VALUE #(
          reference_document_item = SWITCH #(  debitor_creditor
                                                WHEN 'S' THEN '1'
                                                ELSE '2'  )
          creditor = lv_supplier
          altv_recncln_accts = VALUE #(
            content = glaccount
          )
          debit_credit_code = debitor_creditor
          amount_in_transaction_currency = VALUE #(
                currency_code = currency
                content = SWITCH #( debitor_creditor
                    WHEN 'S' THEN convertcurrencytoexternal( amount = amount currency = currency )
                    ELSE 0 - convertcurrencytoexternal( amount = amount currency = currency )
                )
          )
          assignment_reference = contractcode
          document_item_text = headertext
        ).
*            APPEND ls_creditor_item TO et_creditor.
      WHEN 'D'.
        SELECT SINGLE customer
            FROM i_customer WITH PRIVILEGED ACCESS
              JOIN i_globalcompany WITH PRIVILEGED ACCESS ON i_globalcompany~company = i_customer~tradingpartner
              WHERE i_globalcompany~company = @o_company
*                JOIN i_companycode WITH PRIVILEGED ACCESS ON i_companycode~company = i_customer~tradingpartner
*                WHERE i_companycode~companycode = @o_companycode
                INTO @DATA(lv_customer).
        es_debitor = VALUE #(
          reference_document_item = SWITCH #(  debitor_creditor
                                                WHEN 'S' THEN '1'
                                                ELSE '2'  )
            debtor = lv_customer
                          altv_recncln_accts = VALUE #(
            content = glaccount
          )
          debit_credit_code = debitor_creditor
          amount_in_transaction_currency = VALUE #(
                currency_code = currency
                content = SWITCH #( debitor_creditor
                    WHEN 'S' THEN convertcurrencytoexternal( amount = amount currency = currency )
                    ELSE 0 - convertcurrencytoexternal( amount = amount currency = currency )
                )
          )
          assignment_reference = contractcode
          document_item_text = headertext
        ).

    ENDCASE.

*    ENDCASE.
  ENDMETHOD.


  METHOD if_irm_destruction_object_exec~execute.

  ENDMETHOD.


  METHOD processjournalentryitems.
    DATA : ls_item          TYPE zjournal_entry_create_request9,
           ls_debitor_item  TYPE zjournal_entry_create_reques13,
           ls_creditor_item TYPE zjournal_entry_create_reques16.


    "获取配置
    DATA(ls_config) = getaccountconfig(
*        interest = interest
        type = type
        lenderorborrower = lenderorborrower
        cashflow = cashflow
        currency = currency
     ).
    "
    getjournalentryitem(
       EXPORTING
        companycode = companycode
        o_companycode = o_companycode
        o_company = o_company
        amount = amount
        currency = currency
        glaccount = ls_config-debit
        reasoncode = ls_config-cashflowcode
        type = type
        lenderorborrower = lenderorborrower
        debitor_creditor = 'S'
        housebank = housebank
        accountid = accountid
        contractcode = contractcode
        headertext = headertext
       IMPORTING
        es_item = ls_item
        es_creditor = ls_creditor_item
        es_debitor = ls_debitor_item
     ).
    IF ls_item IS NOT INITIAL.
      APPEND ls_item TO et_item.
    ENDIF.
    IF ls_creditor_item IS NOT INITIAL.
      APPEND ls_creditor_item TO et_creditor.
    ENDIF.
    IF ls_debitor_item IS NOT INITIAL.
      APPEND ls_debitor_item TO et_debitor.
    ENDIF.


    CLEAR : ls_item,
            ls_creditor_item,
            ls_debitor_item.
    getjournalentryitem(
       EXPORTING
        companycode = companycode
        o_companycode = o_companycode
        o_company = o_company
        amount = amount
        currency = currency
        glaccount = ls_config-credit
        reasoncode = ls_config-cashflowcode
        type = type
        lenderorborrower = lenderorborrower
        debitor_creditor = 'H'
        housebank = housebank
        accountid = accountid
        contractcode = contractcode
        headertext = headertext
       IMPORTING
        es_item = ls_item
        es_creditor = ls_creditor_item
        es_debitor = ls_debitor_item
     ).
    IF ls_item IS NOT INITIAL.
      APPEND ls_item TO et_item.
    ENDIF.
    IF ls_creditor_item IS NOT INITIAL.
      APPEND ls_creditor_item TO et_creditor.
    ENDIF.
    IF ls_debitor_item IS NOT INITIAL.
      APPEND ls_debitor_item TO et_debitor.
    ENDIF.




  ENDMETHOD.


  METHOD processpayloadofjournalentry.
    DATA : ls_journal_entry TYPE zjournal_entry_create_reques18.

    IF type = zzcl_fi_001=>type-monthlyaccrualofinterest.
      SELECT SINGLE monthlyinterestaccrual
          FROM zr_sfi008( p_date = @inputparams-postingdate )
          WHERE uuid = @interest-uuid
          INTO @DATA(lv_monthlyinterestaccrual).
    ENDIF.

    GET TIME STAMP FIELD es_payload-journal_entry_bulk_create_requ-message_header-creation_date_time.
    " Lender
    IF lenderstatus = zzcl_fi_001=>poststatus-notposted AND interest-lender <> space.
      ls_journal_entry = VALUE #(
          original_reference_document_ty = 'BKPFF'
          business_transaction_type = 'RFBU'
          accounting_document_type = 'SA'
          created_by_user = cl_abap_context_info=>get_user_technical_name(  )
          company_code = interest-lender
          document_date = cl_abap_context_info=>get_system_date(  )
          posting_date = inputparams-postingdate
          document_header_text = SWITCH #( type
              WHEN zzcl_fi_001=>type-postingofinitialprincipal THEN |No.{ interest-contractcode } ICL Prin|
              WHEN zzcl_fi_001=>type-monthlyaccrualofinterest THEN |No.{ interest-contractcode } ICL { inputparams-postingdate+4(2) }/{ inputparams-postingdate+2(2) }int.|
              WHEN zzcl_fi_001=>type-postingofrepaymentbalance THEN |No.{ interest-contractcode } ICL PrinRepay|
              WHEN zzcl_fi_001=>type-postingofrepaymentinterest THEN |No.{ interest-contractcode } ICL int.Repay|
          )
      ).

      processjournalentryitems(
          EXPORTING
              companycode = interest-lender
              o_companycode = interest-borrower
              o_company = interest-borrowercompany
              lenderorborrower = zzcl_fi_001=>lenderorborrower-lender
              type = type
              amount = SWITCH #( type
                        WHEN zzcl_fi_001=>type-postingofinitialprincipal THEN interest-initialprincipal
                        WHEN zzcl_fi_001=>type-monthlyaccrualofinterest THEN lv_monthlyinterestaccrual
                        WHEN zzcl_fi_001=>type-postingofrepaymentbalance THEN repayment-repaymentamount
                        WHEN zzcl_fi_001=>type-postingofrepaymentinterest THEN repayment-repaymentamount
              )
              currency = interest-currency
*              cashflow = interest-cashflow
*              housebank = interest-housebanklender
*              accountid = interest-accountidlender
              cashflow = SWITCH #( type
                WHEN zzcl_fi_001=>type-postingofinitialprincipal  OR zzcl_fi_001=>type-monthlyaccrualofinterest THEN interest-cashflowlender
                WHEN zzcl_fi_001=>type-postingofrepaymentbalance OR zzcl_fi_001=>type-postingofrepaymentinterest THEN repayment-cashflowlender
              )
              housebank = SWITCH #( type
                WHEN zzcl_fi_001=>type-postingofinitialprincipal  OR zzcl_fi_001=>type-monthlyaccrualofinterest THEN interest-housebanklender
                WHEN zzcl_fi_001=>type-postingofrepaymentbalance OR zzcl_fi_001=>type-postingofrepaymentinterest THEN repayment-housebanklender
              )
              accountid = SWITCH #( type
                WHEN zzcl_fi_001=>type-postingofinitialprincipal  OR zzcl_fi_001=>type-monthlyaccrualofinterest THEN interest-accountidlender
                WHEN zzcl_fi_001=>type-postingofrepaymentbalance OR zzcl_fi_001=>type-postingofrepaymentinterest THEN repayment-accountidlender
              )
              contractcode = interest-contractcode
              headertext = CONV string( ls_journal_entry-document_header_text )
          IMPORTING
              et_item = ls_journal_entry-item
              et_creditor = ls_journal_entry-creditor_item
              et_debitor = ls_journal_entry-debtor_item
       ).

      APPEND VALUE #(
          message_header = VALUE #(
              creation_date_time = es_payload-journal_entry_bulk_create_requ-message_header-creation_date_time
          )
          journal_entry  = ls_journal_entry

       ) TO es_payload-journal_entry_bulk_create_requ-journal_entry_create_request.
    ENDIF.

    IF borrowerstatus = zzcl_fi_001=>poststatus-notposted AND interest-borrower <> space.
      "Borrower
      CLEAR ls_journal_entry.

      ls_journal_entry = VALUE #(
          original_reference_document_ty = 'BKPFF'
          business_transaction_type = 'RFBU'
          accounting_document_type = 'SA'
          created_by_user = cl_abap_context_info=>get_user_technical_name(  )
          company_code = interest-borrower
          document_date = cl_abap_context_info=>get_system_date(  )
          posting_date = inputparams-postingdate
          document_header_text = SWITCH #( type
              WHEN zzcl_fi_001=>type-postingofinitialprincipal THEN |No.{ interest-contractcode } ICL Prin|
              WHEN zzcl_fi_001=>type-monthlyaccrualofinterest THEN |No.{ interest-contractcode } ICL { inputparams-postingdate+4(2) }/{ inputparams-postingdate+2(2) }int.|
              WHEN zzcl_fi_001=>type-postingofrepaymentbalance THEN |No.{ interest-contractcode } ICL PrinRepay|
              WHEN zzcl_fi_001=>type-postingofrepaymentinterest THEN |No.{ interest-contractcode } ICL int.Repay|
          )
      ).

      processjournalentryitems(
          EXPORTING
              companycode = interest-borrower
              o_companycode = interest-lender
              o_company = interest-lendercompany
              lenderorborrower = zzcl_fi_001=>lenderorborrower-borrower
              type = type
              amount = SWITCH #( type
                        WHEN zzcl_fi_001=>type-postingofinitialprincipal THEN interest-initialprincipal
                        WHEN zzcl_fi_001=>type-monthlyaccrualofinterest THEN lv_monthlyinterestaccrual
                        WHEN zzcl_fi_001=>type-postingofrepaymentbalance THEN repayment-repaymentamount
                        WHEN zzcl_fi_001=>type-postingofrepaymentinterest THEN repayment-repaymentamount
                    )
              currency = interest-currency
              cashflow = SWITCH #( type
                WHEN zzcl_fi_001=>type-postingofinitialprincipal  OR zzcl_fi_001=>type-monthlyaccrualofinterest THEN interest-cashflowborrower
                WHEN zzcl_fi_001=>type-postingofrepaymentbalance OR zzcl_fi_001=>type-postingofrepaymentinterest THEN repayment-cashflowborrower
              )
              housebank = SWITCH #( type
                WHEN zzcl_fi_001=>type-postingofinitialprincipal  OR zzcl_fi_001=>type-monthlyaccrualofinterest THEN interest-housebankborrower
                WHEN zzcl_fi_001=>type-postingofrepaymentbalance OR zzcl_fi_001=>type-postingofrepaymentinterest THEN repayment-housebankborrower
              )
              accountid = SWITCH #( type
                WHEN zzcl_fi_001=>type-postingofinitialprincipal  OR zzcl_fi_001=>type-monthlyaccrualofinterest THEN interest-accountidborrower
                WHEN zzcl_fi_001=>type-postingofrepaymentbalance OR zzcl_fi_001=>type-postingofrepaymentinterest THEN repayment-accountidborrower
              )
*              cashflow = interest-cashflow
*              housebank = interest-housebankborrower
*              accountid = interest-accountidborro wer
              contractcode = interest-contractcode
              headertext = CONV string( ls_journal_entry-document_header_text )
          IMPORTING
              et_item = ls_journal_entry-item
              et_creditor = ls_journal_entry-creditor_item
              et_debitor = ls_journal_entry-debtor_item
       ).

      APPEND VALUE #(
          message_header = VALUE #(
              creation_date_time = es_payload-journal_entry_bulk_create_requ-message_header-creation_date_time
          )
          journal_entry  = ls_journal_entry

       ) TO es_payload-journal_entry_bulk_create_requ-journal_entry_create_request.

    ENDIF.
    IF simulate = abap_true.
      es_payload-journal_entry_bulk_create_requ-message_header-test_data_indicator = 'X'.
    ENDIF.

  ENDMETHOD.


  METHOD simulatejournalentrydoc.
*    IF lenderstatus = '1'.
*      CASE type.
*        WHEN '1'.
*          ev_je_lender = accruals[  UUIDInterest = interest-uuid Type = '1' ]-JournalEntryLender.
*        WHEN '2'.
*          ev_je_lender = accruals[  UUIDInterest = interest-uuid Type = '2' ]-JournalEntryLender.
*        WHEN '3' OR '4'.
*          ev_je_lender = repayment-JournalEntryLender.
*      ENDCASE.
*
*    ENDIF.
*
*    IF BorrowerStatus = '1'.
*      CASE type.
*        WHEN '1'.
*          ev_je_borrower = accruals[  UUIDInterest = interest-uuid Type = '1' ]-JournalEntryBorrower.
*        WHEN '2'.
*          ev_je_borrower = accruals[  UUIDInterest = interest-uuid Type = '2' ]-JournalEntryBorrower.
*        WHEN '3' OR '4'.
*          ev_je_borrower = repayment-JournalEntryBorrower.
*      ENDCASE.
*    ENDIF.


    "Post Journal Entries - Post Lender/Borrower journal entry that is not posted
    TRY.

        DATA(destination) = cl_soap_destination_provider=>create_by_comm_arrangement(
               comm_scenario  = 'ZZCS_FI_001'
               service_id     = 'ZZOS_FI_001_SPRX'
               comm_system_id = 'SELF'
          ).



        DATA(proxy) = NEW zco_journal_entry_create_reque( destination = destination ).

        " fill request
        DATA(request) = zzcl_fi_001=>processpayloadofjournalentry(
                          simulate = abap_true
                          type = type
                          interest = interest-%data
                          repayment = repayment-%data
                          inputparams = inputparams
                          lenderstatus = lenderstatus
                          borrowerstatus = borrowerstatus
                        ).
        proxy->journal_entry_create_request_c(
          EXPORTING
            input = request
          IMPORTING
            output = DATA(response)
        ).

        " Process response
        IF lines( response-journal_entry_bulk_create_conf-journal_entry_create_confirmat ) > 0.
          LOOP AT response-journal_entry_bulk_create_conf-journal_entry_create_confirmat ASSIGNING FIELD-SYMBOL(<fs_je>).
*            IF <fs_je>-journal_entry_create_confirmat-accounting_document <> '0000000000'.
*              IF <fs_je>-journal_entry_create_confirmat-company_code = interest-Lender.
*                ev_je_lender = <fs_je>-journal_entry_create_confirmat-accounting_document.
*              ELSE.
*                ev_je_borrower = <fs_je>-journal_entry_create_confirmat-accounting_document.
*              ENDIF.
*              ev_fiscalyear = <fs_je>-journal_entry_create_confirmat-fiscal_year.
*            ENDIF.
            "Process Message
            LOOP AT <fs_je>-log-item ASSIGNING FIELD-SYMBOL(<msgitem>).
              APPEND convertlogtobapimsg( log = <msgitem> ) TO et_message.
*              APPEND VALUE #(
*                            type = SWITCH #( <msgitem>-severity_code
*                                WHEN '1' THEN if_abap_behv_message=>severity-success
*                                WHEN '2' THEN if_abap_behv_message=>severity-warning
*                                WHEN '3' THEN if_abap_behv_message=>severity-error
*                            )
*                id = 'SABP_BEHV'
*                number = 100
*                message_v1 = <msgitem>-note
*              ) TO et_message.
            ENDLOOP.
          ENDLOOP.
        ENDIF.

      CATCH cx_soap_destination_error cx_ai_system_fault INTO DATA(lx_system).
*        APPEND VALUE #(
*          %tky = <interest>-%tky
*        ) TO failed-interest.
*        APPEND VALUE #(
*          %tky = <interest>-%tky
*          %msg = new_message_with_text(
*              severity = if_abap_behv_message=>severity-error
*              text = lx_system->get_text(  )
*          )
*          %action-postingofinitialprincipal = if_abap_behv=>mk-on
*        ) TO reported-interest.
*        APPEND VALUE #(
*            type = if_abap_behv_message=>severity-error
*            id = 'SABP_BEHV'
*            number = 100
*            message_v1 = lx_system->get_text(  )
*        ) TO et_message.
        APPEND convertlogtobapimsg( log = VALUE #(
            severity_code = '3'
            note = lx_system->get_text(  )
            )
         ) TO et_message.


        " handle error
    ENDTRY.
  ENDMETHOD.
  METHOD convertcurrencytoexternal.
    amount_out = cl_abap_decfloat=>convert_curr_to_decfloat(
        EXPORTING
            amount_curr = amount
            cuky = currency
    ).
  ENDMETHOD.

ENDCLASS.
