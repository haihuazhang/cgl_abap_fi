CLASS lhc_zr_tfi004 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR ZrTfi004
        RESULT result,
      DuplicateCheck FOR VALIDATE ON SAVE
        IMPORTING keys FOR ZrTfi004~DuplicateCheck.
ENDCLASS.

CLASS lhc_zr_tfi004 IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD DuplicateCheck.
    READ ENTITIES OF zr_tfi004
    IN LOCAL MODE
    ENTITY ZrTfi004
    ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_ztfi004).
    IF lt_ztfi004[] IS NOT INITIAL.
      LOOP AT lt_ztfi004 ASSIGNING FIELD-SYMBOL(<fs_ztfi004>).
        SELECT COUNT( UUID ) FROM ztfi004
        WHERE type = @<fs_ztfi004>-type
          AND bo_len = @<fs_ztfi004>-BoLen
          and cash_flow = @<fs_ztfi004>-CashFlow
          and Currency = @<fs_ztfi004>-Currency
          INTO  @DATA(ls_fi004).
        IF ls_fi004 > 0.
          APPEND VALUE #( %tky = <fs_ztfi004>-%tky ) TO failed-ZrTfi004.
          APPEND VALUE #( %tky = <fs_ztfi004>-%tky
                          %msg = new_message(
                            id = '00'
                            number = 000
                            severity = if_abap_behv_message=>severity-error
                            v1 = '键值重复！' )
                            ) TO reported-ZrTfi004.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
