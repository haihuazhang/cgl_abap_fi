CLASS zzcx_fi_001 DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_t100_message .
*    INTERFACES if_t100_dyn_msg .

    METHODS constructor
      IMPORTING
        !textid   LIKE if_t100_message=>t100key OPTIONAL
        !previous LIKE previous OPTIONAL
        key       TYPE string OPTIONAL
        companycode TYPE bukrs OPTIONAL
        fiscalyear TYPE gjahr OPTIONAL
        accountingdocument TYPE belnr_d OPTIONAL.


    DATA : key TYPE string,
           companycode TYPE bukrs,
           fiscalyear TYPE gjahr,
           accountingdocument TYPE belnr_d.

    CONSTANTS : BEGIN OF invoice_no_key,
                  msgid TYPE symsgid VALUE 'ZZFI',
                  msgno TYPE symsgno VALUE '006',
                  attr1 TYPE scx_attrname VALUE '',
                  attr2 TYPE scx_attrname VALUE '',
                  attr3 TYPE scx_attrname VALUE '',
                  attr4 TYPE scx_attrname VALUE '',
                END OF invoice_no_key,
                BEGIN OF invoice_unknown,
                  msgid TYPE symsgid VALUE 'ZZFI',
                  msgno TYPE symsgno VALUE '007',
                  attr1 TYPE scx_attrname VALUE 'COMPANYCODE',
                  attr2 TYPE scx_attrname VALUE 'FISCALYEAR',
                  attr3 TYPE scx_attrname VALUE 'ACCOUNTINGDOCUMENT',
                  attr4 TYPE scx_attrname VALUE '',
                END OF invoice_unknown,
                BEGIN OF invoice_no_control,
                  msgid TYPE symsgid VALUE 'ZZFI',
                  msgno TYPE symsgno VALUE '008',
                  attr1 TYPE scx_attrname VALUE 'COMPANYCODE',
                  attr2 TYPE scx_attrname VALUE 'FISCALYEAR',
                  attr3 TYPE scx_attrname VALUE 'ACCOUNTINGDOCUMENT',
                  attr4 TYPE scx_attrname VALUE '',
                END OF invoice_no_control,
                BEGIN OF invoice_no_number_range,
                  msgid TYPE symsgid VALUE 'ZZFI',
                  msgno TYPE symsgno VALUE '010',
                  attr1 TYPE scx_attrname VALUE 'COMPANYCODE',
                  attr2 TYPE scx_attrname VALUE 'FISCALYEAR',
                  attr3 TYPE scx_attrname VALUE 'ACCOUNTINGDOCUMENT',
                  attr4 TYPE scx_attrname VALUE '',
                END OF invoice_no_number_range.


protected SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZZCX_FI_001 IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    me->key = key.
    me->companycode = companycode.
    me->fiscalyear = fiscalyear.
    me->accountingdocument = accountingdocument.

    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
