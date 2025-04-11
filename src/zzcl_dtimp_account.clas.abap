CLASS zzcl_dtimp_account DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zzif_process_data .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZZCL_DTIMP_ACCOUNT IMPLEMENTATION.


  METHOD zzif_process_data~process.
        CREATE DATA eo_data TYPE HANDLE io_data_handle.
        DATA LS_INPUT TYPE STRUCTURE FOR CREATE zr_tfi004\\ZrTfi004.
        DATA LT_INPUT TYPE TABLE FOR CREATE zr_tfi004\\ZrTfi004.
        DATA:ls_msg TYPE LINE OF zzt_dmp_data_list.
        DATA L_COUNT TYPE I.
        eo_data->* = io_data->*.
        LOOP AT io_data->* ASSIGNING FIELD-SYMBOL(<fs_data>).
          L_COUNT = L_COUNT + 1.
          ASSIGN COMPONENT 'TYPE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<FS_TYPE>).
          ASSIGN COMPONENT 'BO_LEN' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<FS_BOLEN>).
*          select domain_name,value_low
*            from zr_sfi004
*             where domain_name = 'ZZDFI020'
*            into TABLE @data(lt_ZZDFI020).
*          read table lt_zzdfi020 ASSIGNING FIELD-SYMBOL(<fs_ZZDFI020>)
*                                                       WITH KEY value_low = <FS_TYPE>.
*          if sy-subrc <> 0.
*          ls_msg =  VALUE #( line = L_COUNT
*                              message_list = VALUE #(
*                               ( id = 'SY'
*                                number = '115'
*                                type =  'E'
*                                MESSAGE_V1 = 'TYPE' ) )
*            ).
*            APPEND LS_MSG TO et_message.
*          endif.
          ASSIGN COMPONENT 'CREDIT' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<FS_CREDIT>).
          ASSIGN COMPONENT 'CASH_FLOW' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<FS_CASH_FLOW>).
          ASSIGN COMPONENT 'CASH_FLOW_CODE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<FS_CASH_FLOW_CODE>).
          ASSIGN COMPONENT 'CURRENCY' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<FS_CURRENCY>).
          ASSIGN COMPONENT 'DEBIT' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<FS_DEBIT>).
          LS_INPUT = VALUE #(
          %cid = <FS_TYPE> && <FS_BOLEN> && <FS_CREDIT> && <FS_DEBIT>
          %data = VALUE #(
                              TYPE = <FS_TYPE>
                              BOLEN = <FS_BOLEN>
                              CREDIT = <FS_CREDIT>
                              CASHFLOW = <FS_CASH_FLOW>
                              CASHFLOWCODE = <FS_CASH_FLOW_CODE>
                              CURRENCY = <FS_CURRENCY>
                              DEBIT = <FS_DEBIT>
                              )
                       %control =  VALUE #(
                               TYPE = if_abap_behv=>mk-on
                              BOLEN = if_abap_behv=>mk-on
                              CREDIT = if_abap_behv=>mk-on
                              CASHFLOW = if_abap_behv=>mk-on
                              CASHFLOWCODE = if_abap_behv=>mk-on
                              CURRENCY = if_abap_behv=>mk-on
                              DEBIT = if_abap_behv=>mk-on
                       )
          ).
          APPEND LS_INPUT TO LT_INPUT.
        ENDLOOP.
        MODIFY ENTITIES OF zr_tfi004
        ENTITY ZrTfi004
        CREATE FIELDS ( TYPE
                        BOLEN
                        CASHFLOW
                        CASHFLOWCODE
                        CURRENCY
                        DEBIT
                        CREDIT )
        WITH LT_INPUT
                            MAPPED DATA(mapped)
                            REPORTED DATA(reported)
                            FAILED DATA(failed).
        COMMIT ENTITIES  RESPONSES
                FAILED DATA(failed_commit)
        REPORTED DATA(reported_commit).
   IF reported_commit[] IS INITIAL.
    ls_msg =  VALUE #(        line = 4
                               message_list = VALUE #(  (
                                id = 'SY'
                                type =  'S'
                                MESSAGE = '导入成功！'
                               )  )
      ).
   ELSE.
    LOOP AT reported_commit ASSIGNING FIELD-SYMBOL(<fs_failed>).
      ls_msg =  VALUE #( line = sy-tabix
                              message_list = VALUE #(  (
                                id = 'SY'
                                number = '530'
                                type =  'S'
                               )
                               ( id = 'ZZFI'
                                 number = '003'
                                 type = 'E' )   )

      ).
      APPEND ls_msg TO et_message.
    ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
