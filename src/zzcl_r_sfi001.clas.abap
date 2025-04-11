CLASS zzcl_r_sfi001 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS get_interest IMPORTING io_request  TYPE REF TO if_rap_query_request
                                   io_response TYPE REF TO if_rap_query_response.
    METHODS get_interest_item IMPORTING io_request  TYPE REF TO if_rap_query_request
                                        io_response TYPE REF TO if_rap_query_response.
    CLASS-DATA g_result TYPE cl_exchange_rates=>ty_messages.
ENDCLASS.



CLASS ZZCL_R_SFI001 IMPLEMENTATION.


  METHOD get_interest.

    TRY.
        DATA(lt_ranges) = io_request->get_filter(  )->get_as_ranges(  ).
      CATCH cx_rap_query_filter_no_range.
        "handle exception
        APPEND VALUE #( type = 'E' message = 'filter_no_range' ) TO g_result.
    ENDTRY.

    DATA : lr_companycode   TYPE RANGE OF bukrs,
           lr_reportingdate TYPE RANGE OF datum.
    DATA: lt_entity  TYPE TABLE OF zr_sfi017,
          lwa_entity TYPE zr_sfi017.

    LOOP AT lt_ranges ASSIGNING FIELD-SYMBOL(<fs_range>).
      TRANSLATE <fs_range>-name TO UPPER CASE.
      CASE <fs_range>-name.
        WHEN 'COMPANYCODE'.
          lr_companycode = CORRESPONDING #( <fs_range>-range ).
        WHEN 'REPORTINGDATE'.
          lR_REPORTINGDATE = CORRESPONDING #( <fs_range>-range ).
      ENDCASE.
    ENDLOOP.

    READ TABLE  lR_reportingdate INTO DATA(ls_reportingdate) INDEX 1.
    IF sy-subrc = 0.
      DATA(lv_date) = ls_reportingdate-low.
    ENDIF.

    SELECT uuid,
           PrincipalBalanceEUR,
           InterestBalanceEUR,
           CurrencyEUR
     FROM  zr_sfi008( p_date = @lv_date )
     INTO  TABLE @DATA(lt_result).                    "#EC CI_NOWHERE."

    LOOP AT lt_result INTO DATA(lwa_result).
      SELECT SINGLE lender   FROM zr_tfi001   WHERE uuid = @lwa_result-uuid INTO @lwa_entity-CompanyCode.
      IF sy-subrc = 0.
        lwa_entity-ReportingDate = lv_date.
        " lwa_entity-Num             : abap.int4;
        lwa_entity-Currency        = 'EUR'.
        lwa_entity-PrincipalLender = lwa_result-PrincipalBalanceEUR.
        lwa_entity-InterestLender  = lwa_result-InterestBalanceEUR.
        COLLECT lwa_entity INTO lt_entity.
        CLEAR lwa_entity.
      ENDIF.

      SELECT SINGLE Borrower   FROM zr_tfi001   WHERE uuid = @lwa_result-uuid INTO @lwa_entity-CompanyCode.
      IF sy-subrc = 0.
        lwa_entity-ReportingDate = lv_date.
        " lwa_entity-Num             : abap.int4;
        lwa_entity-Currency      = 'EUR'.
        lwa_entity-PrincipalBorrower = lwa_result-PrincipalBalanceEUR.
        lwa_entity-InterestBorrower  = lwa_result-InterestBalanceEUR.
        COLLECT lwa_entity INTO lt_entity.
        CLEAR lwa_entity.
      ENDIF.
    ENDLOOP.
    DELETE lt_entity WHERE  CompanyCode NOT IN lr_companycode.
    zzcl_odata_utils=>filtering( EXPORTING io_filter = io_request->get_filter(  ) CHANGING ct_data = lt_entity ).

    IF io_request->is_total_numb_of_rec_requested(  ) .
      io_response->set_total_number_of_records( lines( lt_entity ) ).
    ENDIF.

    zzcl_odata_utils=>orderby( EXPORTING it_order = io_request->get_sort_elements( )  CHANGING ct_data = lt_entity ).

    zzcl_odata_utils=>paging( EXPORTING io_paging = io_request->get_paging(  ) CHANGING ct_data = lt_entity ).

    io_response->set_data( lt_entity ).
  ENDMETHOD.


  METHOD get_interest_item.
    TRY.
        DATA(lt_ranges) = io_request->get_filter(  )->get_as_ranges(  ).
      CATCH cx_rap_query_filter_no_range.
        "handle exception
        APPEND VALUE #( type = 'E' message = 'filter_no_range' ) TO g_result.
    ENDTRY.

    DATA : lr_companycode   TYPE RANGE OF bukrs,
           lr_reportingdate TYPE RANGE OF datum.
    DATA: lt_entity  TYPE TABLE OF zr_sfi023,
          lwa_entity TYPE zr_sfi023.

    LOOP AT lt_ranges ASSIGNING FIELD-SYMBOL(<fs_range>).
      TRANSLATE <fs_range>-name TO UPPER CASE.
      CASE <fs_range>-name.
        WHEN 'COMPANYCODE'.
          lr_companycode = CORRESPONDING #( <fs_range>-range ).
        WHEN 'REPORTINGDATE'.
          lR_REPORTINGDATE = CORRESPONDING #( <fs_range>-range ).
      ENDCASE.
    ENDLOOP.

    READ TABLE  lR_reportingdate INTO DATA(ls_reportingdate) INDEX 1.
    IF sy-subrc = 0.
      DATA(lv_date) = ls_reportingdate-low.
    ENDIF.

    SELECT uuid,
           PrincipalBalanceEUR,
           InterestBalanceEUR,
           CurrencyEUR
     FROM  zr_sfi008( p_date = @lv_date )
     INTO  TABLE @DATA(lt_result).                    "#EC CI_NOWHERE."

    LOOP AT lt_result INTO DATA(lwa_result).
      SELECT SINGLE   lender ,
                      Borrower
               FROM zr_tfi001
               WHERE uuid = @lwa_result-uuid
               INTO (  @lwa_entity-CompanyCode, @lwa_entity-Counterparty ).
      IF sy-subrc = 0.

        lwa_entity-uuid          = lwa_result-uuid.
        lwa_entity-ReportingDate = lv_date.
        lwa_entity-Currency        = 'EUR'.
        lwa_entity-PrincipalLender = lwa_result-PrincipalBalanceEUR.
        lwa_entity-InterestLender  = lwa_result-InterestBalanceEUR.
        APPEND lwa_entity TO lt_entity.
        CLEAR lwa_entity.
      ENDIF.

      SELECT SINGLE   Borrower ,
                      lender
               FROM zr_tfi001
               WHERE uuid = @lwa_result-uuid
               INTO (  @lwa_entity-CompanyCode, @lwa_entity-Counterparty ).
      IF sy-subrc = 0.
        lwa_entity-uuid          = lwa_result-uuid.
        lwa_entity-ReportingDate = lv_date.
        lwa_entity-Currency        = 'EUR'.
        lwa_entity-PrincipalLender = lwa_result-PrincipalBalanceEUR.
        lwa_entity-InterestLender  = lwa_result-InterestBalanceEUR.
        APPEND lwa_entity TO lt_entity.
        CLEAR lwa_entity.
      ENDIF.
    ENDLOOP.
    DELETE lt_entity WHERE  CompanyCode NOT IN lr_companycode.
    zzcl_odata_utils=>filtering( EXPORTING io_filter = io_request->get_filter(  ) CHANGING ct_data = lt_entity ).

    IF io_request->is_total_numb_of_rec_requested(  ) .
      io_response->set_total_number_of_records( lines( lt_entity ) ).
    ENDIF.

    zzcl_odata_utils=>orderby( EXPORTING it_order = io_request->get_sort_elements( )  CHANGING ct_data = lt_entity ).

    zzcl_odata_utils=>paging( EXPORTING io_paging = io_request->get_paging(  ) CHANGING ct_data = lt_entity ).

    io_response->set_data( lt_entity ).

  ENDMETHOD.


  METHOD if_rap_query_provider~select.
    DATA(lv_entity_id) =  io_request->get_entity_id(  ).

    CASE lv_entity_id.

      WHEN 'ZR_SFI017'.
        get_interest(
            EXPORTING
                io_request = io_request
                io_response = io_response
         ).

      WHEN 'ZR_SFI023'.
        get_interest_item(
            EXPORTING
                io_request = io_request
                io_response = io_response
         ).
      WHEN OTHERS.

    ENDCASE.
  ENDMETHOD.
ENDCLASS.
