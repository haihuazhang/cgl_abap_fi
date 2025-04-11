CLASS lhc_zr_sfi038 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    TYPES : message_t           TYPE STANDARD TABLE OF symsg WITH DEFAULT KEY,
            tt_invoice_failed   TYPE TABLE FOR FAILED   zr_sfi038,
            tt_invoice_reported TYPE TABLE FOR REPORTED zr_sfi038.

    CONSTANTS : BEGIN OF common,
                  template_name TYPE string VALUE 'Invoice_print',
                END OF common.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zr_sfi038 RESULT result.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zr_sfi038.

    METHODS read FOR READ
      IMPORTING keys FOR READ zr_sfi038 RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK zr_sfi038.
    METHODS sendemail FOR MODIFY
      IMPORTING keys FOR ACTION zr_sfi038~sendemail.
    METHODS print FOR MODIFY
      IMPORTING keys FOR ACTION zr_sfi038~print RESULT result.
    METHODS cancel FOR MODIFY
      IMPORTING keys FOR ACTION zr_sfi038~cancel.

    METHODS map_messages
      IMPORTING
        cid                TYPE string         OPTIONAL
        companycode        TYPE bukrs OPTIONAL
        fiscalyear         TYPE gjahr OPTIONAL
        accountingdocument TYPE belnr_d OPTIONAL
        messages           TYPE message_t
      EXPORTING
        failed_added       TYPE abap_boolean
      CHANGING
        failed             TYPE tt_invoice_failed
        reported           TYPE tt_invoice_reported.

ENDCLASS.

CLASS lhc_zr_sfi038 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.



  METHOD update.
    DATA: messages TYPE TABLE OF symsg,
          invoicex TYPE zzcl_fi_004=>ts_invoice_inx.
*          invoice   TYPE zr_sfi038,
*          invoicex  TYPE . "refers to x structure (> BAPIs)

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<invoice>).
      invoicex = CORRESPONDING #( <invoice> ).
      invoicex-_intx = CORRESPONDING #( <invoice> MAPPING FROM ENTITY ).
      zzcl_fi_004=>get_instance( )->update_invoice( EXPORTING is_invoice             = <invoice>-%data
                                                               is_invoicex             = invoicex
                                                     IMPORTING es_invoice              = DATA(ls_invoice)
                                                               et_messages            = DATA(lt_messages) ).

      zzcl_fi_004=>get_instance( )->convert_messages( EXPORTING it_messages = lt_messages
                                                                IMPORTING et_messages = messages ).

      map_messages(
          EXPORTING
            cid       = <invoice>-%cid_ref
            messages  = messages
            companycode = <invoice>-companycode
            fiscalyear = <invoice>-fiscalyear
            accountingdocument = <invoice>-accountingdocument

          CHANGING
            failed    = failed-zr_sfi038
            reported  = reported-zr_sfi038
        ).
    ENDLOOP.


  ENDMETHOD.



  METHOD read.
    DATA: invoice_out TYPE zr_sfi038,
          messages    TYPE message_t.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<invoice>) GROUP BY <invoice>-%tky.
      zzcl_fi_004=>get_instance( )->get_invoice( EXPORTING iv_invoice_key          = CORRESPONDING #( <invoice>-%tky )
                                                          iv_include_buffer     = abap_false
                                                IMPORTING es_invoice             = invoice_out
                                                          et_messages           = DATA(lt_messages) ).

      zzcl_fi_004=>get_instance( )->convert_messages( EXPORTING it_messages = lt_messages
                                                                IMPORTING et_messages = messages ).

      map_messages(
          EXPORTING
            accountingdocument = <invoice>-accountingdocument
            messages         = messages
          IMPORTING
            failed_added = DATA(failed_added)
          CHANGING
            failed           = failed-zr_sfi038
            reported         = reported-zr_sfi038
        ).

      IF failed_added = abap_false.
        INSERT CORRESPONDING #( invoice_out ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD map_messages.
    failed_added = abap_false.
    LOOP AT messages INTO DATA(message).
      IF message-msgty = 'E' OR message-msgty = 'A'.
        APPEND VALUE #( %cid        = cid
                        companycode = companycode
                        fiscalyear = fiscalyear
                        accountingdocument    = accountingdocument
                        %fail-cause = if_abap_behv=>cause-dependency
                                      )
               TO failed.
        failed_added = abap_true.
      ENDIF.

      APPEND VALUE #( %msg          = new_message(
                                        id       = message-msgid
                                        number   = message-msgno
                                        severity = if_abap_behv_message=>severity-error
                                        v1       = message-msgv1
                                        v2       = message-msgv2
                                        v3       = message-msgv3
                                        v4       = message-msgv4 )
                      %cid          = cid
                        companycode = companycode
                        fiscalyear = fiscalyear
                      accountingdocument    = accountingdocument )
             TO reported.
    ENDLOOP.
  ENDMETHOD.

  METHOD sendemail.
    DATA : lt_print_record TYPE TABLE FOR ACTION IMPORT zr_zt_prt_record\\record~createprintrecordandreturnimme,
           ls_print_record TYPE STRUCTURE FOR ACTION IMPORT zr_zt_prt_record\\record~createprintrecordandreturnimme.
    READ ENTITIES OF zr_sfi038
        IN LOCAL MODE
            ENTITY zr_sfi038
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(invoices).

    LOOP AT invoices ASSIGNING FIELD-SYMBOL(<invoice>).
      IF <invoice>-status = '10'.
        CLEAR: ls_print_record.

*        TRY.
        FIELD-SYMBOLS <cid_tky> TYPE c.
        ASSIGN <invoice>-%tky TO <cid_tky> CASTING .

        ls_print_record = VALUE #(
             %cid = <cid_tky>
*           %cid = keys[ %tky = <invoice>-%tky ]-%cid_ref
             %param = VALUE #(
                 numberofcopies = 1
                 printqueue = ''
                 sendtoprintqueue = abap_false
                 templatename = lhc_zr_sfi038=>common-template_name
                 isexternalprovideddata = abap_false
                 providedkeys = /ui2/cl_json=>serialize(
                                     data = <invoice>-%tky
                                )
              )
        ).
*        MOVE <invoice>-%tky to ls_print_record-%cid.
*          CATCH cx_uuid_error.
        "handle exception
*        ENDTRY.
        APPEND ls_print_record TO lt_print_record.
      ELSE.
        APPEND VALUE #(
            %tky = <invoice>-%tky
            %fail-cause =  if_abap_behv=>cause-disabled
            ) TO failed-zr_sfi038.
        APPEND VALUE #(
        %tky = <invoice>-%tky
        %msg = new_message(
                                        id       = 'ZZFI'
                                        number   = 009
                                        severity = if_abap_behv_message=>severity-error
                                        v1       = <invoice>-accountingdocument )
        ) TO reported-zr_sfi038.
      ENDIF.

    ENDLOOP.

    IF lt_print_record IS NOT INITIAL.
      MODIFY ENTITIES OF zr_zt_prt_record
          ENTITY record
            EXECUTE createprintrecordandreturnimme
          FROM lt_print_record
      RESULT DATA(lt_result)
      MAPPED FINAL(mapped_record)
      REPORTED FINAL(reported_record)
      FAILED FINAL(failed_record).


      reported-printrecord = reported_record-record.
      mapped-printrecord = mapped_record-record.

      failed-printrecord = failed_record-record.

      LOOP AT failed_record-record ASSIGNING FIELD-SYMBOL(<record>).
        APPEND VALUE #(
            %tky = keys[ KEY cid %cid_ref = <record>-%cid ]-%tky
            %fail = <record>-%fail
        ) TO failed-zr_sfi038.
      ENDLOOP.

      IF lt_result IS NOT INITIAL.
*        result = VALUE #( FOR ls_result IN lt_result (
*            %tky = ls_result-%cid
*            %param = CORRESPONDING #( ls_result-%param )
*            %param-Url =
*         ) ).

        "Sender
        "Get Current User ID
        DATA(user) = cl_abap_context_info=>get_user_technical_name(  ).
        SELECT SINGLE addresspersonid,
                      addressid
            FROM i_user WITH PRIVILEGED ACCESS
            WHERE userid = @user
            INTO @DATA(user_address_id).
        IF sy-subrc = 0.
          SELECT SINGLE emailaddress
              FROM i_addressemailaddress_2 WITH PRIVILEGED ACCESS
              WHERE addressid = @user_address_id-addressid
                AND addresspersonid = @user_address_id-addresspersonid
                INTO @DATA(sender_addr).
          IF sy-subrc NE 0.
            " Error No Sender email
          ELSE.
            LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<result>).
              TRY.
                  DATA(lo_mail) = cl_bcs_mail_message=>create_instance( ).
                  lo_mail->set_sender( CONV cl_bcs_mail_message=>ty_address( sender_addr ) ).
*                  lo_mail->add_recipient(  )
                  SPLIT keys[ KEY entity %tky = VALUE #( companycode = <result>-%cid(4) fiscalyear = <result>-%cid+4(4) accountingdocument = <result>-%cid+8(10) )  ]-%param-recipients AT ';' INTO TABLE DATA(recipients).
                  LOOP AT recipients ASSIGNING FIELD-SYMBOL(<recipient>).
                    lo_mail->add_recipient( CONV cl_bcs_mail_message=>ty_address( <recipient> ) ).
                  ENDLOOP.
                  DATA(lv_str) = 'Invoice_' && <result>-%cid+0(4) .
                  SELECT SINGLE
                  emailtype  ,
                  emailsubject ,
                  emailcontent
                  FROM ztfi009  WHERE emailtype = @lv_str INTO  @DATA(ls_ztfi009).
                  IF sy-subrc = 0.
                   READ TABLE invoices ASSIGNING FIELD-SYMBOL(<fs_invoice>) WITH KEY   companycode = <result>-%cid(4)
                                                                     fiscalyear = <result>-%cid+4(4)
                                                                     accountingdocument = <result>-%cid+8(10).
                      if <fs_invoice> is ASSIGNED.
                        DATA(lv_invoice) = <fs_invoice>-INVOICENO.
                      ENDIF.
                      ls_ztfi009-emailsubject = ls_ztfi009-emailsubject && '(' && lv_invoice && ')'.
                    lo_mail->set_subject( CONV cl_bcs_mail_message=>ty_subject( ls_ztfi009-emailsubject ) ).

                    DATA(lv_content) = ls_ztfi009-emailcontent .

                  ELSE.
                    APPEND VALUE #(
                    %tky = <invoice>-%tky
                    %fail-cause =  if_abap_behv=>cause-disabled
                    ) TO failed-zr_sfi038.
                    APPEND VALUE #(
                    %tky = <invoice>-%tky
                    %msg = new_message(
                                                    id       = 'ZZFI'
                                                    number   = 011
                                                    severity = if_abap_behv_message=>severity-error
                                                    v1       =  <result>-%cid )
                    ) TO reported-zr_sfi038.
                  CONTINUE.
                  ENDIF.


                  lo_mail->set_main( cl_bcs_mail_textpart=>create_instance(
                      iv_content      = lv_content
                      iv_content_type = 'text/html' ) ).

                  DATA(lo_attachment) = cl_bcs_mail_binarypart=>create_instance(
                                           iv_content      = <result>-%param-pdf
                                           iv_content_type = <result>-%param-mimetype
                                           iv_filename     = |Sales Invoice - { <result>-%cid }.pdf| ).
                  lo_mail->add_attachment( lo_attachment ).

*                  lo_mail->send( IMPORTING et_status = DATA(lt_status) ).
                  zzcl_fi_004=>get_instance( )->store_email_instance( lo_mail  ).

                CATCH cx_bcs_mail INTO DATA(lo_err).
                  APPEND VALUE #(
                    %tky = VALUE #(
                        companycode = <result>-%cid(4)
                        fiscalyear = <result>-%cid+4(4)
                        accountingdocument = <result>-%cid+8(10)
                    )
                    %fail-cause =  if_abap_behv=>cause-disabled
                  ) TO failed-zr_sfi038.
                  APPEND VALUE #(
                  %tky = VALUE #(
                        companycode = <result>-%cid(4)
                        fiscalyear = <result>-%cid+4(4)
                        accountingdocument = <result>-%cid+8(10)
                    )
                  %msg = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text = lo_err->get_text(  )
                  )
                  ) TO reported-zr_sfi038.
                  CONTINUE.
              ENDTRY.
            ENDLOOP.


          ENDIF.
        ENDIF.



      ENDIF.

    ENDIF.


  ENDMETHOD.

  METHOD print.
    DATA : lt_print_record TYPE TABLE FOR ACTION IMPORT zr_zt_prt_record\\record~createprintrecordandreturnimme,
           ls_print_record TYPE STRUCTURE FOR ACTION IMPORT zr_zt_prt_record\\record~createprintrecordandreturnimme.

    READ ENTITIES OF zr_sfi038
        IN LOCAL MODE
            ENTITY zr_sfi038
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(invoices).
    LOOP AT invoices ASSIGNING FIELD-SYMBOL(<invoice>).
      IF <invoice>-status = '10'.
        CLEAR: ls_print_record.

        FIELD-SYMBOLS <cid_tky> TYPE c.

        ASSIGN <invoice>-%tky TO <cid_tky> CASTING.
*        TRY.
        ls_print_record = VALUE #(
             %cid = <cid_tky>
*           %cid = keys[ %tky = <invoice>-%tky ]-%cid_ref
             %param = VALUE #(
                 numberofcopies = keys[ %tky = <invoice>-%tky ]-%param-numberofcopies
                 printqueue = keys[ %tky = <invoice>-%tky ]-%param-printqueue
                 sendtoprintqueue = keys[ %tky = <invoice>-%tky ]-%param-sendtoprintqueue
                 templatename = keys[ %tky = <invoice>-%tky ]-%param-templatename
                 isexternalprovideddata = abap_false
                 providedkeys = /ui2/cl_json=>serialize(
                                     data = <invoice>-%tky
                                )
              )
        ).
*          CATCH cx_uuid_error .
        "handle exception
*        ENDTRY.
        APPEND ls_print_record TO lt_print_record.
      ELSE.
        APPEND VALUE #(
            %tky = <invoice>-%tky
            %fail-cause =  if_abap_behv=>cause-disabled
            ) TO failed-zr_sfi038.
        APPEND VALUE #(
        %tky = <invoice>-%tky
        %msg = new_message(
                                        id       = 'ZZFI'
                                        number   = 009
                                        severity = if_abap_behv_message=>severity-error
                                        v1       = <invoice>-accountingdocument )
        ) TO reported-zr_sfi038.
      ENDIF.

    ENDLOOP.

    IF lt_print_record IS NOT INITIAL.
      MODIFY ENTITIES OF zr_zt_prt_record
          ENTITY record
*          EXECUTE createprintrecord
            EXECUTE createprintrecordandreturnimme
          FROM lt_print_record
      RESULT DATA(lt_result)
      MAPPED FINAL(mapped_record)
      REPORTED FINAL(reported_record)
      FAILED FINAL(failed_record).


      reported-printrecord = reported_record-record.
      mapped-printrecord = mapped_record-record.

      failed-printrecord = failed_record-record.
*      failed-zr_sfi038 = VALUE #(
*          FOR failed_print_record IN failed_record-record (
*
*              %tky = keys[ %cid_ref = failed_print_record-%cid ]-%tky
*              %fail = failed_print_record-%fail
*          )
*
*       ).
      LOOP AT failed_record-record ASSIGNING FIELD-SYMBOL(<record>).
        APPEND VALUE #(
            %tky = keys[ KEY cid %cid_ref = <record>-%cid ]-%tky
            %fail = <record>-%fail
        ) TO failed-zr_sfi038.
      ENDLOOP.


      IF lt_result IS NOT INITIAL.
        result = VALUE #( FOR ls_result IN lt_result (
            %tky = VALUE #(
                companycode  = ls_result-%cid(4)
                fiscalyear = ls_result-%cid+4(4)
                accountingdocument = ls_result-%cid+8(10)
            )
*            ls_result-%cid
            %param = CORRESPONDING #( ls_result-%param )
*            %param-Url =
         ) ).
      ENDIF.



    ENDIF.


  ENDMETHOD.

  METHOD cancel.
*********************** Cancel方法编写
    READ ENTITIES OF zr_sfi038
        IN LOCAL MODE
            ENTITY zr_sfi038
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(invoices).

    LOOP AT invoices ASSIGNING FIELD-SYMBOL(<fs_invoices>).
      <fs_invoices>-status =  '30' .
    ENDLOOP.

    DATA : lt_zr_sfi038_update TYPE TABLE FOR UPDATE zr_sfi038,
           ls_zr_sfi038_update TYPE STRUCTURE FOR UPDATE zr_sfi038.

    LOOP AT invoices ASSIGNING <fs_invoices>.
      ls_zr_sfi038_update = VALUE #(
         %tky = <fs_invoices>-%tky
         status = <fs_invoices>-status
       ).
      APPEND ls_zr_sfi038_update TO lt_zr_sfi038_update.
      CLEAR ls_zr_sfi038_update.
    ENDLOOP.

    MODIFY ENTITIES OF zr_sfi038
        IN LOCAL MODE
        ENTITY zr_sfi038
        UPDATE FIELDS ( status )
        WITH lt_zr_sfi038_update
     MAPPED FINAL(mapped_invoices)
     FAILED FINAL(failed_invoices)
     REPORTED FINAL(lt_reported).

    IF mapped_invoices-zr_sfi038 IS NOT INITIAL.
      LOOP AT mapped-zr_sfi038 ASSIGNING FIELD-SYMBOL(<mapped_zr_sfi038>).
        APPEND VALUE #( %tky = <mapped_zr_sfi038>-%tky
                        %msg = new_message(
        id       = '00'
        number   = 000
        severity = if_abap_behv_message=>severity-success
        v1       = 'The status is changed'
        )
    )  TO reported-zr_sfi038.


      ENDLOOP.

    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zr_sfi038 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    TYPES : message_t TYPE STANDARD TABLE OF symsg WITH DEFAULT KEY,
            BEGIN OF message_with_key,
              companycode        TYPE bukrs,
              fiscalyear         TYPE gjahr,
              accountingdocument TYPE belnr_d,
              messages           TYPE message_t,
            END OF message_with_key,
            tt_message_with_key TYPE STANDARD TABLE OF message_with_key WITH DEFAULT KEY,

            tt_invoice_failed   TYPE TABLE FOR FAILED   zr_sfi038,
            tt_invoice_reported TYPE TABLE FOR REPORTED LATE zr_sfi038.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.
    METHODS map_messages1
      IMPORTING
        cid                TYPE string         OPTIONAL
        companycode        TYPE bukrs OPTIONAL
        fiscalyear         TYPE gjahr OPTIONAL
        accountingdocument TYPE belnr_d OPTIONAL
        messages           TYPE tt_message_with_key
      EXPORTING
        failed_added       TYPE abap_boolean
      CHANGING
        failed             TYPE tt_invoice_failed OPTIONAL
        reported           TYPE tt_invoice_reported.
*  PRIVATE SECTION.
*        METHODS map_messages
*      IMPORTING
*        cid                TYPE string         OPTIONAL
*        accountingdocument TYPE belnr_d OPTIONAL
*        messages           TYPE message_t
*      EXPORTING
*        failed_added       TYPE abap_boolean
*      CHANGING
*        failed             TYPE tt_invoice_failed
*        reported           TYPE tt_invoice_reported.

ENDCLASS.

CLASS lsc_zr_sfi038 IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    DATA: messages TYPE tt_message_with_key.
    zzcl_fi_004=>get_instance(  )->save(
        IMPORTING
            et_messages = DATA(lt_messages)
     ).
    zzcl_fi_004=>get_instance( )->convert_messages_with_key( EXPORTING it_messages = lt_messages
                                                              IMPORTING et_messages = messages ).

    map_messages1(
        EXPORTING
*          cid       = <invoice>-%cid_ref
          messages  = messages
        CHANGING
*          failed    = failed-zr_sfi038
          reported  = reported-zr_sfi038
      ).
  ENDMETHOD.

  METHOD cleanup.
    zzcl_fi_004=>get_instance(  )->initialize(  ).
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

  METHOD map_messages1.
    failed_added = abap_false.
    LOOP AT messages INTO DATA(message_with_key).
*      IF message-msgty = 'E' OR message-msgty = 'A'.
*        APPEND VALUE #( %cid        = cid
*                        companycode = companycode
*                        fiscalyear = fiscalyear
*                        accountingdocument    = accountingdocument
*                        %fail-cause = if_abap_behv=>cause-dependency
*                                      )
*               TO failed.
*        failed_added = abap_true.
*      ENDIF.
      LOOP AT message_with_key-messages ASSIGNING FIELD-SYMBOL(<message>).
        APPEND VALUE #( %msg          = new_message(
                                       id       = <message>-msgid
                                       number   = <message>-msgno
                                       severity = if_abap_behv_message=>severity-error
                                       v1       = <message>-msgv1
                                       v2       = <message>-msgv2
                                       v3       = <message>-msgv3
                                       v4       = <message>-msgv4 )
*                      %cid          = cid
                     companycode = message_with_key-companycode
                     fiscalyear = message_with_key-fiscalyear
                     accountingdocument    = message_with_key-accountingdocument )
            TO reported.
      ENDLOOP.


    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
