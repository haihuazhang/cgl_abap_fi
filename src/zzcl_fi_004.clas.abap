CLASS zzcl_fi_004 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES : tt_if_t100_message TYPE STANDARD TABLE OF REF TO if_t100_message WITH EMPTY KEY,
            BEGIN OF ts_invoice_key,
              companycode        TYPE bukrs,
              fiscalyear         TYPE gjahr,
              accountingdocument TYPE belnr_d,
            END OF ts_invoice_key,
            tt_invoice_key TYPE STANDARD TABLE OF ts_invoice_key WITH DEFAULT KEY,
            message_t      TYPE STANDARD TABLE OF symsg WITH DEFAULT KEY,
            BEGIN OF message_with_key,
              companycode        TYPE bukrs,
              fiscalyear         TYPE gjahr,
              accountingdocument TYPE belnr_d,
              messages           TYPE message_t,
            END OF message_with_key,
            tt_message_with_key TYPE STANDARD TABLE OF message_with_key WITH DEFAULT KEY,
*            BEGIN OF ts_invoice_intx,
*              bankname       TYPE xsdboolean,
*              housebank      TYPE xsdboolean,
*              swift          TYPE xsdboolean,
*              iban           TYPE xsdboolean,
*              bankkey        TYPE xsdboolean,
*              accountid      TYPE xsdboolean,
*              bankaccount    TYPE xsdboolean,
*              invoicenumber  TYPE xsdboolean,
*              constantsymbol TYPE xsdboolean,
*              status         TYPE xsdboolean,
*            END OF ts_invoice_intx,
            BEGIN OF ts_invoice_inx,
              companycode        TYPE bukrs,
              fiscalyear         TYPE gjahr,
              accountingdocument TYPE belnr_d,
              _intx              TYPE zzsfi002,
            END OF ts_invoice_inx.


    CLASS-METHODS:     get_instance RETURNING VALUE(ro_instance) TYPE REF TO zzcl_fi_004.

    METHODS update_invoice IMPORTING is_invoice  TYPE zr_sfi038
                                     is_invoicex TYPE ts_invoice_inx
                           EXPORTING es_invoice  TYPE zr_sfi038
                                     et_messages TYPE tt_if_t100_message.

    METHODS get_invoice IMPORTING iv_invoice_key         TYPE ts_invoice_key
                                  iv_include_buffer      TYPE abap_boolean
                                  iv_include_temp_buffer TYPE abap_boolean OPTIONAL
                        EXPORTING es_invoice             TYPE zr_sfi038
                                  et_messages            TYPE tt_if_t100_message.
    METHODS save EXPORTING et_messages        TYPE tt_if_t100_message.
    METHODS initialize.
    METHODS convert_messages IMPORTING it_messages TYPE tt_if_t100_message
                             EXPORTING et_messages TYPE message_t.
    METHODS convert_messages_with_key IMPORTING it_messages TYPE tt_if_t100_message
                                      EXPORTING et_messages TYPE tt_message_with_key.

    METHODS store_email_instance IMPORTING io_mail TYPE REF TO cl_bcs_mail_message.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA go_instance TYPE REF TO zzcl_fi_004.
    METHODS lock_invoice IMPORTING iv_lock TYPE abap_boolean
                         RAISING   zzcx_fi_001 ##RELAX ##NEEDED.
    METHODS _resolve_attribute IMPORTING iv_attrname      TYPE scx_attrname
                                         ix               TYPE REF TO zzcx_fi_001
                               RETURNING VALUE(rv_symsgv) TYPE symsgv.
ENDCLASS.



CLASS ZZCL_FI_004 IMPLEMENTATION.


  METHOD convert_messages.
    CLEAR et_messages.
    DATA ls_message TYPE symsg.
    LOOP AT it_messages INTO DATA(lr_error) ##INTO_OK.
      ls_message-msgty = 'E'.
      ls_message-msgid = lr_error->t100key-msgid.
      ls_message-msgno = lr_error->t100key-msgno.
      IF lr_error IS INSTANCE OF zzcx_fi_001.
        DATA(lx) = CAST zzcx_fi_001( lr_error ).
        ls_message-msgv1 = _resolve_attribute( iv_attrname = lr_error->t100key-attr1  ix = lx ).
        ls_message-msgv2 = _resolve_attribute( iv_attrname = lr_error->t100key-attr2  ix = lx ).
        ls_message-msgv3 = _resolve_attribute( iv_attrname = lr_error->t100key-attr3  ix = lx ).
        ls_message-msgv4 = _resolve_attribute( iv_attrname = lr_error->t100key-attr4  ix = lx ).
      ENDIF.
      APPEND ls_message TO et_messages.
    ENDLOOP.
  ENDMETHOD.


  METHOD convert_messages_with_key.
    CLEAR et_messages.
    DATA ls_message TYPE symsg.
    LOOP AT it_messages INTO DATA(lr_error) ##INTO_OK.
      ls_message-msgty = 'E'.
      ls_message-msgid = lr_error->t100key-msgid.
      ls_message-msgno = lr_error->t100key-msgno.
      IF lr_error IS INSTANCE OF zzcx_fi_001.
        DATA(lx) = CAST zzcx_fi_001( lr_error ).
        ls_message-msgv1 = _resolve_attribute( iv_attrname = lr_error->t100key-attr1  ix = lx ).
        ls_message-msgv2 = _resolve_attribute( iv_attrname = lr_error->t100key-attr2  ix = lx ).
        ls_message-msgv3 = _resolve_attribute( iv_attrname = lr_error->t100key-attr3  ix = lx ).
        ls_message-msgv4 = _resolve_attribute( iv_attrname = lr_error->t100key-attr4  ix = lx ).

*        DATA(accountingdocument) = lx->accountingdocument.
        READ TABLE et_messages INTO DATA(message_with_key) WITH KEY companycode = lx->companycode
                                                               fiscalyear = lx->fiscalyear
                                                               accountingdocument = lx->fiscalyear.
        IF sy-subrc = 0.
          APPEND ls_message TO message_with_key-messages.
        ELSE.
          message_with_key = VALUE #(
              companycode = lx->companycode
              fiscalyear = lx->fiscalyear
              accountingdocument = lx->accountingdocument
              messages = VALUE #( ( ls_message ) )
          ).
          APPEND message_with_key TO et_messages.
        ENDIF.

      ELSE.
        message_with_key = VALUE #(
            companycode = ''
            fiscalyear = ''
            accountingdocument = ''
            messages = VALUE #( ( ls_message ) )
        ).
        APPEND message_with_key TO et_messages.
      ENDIF.
*      APPEND ls_message TO et_messages.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_instance.
    go_instance = COND #( WHEN go_instance IS BOUND THEN go_instance ELSE NEW #( ) ).
    ro_instance = go_instance.
  ENDMETHOD.


  METHOD get_invoice.
    CLEAR: es_invoice,  et_messages.

    IF iv_invoice_key IS INITIAL.
      APPEND NEW zzcx_fi_001( textid = zzcx_fi_001=>invoice_no_key ) TO et_messages.
      RETURN.
    ENDIF.

    lcl_invoice_addition_buffer=>get_instance( )->get( EXPORTING it_invoice = VALUE #(
                                                                                        (
                                                                                           companycode = iv_invoice_key-companycode
                                                                                           fiscalyear = iv_invoice_key-fiscalyear
                                                                                           accountingdocument = iv_invoice_key-accountingdocument
                                                                                        )
                                                                                     )
                                                       iv_include_buffer      = iv_include_buffer
                                                       iv_include_temp_buffer = iv_include_temp_buffer
                                             IMPORTING et_invoice              = DATA(lt_invoice) ).
    IF lt_invoice IS INITIAL.
      APPEND NEW zzcx_fi_001( textid = zzcx_fi_001=>invoice_unknown
                              companycode = iv_invoice_key-companycode
                              fiscalyear = iv_invoice_key-fiscalyear
                              accountingdocument = iv_invoice_key-accountingdocument  ) TO et_messages.
      RETURN.
    ENDIF.
    ASSERT lines( lt_invoice ) = 1.
    es_invoice = lt_invoice[ 1 ].

  ENDMETHOD.


  METHOD initialize.
    lcl_invoice_addition_buffer=>get_instance(  )->initialize(  ).
  ENDMETHOD.


  METHOD lock_invoice.

  ENDMETHOD.


  METHOD save.
    lcl_invoice_addition_buffer=>get_instance(  )->save(
        IMPORTING
            et_messages = et_messages
     ).
    "If Action SendMail triggered
    lcl_invoice_addition_buffer=>get_instance(  )->send_email(
       IMPORTING
           et_messages = et_messages
    ).
    initialize(  ).
  ENDMETHOD.


  METHOD store_email_instance.
    lcl_invoice_addition_buffer=>get_instance(  )->store_email_instance(
        io_mail = io_mail
     ).
  ENDMETHOD.


  METHOD update_invoice.
    CLEAR es_invoice.
    CLEAR et_messages.

    IF is_invoice-accountingdocument IS INITIAL.
      APPEND NEW zzcx_fi_001( textid = zzcx_fi_001=>invoice_no_key ) TO et_messages.
      RETURN.
    ENDIF.

    lcl_invoice_addition_buffer=>get_instance(  )->cud_prep(
        EXPORTING
            it_invoice = VALUE #( (  is_invoice ) )
            it_invoicex = VALUE #( ( CORRESPONDING #( is_invoicex ) ) )
        IMPORTING et_invoice   = DATA(lt_invoice)
                  et_messages = et_messages
    ).

    IF et_messages IS INITIAL.
      ASSERT lines( lt_invoice ) = 1.
      " Now do any derivations that require the whole business object (not only a single node), but which may in principle result in an error
      " The derivation may need the complete Business Object, i.e. including unchanged subnodes
      get_invoice( EXPORTING iv_invoice_key        = VALUE #(
                                                    companycode = lt_invoice[ 1 ]-companycode
                                                    fiscalyear = lt_invoice[ 1 ]-fiscalyear
                                                    accountingdocument = lt_invoice[ 1 ]-accountingdocument
                                                   )
                            iv_include_buffer      = abap_true
                            iv_include_temp_buffer = abap_true
                  IMPORTING es_invoice              = es_invoice
                            et_messages            = et_messages ).
    ENDIF.


    IF et_messages IS INITIAL.
      lcl_invoice_addition_buffer=>get_instance( )->cud_copy( ).
    ELSE.
      CLEAR: es_invoice.
      lcl_invoice_addition_buffer=>get_instance( )->cud_disc( ).

    ENDIF.

  ENDMETHOD.


  METHOD _resolve_attribute.
    CLEAR rv_symsgv.
    CASE iv_attrname.
      WHEN ''.
        rv_symsgv = ''.
      WHEN 'KEY'.
        rv_symsgv = |{ ix->key ALPHA = OUT }|.
      WHEN 'COMPANYCODE'.
        rv_symsgv = |{ ix->companycode ALPHA = OUT }|.
      WHEN 'FISCALYEAR'.
        rv_symsgv = |{ ix->fiscalyear ALPHA = OUT }|.
      WHEN 'ACCOUNTINGDOCUMENT'.
        rv_symsgv = |{ ix->accountingdocument ALPHA = OUT }|.

*      WHEN 'MV_TRAVEL_ID'.
*        rv_symsgv = |{ ix->mv_travel_id ALPHA = OUT }|.
*      WHEN 'MV_BOOKING_ID'.
*        rv_symsgv = |{ ix->mv_booking_id ALPHA = OUT }|.
      WHEN OTHERS.
*        ASSERT 1 = 2.
        rv_symsgv = iv_attrname.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
