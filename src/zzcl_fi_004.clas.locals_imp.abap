*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

*CLASS ltc_invoice_addition DEFINITION DEFERRED.
CLASS lcl_invoice_addition_buffer DEFINITION FINAL CREATE PRIVATE .
*FRIENDS ltc_invoice_addition.
  PUBLIC SECTION.
    CONSTANTS : number_of_readonly_fields TYPE i VALUE '8',
                BEGIN OF invoice_status,
                  confirmed       TYPE c LENGTH 2 VALUE '10',
                  to_be_confirmed TYPE c LENGTH 2 VALUE '20',
                  reversed        TYPE c LENGTH 2 VALUE '30',
                END OF invoice_status.

    TYPES : tt_invoice TYPE STANDARD TABLE OF zr_sfi038 WITH EMPTY KEY.
    TYPES : tt_if_t100_message TYPE STANDARD TABLE OF REF TO if_t100_message WITH EMPTY KEY,
*            BEGIN OF ts_invoice_key,
*              companycode        TYPE bukrs,
*              fiscalyear         TYPE gjahr,
*              accountingdocument TYPE belnr_d,
*            END OF ts_invoice_key,
            tt_invoice_key     TYPE STANDARD TABLE OF zzcl_fi_004=>ts_invoice_key WITH DEFAULT KEY,
*            BEGIN OF ts_invoice_inx,
*              companycode        TYPE bukrs,
*              fiscalyear         TYPE gjahr,
*              accountingdocument TYPE belnr_d,
*              _intx              TYPE zzsfi002,
**              bankname           TYPE xsdboolean,
**              housebank          TYPE xsdboolean,
**              swift              TYPE xsdboolean,
**              iban               TYPE xsdboolean,
**              bankkey            TYPE xsdboolean,
**              accountid          TYPE xsdboolean,
**              bankaccount        TYPE xsdboolean,
**              invoicenumber      TYPE xsdboolean,
**              constantsymbol     TYPE xsdboolean,
**              status             TYPE xsdboolean,
*            END OF ts_invoice_inx,
            tt_invoice_inx     TYPE STANDARD TABLE OF zzcl_fi_004=>ts_invoice_inx WITH DEFAULT KEY,
            tt_mail            TYPE STANDARD TABLE OF REF TO cl_bcs_mail_message.

    CLASS-METHODS: get_instance RETURNING VALUE(ro_instance) TYPE REF TO lcl_invoice_addition_buffer.
    METHODS save      EXPORTING et_messages        TYPE tt_if_t100_message.
    METHODS initialize.
    METHODS cud_prep IMPORTING it_invoice         TYPE tt_invoice
                               it_invoicex        TYPE tt_invoice_inx
                               iv_no_delete_check TYPE abap_boolean OPTIONAL
*                               iv_numbering_mode  TYPE /dmo/if_flight_legacy=>t_numbering_mode DEFAULT /dmo/if_flight_legacy=>numbering_mode-early
                     EXPORTING et_invoice         TYPE tt_invoice
                               et_messages        TYPE tt_if_t100_message.
    "! Add content of the temporary buffer to the real buffer and clear the temporary buffer
    METHODS cud_copy.
    METHODS cud_disc.
    METHODS get IMPORTING it_invoice             TYPE tt_invoice
                          iv_include_buffer      TYPE abap_boolean
                          iv_include_temp_buffer TYPE abap_boolean
                EXPORTING et_invoice             TYPE tt_invoice.

    METHODS store_email_instance IMPORTING io_mail TYPE REF TO cl_bcs_mail_message.
    METHODS send_email      EXPORTING et_messages        TYPE tt_if_t100_message.

  PRIVATE SECTION.
    CLASS-DATA go_instance TYPE REF TO lcl_invoice_addition_buffer.

    " Main buffer
    DATA: mt_create_buffer TYPE tt_invoice,
          mt_update_buffer TYPE tt_invoice,
          mt_delete_buffer TYPE tt_invoice_key.
    " Temporary buffer valid during create / update / delete invoice
    DATA: mt_create_buffer_2 TYPE tt_invoice,
          mt_update_buffer_2 TYPE tt_invoice,
          mt_delete_buffer_2 TYPE tt_invoice_key.

    DATA: mt_mail TYPE tt_mail.

    METHODS _update IMPORTING it_invoice  TYPE tt_invoice
                              it_invoicex TYPE tt_invoice_inx
                    EXPORTING et_invoice  TYPE tt_invoice
                              et_messages TYPE tt_if_t100_message.

    METHODS _updatejournalentry
      IMPORTING it_invoice  TYPE tt_invoice
*                              it_invoicex TYPE tt_invoice_inx
      EXPORTING
                et_messages TYPE tt_if_t100_message.
ENDCLASS.

CLASS lcl_invoice_addition_buffer IMPLEMENTATION.

  METHOD get_instance.
    go_instance = COND #( WHEN go_instance IS BOUND THEN go_instance ELSE NEW #( ) ).
    ro_instance = go_instance.
  ENDMETHOD.

  METHOD cud_disc.
    CLEAR: mt_create_buffer_2, mt_update_buffer_2, mt_delete_buffer_2.
  ENDMETHOD.

  METHOD cud_prep.
    _update( EXPORTING it_invoice   = it_invoice
                   it_invoicex  = it_invoicex
         IMPORTING et_invoice   = DATA(lt_invoice)
                   et_messages = DATA(lt_messages) ).
    INSERT LINES OF lt_invoice INTO TABLE et_invoice.
    APPEND LINES OF lt_messages TO et_messages.

    IF lines( lt_messages ) = 0.
      _updatejournalentry( EXPORTING it_invoice = lt_invoice
*                   it_invoicex  = it_invoicex
       IMPORTING
*         et_invoice   = DATA(lt_invoice)
                 et_messages = lt_messages ).
      APPEND LINES OF lt_messages TO et_messages.
    ENDIF.

  ENDMETHOD.

  METHOD get.
*    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
    SELECT                                    "#EC CI_ALL_FIELDS_NEEDED
*      SINGLE
*    companycode,
*    fiscalyear,
*    accountingdocument,
*    accountingdocumenttype,
*    postingdate,
*    documentdate,
*    taxfulfillmentdate,
*    paymentmethod,
*    bankname,
*    housebank,
*    swift,
*    iban,
*    bankkey,
*    accountid,
*    bankaccount,
*    invoicenumber,
*    constantsymbol
        *
*      Status,
*      LastChangedBy,
*      LastChangedAt,
*      LocalLastChangedAt
        FROM zr_sfi038
        FOR ALL ENTRIES IN @it_invoice
        WHERE accountingdocument = @it_invoice-accountingdocument
          AND companycode = @it_invoice-companycode
          AND fiscalyear = @it_invoice-fiscalyear
       INTO CORRESPONDING FIELDS OF TABLE @et_invoice.
  ENDMETHOD.



  METHOD initialize.
    CLEAR: mt_create_buffer, mt_update_buffer, mt_delete_buffer.
    CLEAR: mt_mail.
  ENDMETHOD.

  METHOD save.
    DATA : lt_zfi008   TYPE TABLE OF ztfi008.
    DATA : lv_num_3 TYPE n LENGTH 3.
    lt_zfi008 = CORRESPONDING #( mt_update_buffer MAPPING FROM ENTITY ).

*    IF lines( et_messages ) = 0.
    MODIFY ztfi008 FROM TABLE @lt_zfi008.
*    ENDIF.
  ENDMETHOD.

  METHOD _update.

    DATA lv_new TYPE abap_boolean.

    CLEAR et_invoice.
    CLEAR et_messages.

*  DATA lt_invoice TYPE STANDARD TABLE OF zr_sfi038 WITH DEFAULT KEY.
*    SELECT * FROM zr_sfi038 FOR ALL ENTRIES IN @it_travel WHERE travel_id = @it_travel-travel_id INTO TABLE @lt_travel ##SELECT_FAE_WITH_LOB[DESCRIPTION].
    get(
        EXPORTING
            it_invoice = it_invoice
            iv_include_buffer = abap_false
            iv_include_temp_buffer = abap_false
        IMPORTING
            et_invoice = DATA(lt_invoice)

     ).


    FIELD-SYMBOLS <s_buffer_invoice> TYPE zr_sfi038.
    DATA ls_buffer_invoice TYPE zr_sfi038.

    CHECK it_invoice IS NOT INITIAL.
    LOOP AT it_invoice ASSIGNING FIELD-SYMBOL(<invoice_update>).
      UNASSIGN <s_buffer_invoice>.
      IF <s_buffer_invoice> IS NOT ASSIGNED." Special case: record already in temporary update buffer
        READ TABLE mt_update_buffer_2 ASSIGNING <s_buffer_invoice> WITH  KEY companycode = <invoice_update>-companycode
                                                                                  fiscalyear = <invoice_update>-fiscalyear
                                                                                  accountingdocument = <invoice_update>-accountingdocument.

      ENDIF.

      IF <s_buffer_invoice> IS NOT ASSIGNED." Special case: record already in update buffer
        READ TABLE mt_update_buffer INTO ls_buffer_invoice WITH KEY companycode = <invoice_update>-companycode
                                                                    fiscalyear = <invoice_update>-fiscalyear
                                                                    accountingdocument = <invoice_update>-accountingdocument.
        IF sy-subrc = 0.
          INSERT ls_buffer_invoice INTO TABLE mt_update_buffer_2 ASSIGNING <s_buffer_invoice>.
        ENDIF.
      ENDIF.

      IF <s_buffer_invoice> IS NOT ASSIGNED." Usual case: record not already in update buffer
        READ TABLE lt_invoice ASSIGNING FIELD-SYMBOL(<s_invoice_old>) WITH KEY companycode = <invoice_update>-companycode
                                                                              fiscalyear = <invoice_update>-fiscalyear
                                                                              accountingdocument = <invoice_update>-accountingdocument.
        IF sy-subrc = 0.
          INSERT <s_invoice_old> INTO TABLE mt_update_buffer_2 ASSIGNING <s_buffer_invoice>.
          ASSERT sy-subrc = 0.
        ENDIF.
      ENDIF.

      " Merge fields to be updated
      READ TABLE it_invoicex ASSIGNING FIELD-SYMBOL(<s_invoicex>) WITH KEY companycode = <invoice_update>-companycode
                                                                              fiscalyear = <invoice_update>-fiscalyear
                                                                              accountingdocument = <invoice_update>-accountingdocument.

      IF sy-subrc <> 0.
        APPEND NEW zzcx_fi_001( textid = zzcx_fi_001=>invoice_no_control
                                companycode = <invoice_update>-companycode
                                fiscalyear = <invoice_update>-fiscalyear
                                accountingdocument =  <invoice_update>-accountingdocument
                                  ) TO et_messages.
        RETURN.
      ENDIF.
*      DATA lv_field TYPE i.
*      lv_field = 1.
*      DO.
*        ASSIGN COMPONENT lv_field OF STRUCTURE <s_invoicex>-_intx TO FIELD-SYMBOL(<v_flag>).
*        IF sy-subrc <> 0.
*          EXIT.
*        ENDIF.
*        IF <v_flag> = abap_true.
*          ASSIGN COMPONENT lv_field + lcl_invoice_addition_buffer=>number_of_readonly_fields OF STRUCTURE <invoice_update> TO FIELD-SYMBOL(<v_field_new>).
*          ASSERT sy-subrc = 0.
*          ASSIGN COMPONENT lv_field + lcl_invoice_addition_buffer=>number_of_readonly_fields OF STRUCTURE <s_buffer_invoice> TO FIELD-SYMBOL(<v_field_old>).
*          ASSERT sy-subrc = 0.
*          <v_field_old> = <v_field_new>.
*        ENDIF.
*        lv_field = lv_field + 1.
*      ENDDO.
      DATA struc_ref TYPE REF TO cl_abap_structdescr.
      struc_ref ?= cl_abap_structdescr=>describe_by_data( <s_invoicex>-_intx ).
      DATA(intx_fields) = struc_ref->get_components(  ).
      LOOP AT intx_fields ASSIGNING FIELD-SYMBOL(<fieldname>).
        ASSIGN COMPONENT <fieldname>-name OF STRUCTURE <s_invoicex>-_intx TO FIELD-SYMBOL(<v_flag>).
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.
        IF <v_flag> = abap_true.
          ASSIGN COMPONENT <fieldname>-name OF STRUCTURE <invoice_update> TO FIELD-SYMBOL(<v_field_new>).
          ASSERT sy-subrc = 0.
          ASSIGN COMPONENT <fieldname>-name OF STRUCTURE <s_buffer_invoice> TO FIELD-SYMBOL(<v_field_old>).
          ASSERT sy-subrc = 0.
          <v_field_old> = <v_field_new>.
        ENDIF.
      ENDLOOP.
      IF <S_INVOICEX>-_INTX-STATUS = 'X'.
      ELSE.
        <s_buffer_invoice>-status = lcl_invoice_addition_buffer=>invoice_status-confirmed.
      ENDIF.
      GET TIME STAMP FIELD <s_buffer_invoice>-locallastchangedat .
      GET TIME STAMP FIELD <s_buffer_invoice>-lastchangedat.
      <s_buffer_invoice>-lastchangedby = sy-uname.

*    LOOP AT lt_zfi008 ASSIGNING  FIELD-SYMBOL(<fs_zfi008>).
      DATA lv_num_3 TYPE n LENGTH 3.
      CLEAR lv_num_3.
      IF   <s_buffer_invoice>-invoicenumber IS INITIAL and <s_buffer_invoice>-Status <> '30'.
        "先生成发票编号
**********************获取编号
        DATA(lo_numberrangebuf) = cl_numberrange_buffer=>get_instance( ).
        TRY.
            lo_numberrangebuf->if_numberrange_buffer~number_get_main_memory(
              EXPORTING
                  iv_object = 'ZZNR002' " 编号范围对象名称，需要在系统中配置好
                  iv_interval = CONV if_numberrange_buffer=>nr_interval( <s_buffer_invoice>-companycode+2(2) ) " 转换为所需的间隔类型
                  iv_toyear = <s_buffer_invoice>-fiscalyear " 传递年份
                  iv_quantity =  1 " 要获取的编号数量
              IMPORTING
                  ev_number = DATA(lv_number) " 获取的编号存储在 lv_number 中
            ).
            lv_num_3 = lv_number. " 将获取的编号赋值给 lv_num_3
          CATCH cx_number_ranges.
            "handle exceptio
            APPEND NEW zzcx_fi_001( textid = zzcx_fi_001=>invoice_no_number_range
                        companycode = <s_buffer_invoice>-companycode
                        fiscalyear = <s_buffer_invoice>-fiscalyear
                        accountingdocument =  <s_buffer_invoice>-accountingdocument
                          ) TO et_messages.
*            RETURN.
            CONTINUE.
            lv_num_3 = 000. " 发生异常时，将 lv_num_3 赋值为 000

        ENDTRY.

        <s_buffer_invoice>-invoicenumber = condense(
              val = |{ <s_buffer_invoice>-fiscalyear }{ lv_num_3 } |
              to = ``
        ).

      ENDIF.
*    ENDLOOP.


      INSERT <s_buffer_invoice> INTO TABLE et_invoice.
    ENDLOOP.

  ENDMETHOD.

  METHOD cud_copy.

    LOOP AT mt_update_buffer_2 ASSIGNING FIELD-SYMBOL(<s_update_buffer_2>).
      READ TABLE mt_update_buffer ASSIGNING FIELD-SYMBOL(<s_update_buffer>) WITH KEY companycode = <s_update_buffer_2>-companycode
                                                                              fiscalyear = <s_update_buffer_2>-fiscalyear
                                                                              accountingdocument = <s_update_buffer_2>-accountingdocument.
      IF sy-subrc <> 0.
        INSERT CORRESPONDING #( <s_update_buffer_2> ) INTO TABLE mt_update_buffer ASSIGNING <s_update_buffer>.
      ENDIF.
*      <s_update_buffer>-gr_data  = <s_update_buffer_2>-gr_data.
*      <s_update_buffer>-gr_admin = <s_update_buffer_2>-gr_admin.
    ENDLOOP.

    CLEAR: mt_create_buffer_2, mt_update_buffer_2, mt_delete_buffer_2.
  ENDMETHOD.

  METHOD _updatejournalentry.
************更新凭证行将invoice number回写至会计凭证行项目分配字段上：assignmentreference，

    DATA: lt_je  TYPE TABLE FOR ACTION IMPORT i_journalentrytp~change,
          lv_cid TYPE abp_behv_cid.
    LOOP AT it_invoice ASSIGNING FIELD-SYMBOL(<invoice>).

      TRY.
          lv_cid = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
        CATCH cx_uuid_error.
          ASSERT 1 = 0.
      ENDTRY.
      APPEND INITIAL LINE TO lt_je ASSIGNING FIELD-SYMBOL(<je>).

* Header Control
*      DATA ls_header_control LIKE <je>-%param-%control.
*        ls_header_control-documentheadertext = if_abap_behv=>mk-on.
*      ls_header_control-documentreferenceid = if_abap_behv=>mk-on.


* GL Item Control
*      DATA lt_glitem LIKE <je>-%param-_glitems.
*      DATA ls_glitem TYPE STRUCTURE FOR ac
*      DATA ls_glitem_control LIKE ls_glitem-%control.
*        ls_glitem_control-glaccountlineitem = if_abap_behv=>mk-on.
*       ls_glitem_control-documentitemtext = if_abap_behv=>mk-on.
*      ls_glitem_control-assignmentreference = if_abap_behv=>mk-on.
*        ls_glitem_control-statecentralbankpaymentreason = if_abap_behv=>mk-on.
*        ls_glitem_control-supplyingcountry = if_abap_behv=>mk-on.

* APAR Item Control
*      DATA lt_aparitem LIKE <je>-%param-_aparitems.
*      DATA ls_aparitem LIKE LINE OF lt_aparitem.
*      DATA ls_aparitem_control LIKE ls_aparitem-%control.
*        ls_aparitem_control-glaccountlineitem = if_abap_behv=>mk-on.
*        ls_aparitem_control-documentitemtext = if_abap_behv=>mk-on.
*      ls_aparitem_control-assignmentreference = if_abap_behv=>mk-on.
*        ls_aparitem_control-specialglaccountassignment = if_abap_behv=>mk-on.
      SELECT companycode,
             fiscalyear,
             accountingdocument,
             AccountingDocumentItem,
             financialaccounttype
             FROM i_journalentryitem WITH PRIVILEGED ACCESS
             WHERE companycode = @<invoice>-companycode
               AND fiscalyear = @<invoice>-fiscalyear
               AND accountingdocument = @<invoice>-accountingdocument
               INTO TABLE @DATA(journal_entry_items).


* Test Data
      <je>-accountingdocument = <invoice>-accountingdocument.
      <je>-fiscalyear = <invoice>-fiscalyear.
      <je>-companycode = <invoice>-companycode.
*      <je>-%cid_ref = lv_cid.

      <je>-%param = VALUE #(
        documentreferenceid = <invoice>-invoicenumber
        %control = VALUE #(
            documentreferenceid = if_abap_behv=>mk-on
        )
        _aparitems = VALUE #(
            FOR aparitem IN journal_entry_items WHERE ( financialaccounttype = 'K' OR financialaccounttype = 'D' ) (
                glaccountlineitem = aparitem-AccountingDocumentItem
                assignmentreference = <invoice>-invoicenumber
                %control = VALUE #(
                    glaccountlineitem = if_abap_behv=>mk-on
                    assignmentreference = if_abap_behv=>mk-on
                )
            )
        )
        _glitems = VALUE #(
            FOR aparitem IN journal_entry_items WHERE ( financialaccounttype = 'S' ) (
                glaccountlineitem = aparitem-AccountingDocumentItem
                assignmentreference = <invoice>-invoicenumber
                %control = VALUE #(
                    glaccountlineitem = if_abap_behv=>mk-on
                    assignmentreference = if_abap_behv=>mk-on
                )
            )
        )
      ).


*      <je>-%param = VALUE #(
**         documentheadertext = 'TEST by 20220216'
*        documentreferenceid = <fs_zfi008>-invoicenumber
*       %control = ls_header_control
*       _glitems = VALUE #( (
**          glaccountlineitem = '000002'
**         documentitemtext = 'GL Item test 1400000959-2'
*       assignmentreference = <fs_zfi008>-invoicenumber
**         statecentralbankpaymentreason = '017'
**         supplyingcountry = 'CN'
*       %control = ls_glitem_control )
*       )
*       _aparitems = VALUE #( (
**         glaccountlineitem = '000001'
**         documentitemtext = 'APAR Item te0959-4'
*       assignmentreference = <fs_zfi008>-invoicenumber
**         specialglaccountassignment = '123'
*       %control = ls_aparitem_control
*       )
*       )

*      ) .
    ENDLOOP.

    IF lines( lt_je ) > 0.
      MODIFY ENTITIES OF i_journalentrytp
        ENTITY journalentry
        EXECUTE change FROM lt_je
        FAILED DATA(ls_failed_deep)
        REPORTED DATA(ls_reported_deep)
        MAPPED DATA(ls_mapped_deep).
      LOOP AT ls_reported_deep-journalentry ASSIGNING FIELD-SYMBOL(<journalentry_error>).
        APPEND NEW zzcx_fi_001( textid = <journalentry_error>-%msg->if_t100_message~t100key
            companycode = <journalentry_error>-companycode
            fiscalyear = <journalentry_error>-fiscalyear
            accountingdocument =  <journalentry_error>-accountingdocument
              ) TO et_messages.
      ENDLOOP.


    ENDIF.
  ENDMETHOD.

  METHOD store_email_instance.
    INSERT io_mail INTO TABLE mt_mail.
  ENDMETHOD.

  METHOD send_email.
    LOOP AT mt_mail ASSIGNING FIELD-SYMBOL(<mail>).
      TRY.
          <mail>->send(  ).
        CATCH cx_bcs_mail INTO DATA(lx_mail).
        append lx_mail to et_messages.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
