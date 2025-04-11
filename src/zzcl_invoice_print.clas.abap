CLASS zzcl_invoice_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS get_invoice_header IMPORTING io_request  TYPE REF TO if_rap_query_request
                                         io_response TYPE REF TO if_rap_query_response.
    METHODS get_seller_info IMPORTING io_request  TYPE REF TO if_rap_query_request
                                      io_response TYPE REF TO if_rap_query_response.

    METHODS get_buyer_info IMPORTING io_request  TYPE REF TO if_rap_query_request
                                     io_response TYPE REF TO if_rap_query_response.

    METHODS get_bank_info IMPORTING io_request  TYPE REF TO if_rap_query_request
                                    io_response TYPE REF TO if_rap_query_response.
    METHODS get_invoice_detail IMPORTING io_request  TYPE REF TO if_rap_query_request
                                         io_response TYPE REF TO if_rap_query_response.


    CLASS-DATA g_result TYPE cl_exchange_rates=>ty_messages.
ENDCLASS.



CLASS ZZCL_INVOICE_PRINT IMPLEMENTATION.


  METHOD get_bank_info.
    DATA:lr_companycode        TYPE RANGE OF bukrs,
         lr_AccountingDocument TYPE RANGE OF I_JournalEntry-AccountingDocument,
         lr_FiscalYear         TYPE RANGE OF I_JournalEntry-FiscalYear.
    DATA:lt_entity TYPE TABLE OF zr_sfi042,
         ls_entity TYPE zr_sfi042.

    TRY.
        DATA(lt_ranges) = io_request->get_filter(  )->get_as_ranges(  ).
      CATCH cx_rap_query_filter_no_range.
        "handle exception
        APPEND VALUE #( type = 'E' message = 'filter_no_range' ) TO g_result.
    ENDTRY.
    LOOP AT lt_ranges ASSIGNING FIELD-SYMBOL(<fs_range>).
      TRANSLATE <fs_range>-name TO UPPER CASE.
      CASE <fs_range>-name.
        WHEN 'COMPANYCODE'.
          lr_companycode = CORRESPONDING #( <fs_range>-range ).
        WHEN 'ACCOUNTINGDOCUMENT'.
          lr_AccountingDocument = CORRESPONDING #( <fs_range>-range ).
        WHEN 'FISCALYEAR'.
          lr_FiscalYear = CORRESPONDING #( <fs_range>-range ).
      ENDCASE.
    ENDLOOP.

    SELECT * FROM zr_sfi038
    WHERE CompanyCode IN @lr_companycode
      AND AccountingDocument IN @lr_AccountingDocument
      AND FiscalYear IN @lr_FiscalYear
    INTO TABLE @DATA(lt_result).
    MOVE-CORRESPONDING lt_result TO lt_entity.

    zzcl_odata_utils=>filtering( EXPORTING io_filter = io_request->get_filter(  ) CHANGING ct_data = lt_entity ).

    IF io_request->is_total_numb_of_rec_requested(  ) .
      io_response->set_total_number_of_records( lines( lt_entity ) ).
    ENDIF.

    zzcl_odata_utils=>orderby( EXPORTING it_order = io_request->get_sort_elements( )  CHANGING ct_data = lt_entity ).

    zzcl_odata_utils=>paging( EXPORTING io_paging = io_request->get_paging(  ) CHANGING ct_data = lt_entity ).

    io_response->set_data( lt_entity ).

  ENDMETHOD.


  METHOD get_buyer_info.
    DATA:lr_companycode        TYPE RANGE OF bukrs,
         lr_AccountingDocument TYPE RANGE OF I_JournalEntry-AccountingDocument,
         lr_FiscalYear         TYPE RANGE OF I_JournalEntry-FiscalYear.
    DATA:lt_entity TYPE TABLE OF zr_sfi041,
         ls_entity TYPE zr_sfi041.
    TRY.
        DATA(lt_ranges) = io_request->get_filter(  )->get_as_ranges(  ).
      CATCH cx_rap_query_filter_no_range.
        "handle exception
        APPEND VALUE #( type = 'E' message = 'filter_no_range' ) TO g_result.
    ENDTRY.
    LOOP AT lt_ranges ASSIGNING FIELD-SYMBOL(<fs_range>).
      TRANSLATE <fs_range>-name TO UPPER CASE.
      CASE <fs_range>-name.
        WHEN 'COMPANYCODE'.
          lr_companycode = CORRESPONDING #( <fs_range>-range ).
        WHEN 'ACCOUNTINGDOCUMENT'.
          lr_AccountingDocument = CORRESPONDING #( <fs_range>-range ).
        WHEN 'FISCALYEAR'.
          lr_FiscalYear = CORRESPONDING #( <fs_range>-range ).
      ENDCASE.
    ENDLOOP.
    SELECT * FROM zr_sfi038
    WHERE CompanyCode IN @lr_companycode
      AND AccountingDocument IN @lr_AccountingDocument
      AND FiscalYear IN @lr_FiscalYear
    INTO TABLE @DATA(lt_result).
    MOVE-CORRESPONDING lt_result TO lt_entity.
    LOOP AT lt_entity INTO ls_entity.
      CONCATENATE ls_entity-CustomerStreetName ls_entity-CustomerHouseNumber
      INTO ls_entity-CustomerStreetHouse
      SEPARATED BY space.
      CONCATENATE ls_entity-CustomerPostalCode ls_entity-CustomerCity
      INTO ls_entity-CustomerPostalCity
      SEPARATED BY space.
      MODIFY lt_entity FROM ls_entity.
      CLEAR ls_entity.
    ENDLOOP..
    zzcl_odata_utils=>filtering( EXPORTING io_filter = io_request->get_filter(  ) CHANGING ct_data = lt_entity ).

    IF io_request->is_total_numb_of_rec_requested(  ) .
      io_response->set_total_number_of_records( lines( lt_entity ) ).
    ENDIF.

    zzcl_odata_utils=>orderby( EXPORTING it_order = io_request->get_sort_elements( )  CHANGING ct_data = lt_entity ).

    zzcl_odata_utils=>paging( EXPORTING io_paging = io_request->get_paging(  ) CHANGING ct_data = lt_entity ).

    io_response->set_data( lt_entity ).
  ENDMETHOD.


  METHOD get_invoice_detail.
    DATA:lr_companycode        TYPE RANGE OF bukrs,
         lr_AccountingDocument TYPE RANGE OF I_JournalEntry-AccountingDocument,
         lr_FiscalYear         TYPE RANGE OF I_JournalEntry-FiscalYear.
    DATA:lt_entity TYPE TABLE OF zr_sfi043,
         ls_entity TYPE zr_sfi043.
    DATA:l_factor TYPE ffact_curr.
    TRY.
        DATA(lt_ranges) = io_request->get_filter(  )->get_as_ranges(  ).
      CATCH cx_rap_query_filter_no_range.
        "handle exception
        APPEND VALUE #( type = 'E' message = 'filter_no_range' ) TO g_result.
    ENDTRY.
    LOOP AT lt_ranges ASSIGNING FIELD-SYMBOL(<fs_range>).
      TRANSLATE <fs_range>-name TO UPPER CASE.
      CASE <fs_range>-name.
        WHEN 'COMPANYCODE'.
          lr_companycode = CORRESPONDING #( <fs_range>-range ).
        WHEN 'ACCOUNTINGDOCUMENT'.
          lr_AccountingDocument = CORRESPONDING #( <fs_range>-range ).
        WHEN 'FISCALYEAR'.
          lr_FiscalYear = CORRESPONDING #( <fs_range>-range ).
      ENDCASE.
    ENDLOOP.

    SELECT * FROM zr_sfi044
    WHERE CompanyCode IN @lr_companycode
      AND AccountingDocument IN @lr_AccountingDocument
      AND FiscalYear IN @lr_FiscalYear
    INTO TABLE @DATA(lt_result).

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_result1>).
      <fs_result1>-GrossAmount = abs( <fs_result1>-GrossAmount ).
      <fs_result1>-NetAmount = abs( <fs_result1>-NetAmount ).
      <fs_result1>-TaxAmount = abs( <fs_result1>-TaxAmount  ) .
      <fs_result1>-UnitPrice = abs( <fs_result1>-UnitPrice ) .
    ENDLOOP.

    MOVE-CORRESPONDING lt_result TO lt_entity.
    zzcl_odata_utils=>filtering( EXPORTING io_filter = io_request->get_filter(  ) CHANGING ct_data = lt_entity ).
    DATA(l_lines)  = lines( lt_entity ).
    IF l_lines LE 3.
      DATA(l_lines2) = l_lines + 3.
      DATA(l_mod) = l_lines2 MOD 7.
      DATA(l_count) = 7 - l_mod.
      DATA(l_count2) = l_lines.
      DO l_count TIMES.
        l_count2 = l_count2 + 1.
        READ TABLE lt_result ASSIGNING FIELD-SYMBOL(<fs_result>) INDEX 1.
        IF sy-subrc = 0.
          ls_entity-CompanyCode = <fs_result>-CompanyCode.
          ls_entity-AccountingDocument = <fs_result>-AccountingDocument.
          ls_entity-FiscalYear = <fs_result>-FiscalYear.
          ls_entity-AccountingDocumentItem = l_count2.
          ls_entity-GrossAmount = ''.
          ls_entity-NetAmount = ''.
          ls_entity-Quality = ''.
          ls_entity-TaxAmount = ''.
          ls_entity-Taxrate = ''.
          ls_entity-UnitPrice = ''.
          APPEND ls_entity TO  lt_entity.
          CLEAR ls_entity.
        ENDIF.
      ENDDO.
    ELSE.
      DATA(l_lines3) = l_lines + 1.
      DATA(l_times) = l_lines DIV 4.
      DATA(l_indx) = 0.
      CLEAR:l_count,l_count2.
      l_count2 = l_lines.
      DO l_times TIMES.
        l_count = l_count + 1.
        IF l_count = 1.
          l_indx = 4.
        ELSE.
          l_indx = l_indx + 4.
        ENDIF.
        DO 3 TIMES.
          l_count2 = l_count2 + 1.
          READ TABLE lt_result ASSIGNING <fs_result> INDEX 1.
          IF sy-subrc = 0.
            ls_entity-CompanyCode = <fs_result>-CompanyCode.
            ls_entity-AccountingDocument = <fs_result>-AccountingDocument.
            ls_entity-FiscalYear = <fs_result>-FiscalYear.
            ls_entity-AccountingDocumentItem = l_count2.
            INSERT ls_entity INTO lt_entity INDEX l_indx.
            CLEAR ls_entity.
            l_indx = l_indx + 1.
          ENDIF.
        ENDDO.
      ENDDO.
      l_lines  = lines( lt_entity ).
      l_lines2 = l_lines + 3.
      l_mod = l_lines2 MOD 7.
      l_count = 7 - l_mod.
      l_count2 = l_lines.
      DO l_count TIMES.
        l_count2 = l_count2 + 1.
        READ TABLE lt_result ASSIGNING <fs_result> INDEX 1.
        IF sy-subrc = 0.
          ls_entity-CompanyCode = <fs_result>-CompanyCode.
          ls_entity-AccountingDocument = <fs_result>-AccountingDocument.
          ls_entity-FiscalYear = <fs_result>-FiscalYear.
          ls_entity-AccountingDocumentItem = l_count2.
          ls_entity-GrossAmount = ''.
          ls_entity-NetAmount = ''.
          ls_entity-Quality = ''.
          ls_entity-TaxAmount = ''.
          ls_entity-Taxrate = ''.
          ls_entity-UnitPrice = ''.
          APPEND ls_entity TO  lt_entity.
          CLEAR ls_entity.
        ENDIF.
      ENDDO.
    ENDIF.
    IF io_request->is_total_numb_of_rec_requested(  ) .
      io_response->set_total_number_of_records( lines( lt_entity ) ).
    ENDIF.

    zzcl_odata_utils=>orderby( EXPORTING it_order = io_request->get_sort_elements( )  CHANGING ct_data = lt_entity ).

    zzcl_odata_utils=>paging( EXPORTING io_paging = io_request->get_paging(  ) CHANGING ct_data = lt_entity ).

    io_response->set_data( lt_entity ).

  ENDMETHOD.


  METHOD get_invoice_header.
    DATA:lr_companycode        TYPE RANGE OF bukrs,
         lr_AccountingDocument TYPE RANGE OF I_JournalEntry-AccountingDocument,
         lr_FiscalYear         TYPE RANGE OF I_JournalEntry-FiscalYear.
    DATA:lt_entity TYPE TABLE OF zr_sfi039,
         ls_entity TYPE zr_sfi039.
    DATA:l_sum_netamount TYPE I_OperationalAcctgDocItem-TaxBaseAmountInTransCrcy.
    DATA:l_sum_taxamount TYPE I_OperationalAcctgDocItem-TaxBaseAmountInTransCrcy.
    DATA:l_sum_grossamount TYPE I_OperationalAcctgDocItem-TaxBaseAmountInTransCrcy.
    DATA:l_taxrate TYPE zr_sfi044-TaxRate.
    DATA:l_factor TYPE ffact_curr.
    TRY.
        DATA(lt_ranges) = io_request->get_filter(  )->get_as_ranges(  ).
      CATCH cx_rap_query_filter_no_range.
        "handle exception
        APPEND VALUE #( type = 'E' message = 'filter_no_range' ) TO g_result.
    ENDTRY.
    LOOP AT lt_ranges ASSIGNING FIELD-SYMBOL(<fs_range>).
      TRANSLATE <fs_range>-name TO UPPER CASE.
      CASE <fs_range>-name.
        WHEN 'COMPANYCODE'.
          lr_companycode = CORRESPONDING #( <fs_range>-range ).
        WHEN 'ACCOUNTINGDOCUMENT'.
          lr_AccountingDocument = CORRESPONDING #( <fs_range>-range ).
        WHEN 'FISCALYEAR'.
          lr_FiscalYear = CORRESPONDING #( <fs_range>-range ).
      ENDCASE.
    ENDLOOP.

    SELECT * FROM zr_sfi038
    WHERE CompanyCode IN @lr_companycode
      AND AccountingDocument IN @lr_AccountingDocument
      AND FiscalYear IN @lr_FiscalYear
    INTO TABLE @DATA(lt_result).
    MOVE-CORRESPONDING lt_result TO lt_entity.

    SELECT * FROM zr_sfi044
    WHERE CompanyCode IN @lr_companycode
      AND AccountingDocument IN @lr_AccountingDocument
      AND FiscalYear IN @lr_FiscalYear
    INTO TABLE @DATA(lt_result_V).

    LOOP AT lt_result_v ASSIGNING FIELD-SYMBOL(<fs_result_v>).
      l_sum_netamount = abs( <fs_result_v>-NetAmount )  + l_sum_netamount.
      l_sum_taxamount = abs( <fs_result_v>-TaxAmount )  + l_sum_taxamount.
      l_sum_grossamount = abs( <fs_result_v>-GrossAmount ) + l_sum_grossamount.
      l_taxrate = <fs_result_v>-TaxRate.
    ENDLOOP.
    LOOP AT lt_entity ASSIGNING FIELD-SYMBOL(<fs_entity>).
      <fs_entity>-NetAmountSum = l_sum_netamount.
      <fs_entity>-TaxAmountSUM = l_sum_taxamount.
      <fs_entity>-GrossAmountSum = l_sum_grossamount.
      <fs_entity>-TaxRate = l_taxrate.
    ENDLOOP.
    zzcl_odata_utils=>filtering( EXPORTING io_filter = io_request->get_filter(  ) CHANGING ct_data = lt_entity ).

    IF io_request->is_total_numb_of_rec_requested(  ) .
      io_response->set_total_number_of_records( lines( lt_entity ) ).
    ENDIF.

    zzcl_odata_utils=>orderby( EXPORTING it_order = io_request->get_sort_elements( )  CHANGING ct_data = lt_entity ).

    zzcl_odata_utils=>paging( EXPORTING io_paging = io_request->get_paging(  ) CHANGING ct_data = lt_entity ).

    io_response->set_data( lt_entity ).

  ENDMETHOD.


  METHOD get_seller_info.
    DATA:lr_companycode        TYPE RANGE OF bukrs,
         lr_AccountingDocument TYPE RANGE OF I_JournalEntry-AccountingDocument,
         lr_FiscalYear         TYPE RANGE OF I_JournalEntry-FiscalYear.
    DATA:lt_entity TYPE TABLE OF zr_sfi040,
         ls_entity TYPE zr_sfi040.
    TRY.
        DATA(lt_ranges) = io_request->get_filter(  )->get_as_ranges(  ).
      CATCH cx_rap_query_filter_no_range.
        "handle exception
        APPEND VALUE #( type = 'E' message = 'filter_no_range' ) TO g_result.
    ENDTRY.
    LOOP AT lt_ranges ASSIGNING FIELD-SYMBOL(<fs_range>).
      TRANSLATE <fs_range>-name TO UPPER CASE.
      CASE <fs_range>-name.
        WHEN 'COMPANYCODE'.
          lr_companycode = CORRESPONDING #( <fs_range>-range ).
        WHEN 'ACCOUNTINGDOCUMENT'.
          lr_AccountingDocument = CORRESPONDING #( <fs_range>-range ).
        WHEN 'FISCALYEAR'.
          lr_FiscalYear = CORRESPONDING #( <fs_range>-range ).
      ENDCASE.
    ENDLOOP.
    SELECT * FROM zr_sfi038
    WHERE CompanyCode IN @lr_companycode
      AND AccountingDocument IN @lr_AccountingDocument
      AND FiscalYear IN @lr_FiscalYear
    INTO TABLE @DATA(lt_result).
    MOVE-CORRESPONDING lt_result TO lt_entity.
    LOOP AT lt_entity INTO ls_entity.
      CONCATENATE ls_entity-CompanyStreetName ls_entity-CompanyHouseNumber
      INTO ls_entity-CompanyStreetHouse
      SEPARATED BY space.
      CONCATENATE ls_entity-CompanyPostalCode ls_entity-CompanyCity
      INTO ls_entity-CompanyPostalCity
      SEPARATED BY space.
      MODIFY lt_entity FROM ls_entity.
      CLEAR ls_entity.
    ENDLOOP..
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

      WHEN 'ZR_SFI039'.
        get_invoice_header(
            EXPORTING
                io_request = io_request
                io_response = io_response
         ).


      WHEN 'ZR_SFI040'.
        get_seller_info(
            EXPORTING
                io_request = io_request
                io_response = io_response
         ).
      WHEN 'ZR_SFI041'.
        get_buyer_info(
            EXPORTING
                io_request = io_request
                io_response = io_response
         ).
      WHEN 'ZR_SFI042'.
        get_bank_info(
            EXPORTING
                io_request = io_request
                io_response = io_response
         ).
      WHEN 'ZR_SFI043'.

        get_invoice_detail(
            EXPORTING
                io_request = io_request
                io_response = io_response
         ).

    ENDCASE.
  ENDMETHOD.
ENDCLASS.
