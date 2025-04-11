CLASS zzcl_dtimp_journal_entry DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zzif_process_data .
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA g_result TYPE cl_exchange_rates=>ty_messages.

*    CLASS-METHODS:   convertlogtobapimsg
*      IMPORTING
*                log        TYPE zlog_item
*      RETURNING VALUE(msg) TYPE bapiret2.
ENDCLASS.



CLASS ZZCL_DTIMP_JOURNAL_ENTRY IMPLEMENTATION.


  METHOD zzif_process_data~process.

    DATA : ls_message TYPE zzs_dmp_data_list.
    DATA : ls_journal_entry TYPE zjournal_entry_create_reques18.
    DATA : ls_item          TYPE zjournal_entry_create_request9,
           lt_item          TYPE TABLE OF zjournal_entry_create_request9,
           ls_debitor_item  TYPE zjournal_entry_create_reques13,
           lt_debitor_item  TYPE TABLE OF zjournal_entry_create_reques13,
           ls_creditor_item TYPE zjournal_entry_create_reques16,
           lt_creditor_item TYPE TABLE OF zjournal_entry_create_reques16.
    CREATE DATA eo_data TYPE HANDLE io_data_handle.
    DATA:ls_msg TYPE LINE OF bapirettab,
         lt_msg TYPE bapirettab.
    eo_data->* = io_data->*.
    LOOP AT io_data->* ASSIGNING FIELD-SYMBOL(<fs_data>).
      "数据处理********head
      ASSIGN COMPONENT 'HEADER_KEY' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_header_key>).
      ASSIGN COMPONENT 'COMPANYCODE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_companycode>).
      ASSIGN COMPONENT 'ACCOUNTINGDOCUMENTTYPE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_accountingdocumenttype>).
      ASSIGN COMPONENT 'DOCUMENTREFERENCEID' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_documentreferenceid>).
      ASSIGN COMPONENT 'DOCUMENTHEADERTEXT' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_documentheadertext>).
      ASSIGN COMPONENT 'CREATEDBYUSER' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_createdbyuser>).
      ASSIGN COMPONENT 'DOCUMENTDATE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_documentdate>).
      ASSIGN COMPONENT 'POSTINGDATE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_postingdate>).
      ASSIGN COMPONENT 'INVOICERECEIPTDATE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_invoicereceiptdate>).
      ASSIGN COMPONENT 'EXCHANGERATEDATE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_exchangeratedate>).
      ASSIGN COMPONENT 'EXCHANGERATE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_exchangerate>).


      ls_journal_entry = VALUE #(
         original_reference_document_ty = 'BKPFF'
         business_transaction_type = 'RFBU'
         accounting_document_type = <fs_accountingdocumenttype>
         document_reference_id    = <fs_documentreferenceid>
         created_by_user = <fs_createdbyuser>
         company_code = <fs_companycode>
         document_date = <fs_documentdate>
         posting_date = <fs_postingdate>
         document_header_text = <fs_documentheadertext>
         invoice_receipt_date = <fs_invoicereceiptdate>
         exchange_rate_date   = <fs_exchangeratedate>
         exchange_rate        = <fs_exchangerate>
     ).

      ASSIGN COMPONENT 'GLITEMS' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<t_glitems>).
      ASSIGN COMPONENT 'ARITEMS' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<t_aritems>).
      ASSIGN COMPONENT 'APITEMS' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<t_apitems>).

      IF <t_glitems> IS ASSIGNED.
        LOOP AT <t_glitems> ASSIGNING FIELD-SYMBOL(<fs_glitems>).
          ASSIGN COMPONENT 'GLACCOUNT' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_glaccount>).
          ASSIGN COMPONENT 'DOCUMENTITEMTEXT' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_documentitemtext>).
          ASSIGN COMPONENT 'ASSIGNMENTREFERENCE' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_assignmentreference>).
          ASSIGN COMPONENT 'TAXCODE' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_taxcode>).
          ASSIGN COMPONENT 'VALUEDATE' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_valuedate>).
          ASSIGN COMPONENT 'HOUSEBANK' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_housebank>).
          ASSIGN COMPONENT 'PROFITCENTER' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_profitcenter>).
          ASSIGN COMPONENT 'COSTCENTER' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_costcenter>).
          ASSIGN COMPONENT 'WBSELEMENT' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_wbselement>).
          ASSIGN COMPONENT 'AMOUNTINTRANSACTIONCURRENCY' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_amountcurrency>).
          ASSIGN COMPONENT 'FINANCIALTRANSACTIONTYPE' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_financialtransactiontype>).
          ASSIGN COMPONENT 'HOUSEBANKACCOUNT' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_housebankaccount>).
          ASSIGN COMPONENT 'CURRENCYCODE' OF STRUCTURE <fs_glitems> TO FIELD-SYMBOL(<fs_currencycode>).

          ls_item-glaccount-content = <fs_glaccount>.
          ls_item-document_item_text =  <fs_documentitemtext>.
          ls_item-assignment_reference = <fs_assignmentreference>.
          ls_item-tax-tax_code-content = <fs_taxcode> .
          ls_item-value_date    = <fs_valuedate>.
          ls_item-house_bank = <fs_housebank>.
          ls_item-financial_transaction_type  = <fs_financialtransactiontype>.
          ls_item-house_bank_account = <fs_housebankaccount>.
          ls_item-amount_in_transaction_currency-content = <fs_amountcurrency>.
          ls_item-amount_in_transaction_currency-currency_code = <fs_currencycode>.
          ls_item-account_assignment-cost_center = <fs_costcenter>.
          ls_item-account_assignment-profit_center = <fs_profitcenter>.
          IF    <fs_wbselement> = '00000000'.
          ELSE.
            ls_item-account_assignment-wbselement = <fs_wbselement>.
          ENDIF.
          APPEND ls_item TO lt_item.
          CLEAR ls_item.
        ENDLOOP.
      ENDIF.
      IF <t_aritems> IS ASSIGNED.
        LOOP AT <t_aritems> ASSIGNING FIELD-SYMBOL(<fs_aritems>).
          ASSIGN COMPONENT 'CUSTOMER' OF STRUCTURE <fs_aritems> TO FIELD-SYMBOL(<fs_customer>).
          ASSIGN COMPONENT 'GLACCOUNT' OF STRUCTURE <fs_aritems> TO FIELD-SYMBOL(<fs_glaccount1>).
          ASSIGN COMPONENT 'CURRENCYAMOUNT' OF STRUCTURE <fs_aritems> TO FIELD-SYMBOL(<fs_currencyamount>).
          ASSIGN COMPONENT 'DOCUMENTITEMTEXT' OF STRUCTURE <fs_aritems> TO FIELD-SYMBOL(<fs_documentitemtext1>).
          ASSIGN COMPONENT 'ASSIGNMENTREFERENCE' OF STRUCTURE <fs_aritems> TO FIELD-SYMBOL(<fs_assignmentreference1>).
          ASSIGN COMPONENT 'CURRENCYCODE' OF STRUCTURE <fs_aritems> TO FIELD-SYMBOL(<fs_currencycode1>).

          ls_debitor_item-debtor = <fs_customer>.
          ls_debitor_item-altv_recncln_accts-content = <fs_glaccount1>.
          ls_debitor_item-document_item_text = <fs_documentitemtext1>.
          ls_debitor_item-assignment_reference = <fs_assignmentreference1>.
          ls_debitor_item-amount_in_transaction_currency-content = <fs_currencyamount>.
          ls_debitor_item-amount_in_transaction_currency-currency_code = <fs_currencycode1>.
          APPEND ls_debitor_item TO lt_debitor_item.
          CLEAR ls_debitor_item.
        ENDLOOP.

      ENDIF.

      IF <t_apitems> IS ASSIGNED.
        LOOP AT <t_apitems> ASSIGNING FIELD-SYMBOL(<fs_apitems>).
          ASSIGN COMPONENT 'VENDOR' OF STRUCTURE <fs_apitems> TO FIELD-SYMBOL(<fs_vendor>).
          ASSIGN COMPONENT 'GLACCOUNT' OF STRUCTURE <fs_apitems> TO FIELD-SYMBOL(<fs_glaccount2>).
          ASSIGN COMPONENT 'CURRENCYAMOUNT' OF STRUCTURE <fs_apitems> TO FIELD-SYMBOL(<fs_currencyamount2>).
          ASSIGN COMPONENT 'DOCUMENTITEMTEXT' OF STRUCTURE <fs_apitems> TO FIELD-SYMBOL(<fs_documentitemtext2>).
          ASSIGN COMPONENT 'ASSIGNMENTREFERENCE' OF STRUCTURE <fs_apitems> TO FIELD-SYMBOL(<fs_assignmentreference2>).
          ASSIGN COMPONENT 'CURRENCYCODE' OF STRUCTURE <fs_apitems> TO FIELD-SYMBOL(<fs_currencycode2>).

          ls_creditor_item-creditor = <fs_vendor>.
          ls_creditor_item-altv_recncln_accts-content = <fs_glaccount2>.
          ls_creditor_item-document_item_text = <fs_documentitemtext2>.
          ls_creditor_item-assignment_reference = <fs_assignmentreference2>.
          ls_creditor_item-amount_in_transaction_currency-content = <fs_currencyamount2>.
          ls_creditor_item-amount_in_transaction_currency-currency_code = <fs_currencycode2>.
          APPEND ls_creditor_item TO lt_creditor_item.
          CLEAR ls_creditor_item.
        ENDLOOP.

      ENDIF.
      MOVE-CORRESPONDING  lt_item TO ls_journal_entry-item .
      MOVE-CORRESPONDING  lt_creditor_item TO ls_journal_entry-creditor_item.
      MOVE-CORRESPONDING  lt_debitor_item TO ls_journal_entry-debtor_item.
      CLEAR :lt_item ,lt_creditor_item,lt_debitor_item.
      DATA :es_payload TYPE zjournal_entry_bulk_create_req.
      APPEND VALUE #(
          message_header = VALUE #(
              creation_date_time = es_payload-journal_entry_bulk_create_requ-message_header-creation_date_time
          )
          journal_entry  = ls_journal_entry

       ) TO es_payload-journal_entry_bulk_create_requ-journal_entry_create_request.

      "     IF simulate = abap_true.
      "es_payload-journal_entry_bulk_create_requ-message_header-test_data_indicator = 'X'.
      "     ENDIF.

    ENDLOOP.



    "方法调用
    TRY.

        DATA(destination) = cl_soap_destination_provider=>create_by_comm_arrangement(
               comm_scenario  = 'ZZCS_FI_001'
               service_id     = 'ZZOS_FI_001_SPRX'
               comm_system_id = 'SELF'
          ).



        DATA(proxy) = NEW zco_journal_entry_create_reque( destination = destination ).

        " fill request

        DATA(request) = es_payload.
        proxy->journal_entry_create_request_c(
          EXPORTING
            input = request
          IMPORTING
            output = DATA(response)
        ).

        " Process response

        "DATA : et_message TYPE TABLE of  bapiret2.
        IF lines( response-journal_entry_bulk_create_conf-journal_entry_create_confirmat ) > 0.
          LOOP AT response-journal_entry_bulk_create_conf-journal_entry_create_confirmat ASSIGNING FIELD-SYMBOL(<fs_je>).
            ls_message-line =  sy-tabix.
            DATA(lv_line) = 0.
            LOOP AT <fs_je>-log-item ASSIGNING FIELD-SYMBOL(<msgitem>).
              ls_msg-row = lv_line + 1.
              ls_msg-id = 'SABP_BEHV'.
              ls_msg-number = <msgitem>-type_id.
              IF <msgitem>-severity_code = '1'.
                ls_msg-type = if_abap_behv_message=>severity-success.
              ELSEIF <msgitem>-severity_code = '2'.
                ls_msg-type = if_abap_behv_message=>severity-warning.
              ELSE.
                ls_msg-type = if_abap_behv_message=>severity-error.
              ENDIF.
              ls_msg-message_v1 = <msgitem>-note.

              DATA(length) = strlen( <msgitem>-note ).

              IF length <= 50.
                ls_msg-message_v1 = <msgitem>-note(length).
              ELSEIF length > 50 AND length <= 100.
                DATA(length_v2) = length - 50.
                ls_msg-message_v1 = <msgitem>-note(50).
                ls_msg-message_v2 = <msgitem>-note+50(length_v2).
              ELSEIF length > 100 AND length <= 150.
                DATA(length_v3) = length - 100.
                ls_msg-message_v1 = <msgitem>-note(50).
                ls_msg-message_v2 = <msgitem>-note+50(50).
                ls_msg-message_v3 = <msgitem>-note+100(length_v3).
              ELSE.
                DATA(length_v4) = length - 150.
                ls_msg-message_v1 = <msgitem>-note(50).
                ls_msg-message_v2 = <msgitem>-note+50(50).
                ls_msg-message_v3 = <msgitem>-note+100(50).
                ls_msg-message_v4 = <msgitem>-note+150(length_v4).
              ENDIF.

              APPEND  ls_msg TO lt_msg[].
              CLEAR ls_msg.
            ENDLOOP.
            ls_message-message_list = lt_msg[].
            APPEND ls_message  TO et_message.
            CLEAR ls_message.CLEAR lt_msg[].
          ENDLOOP.
        ENDIF.
*
      CATCH cx_soap_destination_error cx_ai_system_fault INTO DATA(lx_system).
        ls_msg-row = 0.
        ls_msg-id =  'EXCEPTION'.
        DATA(text) = lx_system->get_text(  ).
        length = strlen( text ).

        IF length <= 50.
          ls_msg-message_v1 = text(length).
        ELSEIF length > 50 AND length <= 100.
          length_v2 = length - 50.
          ls_msg-message_v1 = text(50).
          ls_msg-message_v2 = text+50(length_v2).
        ELSEIF length > 100 AND length <= 150.
          length_v3 = length - 100.
          ls_msg-message_v1 = text(50).
          ls_msg-message_v2 = text+50(50).
          ls_msg-message_v3 = text+100(length_v3).
        ELSE.
          length_v4 = length - 150.
          ls_msg-message_v1 = text(50).
          ls_msg-message_v2 = text+50(50).
          ls_msg-message_v3 = text+100(50).
          ls_msg-message_v4 = text+150(length_v4).
        ENDIF.

        APPEND  ls_msg TO lt_msg[].
        CLEAR ls_msg.

        ls_message-message_list = lt_msg[].
        APPEND ls_message  TO et_message.
        CLEAR ls_message.

    ENDTRY.

  ENDMETHOD.
ENDCLASS.
