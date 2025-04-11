CLASS zzcl_dtimp_process_contract DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zzif_process_data .
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA g_result TYPE cl_exchange_rates=>ty_messages.
ENDCLASS.



CLASS ZZCL_DTIMP_PROCESS_CONTRACT IMPLEMENTATION.


  METHOD zzif_process_data~process.
    DATA : ls_message TYPE zzs_dmp_data_list.
    CREATE DATA eo_data TYPE HANDLE io_data_handle.
    DATA : lt_zr_tfi001 TYPE TABLE FOR CREATE zr_tfi001.
*行表
    DATA : lt_zr_tfi002 TYPE TABLE FOR CREATE zr_tfi001\\interest\_repayment,
           ls_zr_tfi002 TYPE STRUCTURE FOR CREATE zr_tfi001\\interest\_repayment.
    DATA:ls_msg TYPE LINE OF bapirettab,
         lt_msg TYPE bapirettab.
    eo_data->* = io_data->*.

    LOOP AT io_data->* ASSIGNING FIELD-SYMBOL(<fs_data>).
      DATA(lv_tabix) = sy-tabix.
      ASSIGN COMPONENT 'LINE_NO' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_line_no>).
      <fs_line_no> = lv_tabix.
      ASSIGN COMPONENT 'CONTRACT_ID' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_contract_id>).
      ASSIGN COMPONENT 'CONTRACT_TYPE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_contract_type>).
      ASSIGN COMPONENT 'CONTRACT_NAME' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_contract_name>).
      ASSIGN COMPONENT 'LENDER' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_lender>).
      ASSIGN COMPONENT 'BORROWER' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_borrower>).
      ASSIGN COMPONENT 'START_DATE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_start_date>).
      ASSIGN COMPONENT 'LOAN_MATURITY_DATE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_loan_maturity_date>).
      ASSIGN COMPONENT 'INITIAL_PRINCIPAL' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_initial_principal>).
      ASSIGN COMPONENT 'CURRENCY' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_currency>).
*      ASSIGN COMPONENT 'EXCHANGE_RATE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_exchange_rate>).
      ASSIGN COMPONENT 'INTEREST_RATE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_ex_rates>).
      ASSIGN COMPONENT 'OTHER_EXPENSES' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_other_expenses>).
      APPEND VALUE #(
                                  %cid = <fs_contract_id>
                                  %data = VALUE #(
                                    contracttype    = <fs_contract_type>
                                    contractname    = <fs_contract_name>
                                    lendercompany   = <fs_lender>
                                    borrowercompany = <fs_borrower>
                                    startdate       = <fs_start_date>
                                    loanmaturitydate = <fs_loan_maturity_date>
                                    initialprincipal = <fs_initial_principal>
                                    currency         = <fs_currency>
*                                    ExchangeRate     = <fs_exchange_rate>
                                    exrates          = <fs_ex_rates>
                                    otherexpenses    = <fs_other_expenses>
                                  )
                                  %control =  VALUE #(
                                    contracttype    = if_abap_behv=>mk-on
                                    contractname    = if_abap_behv=>mk-on
                                    lendercompany           = if_abap_behv=>mk-on
                                    borrowercompany         = if_abap_behv=>mk-on
                                    startdate       = if_abap_behv=>mk-on
                                    loanmaturitydate = if_abap_behv=>mk-on
                                    initialprincipal = if_abap_behv=>mk-on
                                    currency         = if_abap_behv=>mk-on
*                                    ExchangeRate     = if_abap_behv=>mk-on
                                     exrates          = if_abap_behv=>mk-on
                                    otherexpenses    = if_abap_behv=>mk-on
                                  )


                            ) TO lt_zr_tfi001.


      ASSIGN COMPONENT 'REPAYMENT' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<t_repayment>).
      IF <t_repayment> IS ASSIGNED.
        CLEAR ls_zr_tfi002.
        ls_zr_tfi002-%cid_ref = <fs_contract_id>.
        LOOP AT <t_repayment> ASSIGNING FIELD-SYMBOL(<fs_data1>).
          ASSIGN COMPONENT 'REPAYMENT_TYPE' OF STRUCTURE <fs_data1> TO FIELD-SYMBOL(<fs_repayment_type>).
          ASSIGN COMPONENT 'REPAYMENT_DATE' OF STRUCTURE <fs_data1> TO FIELD-SYMBOL(<fs_repayment_date>).
          ASSIGN COMPONENT 'AMOUNT' OF STRUCTURE <fs_data1> TO FIELD-SYMBOL(<fs_amount>).
          ASSIGN COMPONENT 'CURRENCY' OF STRUCTURE <fs_data1> TO FIELD-SYMBOL(<fs_currency1>).
          ASSIGN COMPONENT 'REPAYMENT_NUMBER' OF STRUCTURE <fs_data1> TO FIELD-SYMBOL(<fs_repayment_num>).
          TRY.
              APPEND VALUE #(
                                        %cid =  cl_system_uuid=>create_uuid_c36_static(  )
                                        %data = VALUE #(
                                           repaymenttype1 = <fs_repayment_type>
                                           repaymentdate  = <fs_repayment_date>
                                           repaymentamount = <fs_amount>
                                           currency       = <fs_currency1>
                                           repaymentnumber = <fs_repayment_num>
                                        )
                                        %control = VALUE #(
                                            repaymenttype1 = if_abap_behv=>mk-on
                                            repaymentdate  = if_abap_behv=>mk-on
                                            repaymentamount = if_abap_behv=>mk-on
                                            currency       = if_abap_behv=>mk-on
                                            repaymentnumber = if_abap_behv=>mk-on
                                        )
                                     ) TO ls_zr_tfi002-%target.
            CATCH cx_uuid_error.
              APPEND VALUE #( type = 'E' message = 'cx_uuid_error' ) TO g_result.
          ENDTRY.

        ENDLOOP.
      ENDIF.


      APPEND ls_zr_tfi002 TO lt_zr_tfi002.

    ENDLOOP.

    MODIFY ENTITIES OF zr_tfi001
        ENTITY interest
          CREATE  FIELDS (          contracttype
                                    contractname
                                    lendercompany
                                    borrowercompany
*                                    Lender
*                                    Borrower
                                    startdate
                                    loanmaturitydate
                                    initialprincipal
                                    currency
*                                    ExchangeRate
                                     exrates
                                    otherexpenses  ) WITH lt_zr_tfi001
          CREATE BY \_repayment
          FIELDS ( repaymenttype1 repaymentdate repaymentamount currency repaymentnumber ) WITH lt_zr_tfi002

                        MAPPED DATA(mapped)
                        REPORTED DATA(reported)
                        FAILED DATA(failed).
    IF   failed-interest IS NOT INITIAL .
      LOOP AT failed-interest ASSIGNING FIELD-SYMBOL(<fs_failed>).
        DATA(lv_cid) = <fs_failed>-%cid.
        LOOP AT io_data->* ASSIGNING FIELD-SYMBOL(<fs_cid>).
          UNASSIGN : <fs_contract_id>,<fs_line_no>.CLEAR:lt_msg.
          ASSIGN COMPONENT 'CONTRACT_ID' OF STRUCTURE <fs_cid> TO <fs_contract_id>.
          IF  <fs_contract_id> IS ASSIGNED.
            IF <fs_contract_id> = lv_cid.
              ASSIGN COMPONENT 'LINE_NO' OF STRUCTURE <fs_cid> TO <fs_line_no>.
              ls_message-line = <fs_line_no>.
            ENDIF.
          ENDIF.
        ENDLOOP.
        ls_msg-type = 'E'.
        ls_msg-id = 'SABP_BEHV'.
        ls_msg-number = '00'.
        ls_msg-message_v1 =  <fs_failed>-%fail-cause.
        APPEND  ls_msg TO lt_msg[].
        CLEAR ls_msg.
        ls_message-message_list = lt_msg[].
        APPEND ls_message  TO et_message.
        CLEAR ls_message.

      ENDLOOP.
      ROLLBACK ENTITIES.
    ELSE.

      COMMIT ENTITIES RESPONSES
          FAILED DATA(failed_commit)
          REPORTED DATA(reported_commit).

      IF sy-subrc <> 0.
        ROLLBACK ENTITIES.
      ENDIF.

      LOOP AT  reported_commit ASSIGNING FIELD-SYMBOL(<reported_commit>).

        LOOP AT <reported_commit>-entries->* ASSIGNING FIELD-SYMBOL(<fs_msg>).
          ASSIGN COMPONENT '%MSG' OF STRUCTURE <fs_msg> TO FIELD-SYMBOL(<t_msg1>).
          ASSIGN COMPONENT 'UUID' OF STRUCTURE <fs_msg> TO FIELD-SYMBOL(<fs_uuid>).
          IF  <fs_uuid> IS ASSIGNED.
            DATA(lt_map) = mapped-interest.
            READ TABLE lt_map INTO DATA(lwa_map) WITH KEY uuid = <fs_uuid>.
            lv_cid = lwa_map-%cid.
            LOOP AT io_data->* ASSIGNING <fs_cid>.
              UNASSIGN : <fs_contract_id>,<fs_line_no>.CLEAR:lt_msg.
              ASSIGN COMPONENT 'CONTRACT_ID' OF STRUCTURE <fs_cid> TO <fs_contract_id>.
              IF  <fs_contract_id> IS ASSIGNED.
                IF <fs_contract_id> = lv_cid.
                  ASSIGN COMPONENT 'LINE_NO' OF STRUCTURE <fs_cid> TO <fs_line_no>.
                  ls_message-line = <fs_line_no>.
                  DATA lo_msg TYPE REF TO if_abap_behv_message.
                  " ls_msg-row = sy-tabix.
                  lo_msg ?= <t_msg1>.
                  ls_msg-id = lo_msg->if_t100_message~t100key-msgid.
                  ls_msg-number = lo_msg->if_t100_message~t100key-msgno.
                  MESSAGE ID ls_msg-id TYPE 'E' NUMBER ls_msg-number INTO DATA(msgtext).
                  ls_msg-message_v1 = lo_msg->if_t100_dyn_msg~msgv1.
                  IF ls_msg-message_v1 IS INITIAL.
                    ls_msg-message_v1 = msgtext.
                  ENDIF.
                  ls_msg-message_v2 = lo_msg->if_t100_dyn_msg~msgv2.
                  ls_msg-message_v3 = lo_msg->if_t100_dyn_msg~msgv3.
                  ls_msg-message_v4 = lo_msg->if_t100_dyn_msg~msgv4.
                  ls_msg-type = lo_msg->if_t100_dyn_msg~msgty.
                  APPEND  ls_msg TO lt_msg[].
                  CLEAR ls_msg.
                  EXIT.
                ENDIF.
              ENDIF.
            ENDLOOP.
            ls_message-message_list = lt_msg[].
            APPEND ls_message  TO et_message.
            CLEAR ls_message.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
