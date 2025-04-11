CLASS zzcl_fi_002 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS get_detail IMPORTING io_request  TYPE REF TO if_rap_query_request
                                 io_response TYPE REF TO if_rap_query_response.
    METHODS get_summary IMPORTING io_request  TYPE REF TO if_rap_query_request
                                  io_response TYPE REF TO if_rap_query_response.
    CLASS-DATA g_result TYPE cl_exchange_rates=>ty_messages.
    DATA:r_company TYPE RANGE OF bukrs.
    DATA: r_date TYPE RANGE OF zzefi006.

ENDCLASS.



CLASS ZZCL_FI_002 IMPLEMENTATION.


  METHOD get_detail.
    TRY.
        DATA(lt_ranges) = io_request->get_filter(  )->get_as_ranges(  ).
      CATCH cx_rap_query_filter_no_range.
        "handle exception
        APPEND VALUE #( type = 'E' message = 'filter_no_range' ) TO g_result.
    ENDTRY.
    LOOP AT lt_ranges ASSIGNING FIELD-SYMBOL(<fs_ranges>).
      TRANSLATE <fs_ranges>-name TO UPPER CASE.
      IF <fs_ranges>-name = 'COMPANYCODE'.
        r_company[] = CORRESPONDING #( <fs_ranges>-range  ).
      ENDIF.
      IF <fs_ranges>-name = 'REPORTDATE'.
        r_date[] = CORRESPONDING #( <fs_ranges>-range  ).
      ENDIF.
    ENDLOOP.
    READ TABLE  r_date INTO DATA(ls_date) INDEX 1.
    IF sy-subrc = 0.
      DATA(lv_date) = ls_date-low.
    ENDIF.

    DATA: lt_entity  TYPE TABLE OF zr_sfi024,
          lwa_entity TYPE zr_sfi024.
    SELECT zr_sfi008~uuid,
          zr_tfi001~Lendercompany,
          zr_tfi001~Borrowercompany,
          zr_sfi008~CurrencyEUR,
          zr_sfi008~PrincipalBalanceEUR,
          zr_sfi008~InterestBalanceEUR
    FROM zr_sfi008( p_date = @lv_date )
    JOIN zr_tfi001 ON zr_tfi001~uuid = zr_sfi008~uuid
    INTO TABLE @DATA(lt_sfi018).
    LOOP AT lt_sfi018 ASSIGNING FIELD-SYMBOL(<fs_sfi018>).
      lwa_entity-CompanyCode = <fs_sfi018>-Lendercompany.
      SELECT SINGLE CompanyName
      FROM I_Globalcompany
      WHERE Company = @<fs_sfi018>-Lendercompany
      INTO @lwa_entity-CompanyName.
      lwa_entity-reportdate = lv_date.
      lwa_entity-counterparty = <fs_sfi018>-Borrowercompany.
      SELECT SINGLE CompanyName
      FROM I_Globalcompany
      WHERE Company = @<fs_sfi018>-Borrowercompany
      INTO @lwa_entity-CounterpartyName.
      lwa_entity-CurrencyEUR = <fs_sfi018>-CurrencyEUR.
      lwa_entity-com_cou = <fs_sfi018>-Lendercompany && <fs_sfi018>-Borrowercompany.
      lwa_entity-PrincipalBalanceEUR_lender = <fs_sfi018>-PrincipalBalanceEUR.
      lwa_entity-interestbalanceEUR_lender = <fs_sfi018>-InterestBalanceEUR.
      lwa_entity-PrincipalBalanceEUR_sum = lwa_entity-PrincipalBalanceEUR_lender.
      lwa_entity-InterestBalanceEUR_sum = lwa_entity-interestbalanceEUR_lender.
      lwa_entity-Navigation = 'Show detail'.
      COLLECT lwa_entity INTO lt_entity.
      CLEAR lwa_entity.
      lwa_entity-CompanyCode = <fs_sfi018>-Borrowercompany.
      SELECT SINGLE CompanyName
      FROM I_Globalcompany
      WHERE Company = @<fs_sfi018>-Borrowercompany
      INTO @lwa_entity-CompanyName.
      lwa_entity-reportdate = lv_date.
      lwa_entity-counterparty = <fs_sfi018>-Lendercompany.
      SELECT SINGLE CompanyName
      FROM I_Globalcompany
      WHERE Company = @<fs_sfi018>-Lendercompany
      INTO @lwa_entity-CounterpartyName.
      lwa_entity-com_cou = <fs_sfi018>-Borrowercompany && <fs_sfi018>-Lendercompany.
      lwa_entity-CurrencyEUR = <fs_sfi018>-CurrencyEUR.
      lwa_entity-PrincipalBalanceEUR_Borrower = <fs_sfi018>-PrincipalBalanceEUR.
      lwa_entity-interestbalanceEUR_Borrower = <fs_sfi018>-InterestBalanceEUR.
      lwa_entity-PrincipalBalanceEUR_sum = -1 * lwa_entity-PrincipalBalanceEUR_Borrower.
      lwa_entity-InterestBalanceEUR_sum = -1 * lwa_entity-interestbalanceEUR_Borrower.
      lwa_entity-Navigation = 'Show detail'.
      COLLECT lwa_entity INTO lt_entity.
      CLEAR lwa_entity.
    ENDLOOP.
    zzcl_odata_utils=>filtering( EXPORTING io_filter = io_request->get_filter(  ) CHANGING ct_data = lt_entity ).

    IF io_request->is_total_numb_of_rec_requested(  ) .
      io_response->set_total_number_of_records( lines( lt_entity ) ).
    ENDIF.

    zzcl_odata_utils=>orderby( EXPORTING it_order = io_request->get_sort_elements( )  CHANGING ct_data = lt_entity ).

    zzcl_odata_utils=>paging( EXPORTING io_paging = io_request->get_paging(  ) CHANGING ct_data = lt_entity ).

    io_response->set_data( lt_entity ).
  ENDMETHOD.


  METHOD get_summary.
    TRY.
        DATA(lt_ranges) = io_request->get_filter(  )->get_as_ranges(  ).
      CATCH cx_rap_query_filter_no_range.
        "handle exception
        APPEND VALUE #( type = 'E' message = 'filter_no_range' ) TO g_result.
    ENDTRY.
    LOOP AT lt_ranges ASSIGNING FIELD-SYMBOL(<fs_ranges>).
      TRANSLATE <fs_ranges>-name TO UPPER CASE.
      IF <fs_ranges>-name = 'COMPANYCODE'.
        r_company[] = CORRESPONDING #( <fs_ranges>-range  ).
      ENDIF.
      IF <fs_ranges>-name = 'REPORTDATE'.
        r_date[] = CORRESPONDING #( <fs_ranges>-range  ).
      ENDIF.
    ENDLOOP.
    READ TABLE  r_date INTO DATA(ls_date) INDEX 1.
    IF sy-subrc = 0.
      DATA(lv_date) = ls_date-low.
    ENDIF.
    DATA: lt_detail TYPE TABLE OF zr_sfi024,
          ls_detail TYPE zr_sfi024.
    DATA: lt_entity  TYPE TABLE OF zr_sfi025,
          lwa_entity TYPE zr_sfi025.
    SELECT zr_sfi008~uuid,
          zr_tfi001~Lendercompany,
          zr_tfi001~Borrowercompany,
          zr_sfi008~CurrencyEUR,
          zr_sfi008~PrincipalBalanceEUR,
          zr_sfi008~InterestBalanceEUR
    FROM zr_sfi008( p_date = @lv_date )
    JOIN zr_tfi001 ON zr_tfi001~uuid = zr_sfi008~uuid
    INTO TABLE @DATA(lt_sfi018).
    LOOP AT lt_sfi018 ASSIGNING FIELD-SYMBOL(<fs_sfi018>).
      ls_detail-CompanyCode = <fs_sfi018>-Lendercompany.
      SELECT SINGLE CompanyName
     FROM I_Globalcompany
     WHERE Company = @<fs_sfi018>-Lendercompany
     INTO @ls_detail-CompanyName.
      ls_detail-reportdate = lv_date.
      ls_detail-counterparty = <fs_sfi018>-Borrowercompany.
      SELECT SINGLE CompanyName
     FROM I_Globalcompany
     WHERE Company = @<fs_sfi018>-Borrowercompany
     INTO @ls_detail-CounterpartyName.
      ls_detail-CurrencyEUR = <fs_sfi018>-CurrencyEUR.
      ls_detail-PrincipalBalanceEUR_lender = <fs_sfi018>-PrincipalBalanceEUR.
      ls_detail-interestbalanceEUR_lender = <fs_sfi018>-InterestBalanceEUR.
      ls_detail-PrincipalBalanceEUR_sum = ls_detail-PrincipalBalanceEUR_lender.
      ls_detail-InterestBalanceEUR_sum = ls_detail-interestbalanceEUR_lender.
      APPEND ls_detail TO lt_detail.
      CLEAR ls_detail.
      ls_detail-CompanyCode = <fs_sfi018>-Borrowercompany.
      SELECT SINGLE CompanyName
      FROM I_Globalcompany
      WHERE Company = @<fs_sfi018>-Borrowercompany
      INTO @ls_detail-CompanyName.
      ls_detail-reportdate = lv_date.
      ls_detail-counterparty = <fs_sfi018>-Lendercompany.
      SELECT SINGLE CompanyName
      FROM I_Globalcompany
      WHERE Company = @<fs_sfi018>-Lendercompany
      INTO @ls_detail-CounterpartyName.
      ls_detail-CurrencyEUR = <fs_sfi018>-CurrencyEUR.
      ls_detail-PrincipalBalanceEUR_Borrower = <fs_sfi018>-PrincipalBalanceEUR.
      ls_detail-interestbalanceEUR_Borrower = <fs_sfi018>-InterestBalanceEUR.
      ls_detail-PrincipalBalanceEUR_sum = -1 * ls_detail-PrincipalBalanceEUR_Borrower.
      ls_detail-InterestBalanceEUR_sum = -1 * ls_detail-interestbalanceEUR_Borrower.
      APPEND ls_detail TO lt_detail.
      CLEAR ls_detail.
    ENDLOOP.
    SORT lt_detail BY CompanyCode.
    LOOP AT lt_detail INTO ls_detail.
      lwa_entity = CORRESPONDING #( ls_detail ).
      COLLECT lwa_entity INTO lt_entity.
      CLEAR:ls_detail,lwa_entity.
    ENDLOOP.
    zzcl_odata_utils=>filtering( EXPORTING io_filter = io_request->get_filter(  ) CHANGING ct_data = lt_entity ).

    IF io_request->is_total_numb_of_rec_requested(  ) .
      io_response->set_total_number_of_records( lines( lt_entity ) ).
    ENDIF.

    zzcl_odata_utils=>orderby( EXPORTING it_order = io_request->get_sort_elements( )  CHANGING ct_data = lt_entity ).

    zzcl_odata_utils=>paging( EXPORTING io_paging = io_request->get_paging(  ) CHANGING ct_data = lt_entity ).

    io_response->set_data( lt_entity ).

  ENDMETHOD.


  METHOD if_rap_query_provider~select.
    DATA(i_entity) = io_request->get_entity_id( ).
    CASE i_entity.
      WHEN 'ZR_SFI024'.
        get_detail(
          EXPORTING
           io_request = io_request
           io_response = io_response ).
      WHEN 'ZR_SFI025'.
        get_summary(
          EXPORTING
           io_request = io_request
           io_response = io_response ).
      WHEN OTHERS.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
