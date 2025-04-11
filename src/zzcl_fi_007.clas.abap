CLASS zzcl_fi_007 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_apj_dt_exec_object .
    INTERFACES if_apj_rt_exec_object .
    INTERFACES if_oo_adt_classrun .

    TYPES : BEGIN OF ts_range_currency,
              sign   TYPE c LENGTH 1,
              option TYPE c LENGTH 2,
              low    TYPE zzefi039,
              high   TYPE zzefi039,
            END OF ts_range_currency,
            tt_range_currency TYPE STANDARD TABLE OF ts_range_currency WITH DEFAULT KEY.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: out TYPE REF TO if_oo_adt_classrun_out.
    DATA: application_log TYPE REF TO if_bali_log .
    CONSTANTS : xlsx_sheet_name TYPE string VALUE 'Sheet0'.

    DATA : start_date     TYPE datum,
           end_date       TYPE datum,
           rate_type      TYPE kurst_curr,
           currency_range TYPE tt_range_currency.

    METHODS: get_ratefile RETURNING VALUE(file) TYPE xstring
                          RAISING
                                    cx_http_dest_provider_error
                                    cx_web_http_client_error
                                    cx_abap_datfm_format_unknown.
    METHODS: parse_ratefile
      IMPORTING file           TYPE xstring
                start_date     TYPE datum
                end_date       TYPE datum OPTIONAL
                currency_range TYPE tt_range_currency
                rate_type      TYPE kurst_curr
      RETURNING VALUE(rates)   TYPE cl_exchange_rates=>ty_exchange_rates
      RAISING   zzcx_fi_001
                cx_abap_datfm_no_date
                cx_abap_datfm_invalid_date
                cx_abap_datfm_format_unknown
                cx_abap_datfm_ambiguous.

    METHODS: sync_rates
      IMPORTING rates          TYPE cl_exchange_rates=>ty_exchange_rates
      RETURNING VALUE(results) TYPE cl_exchange_rates=>ty_messages.

    METHODS : get_parameters IMPORTING it_parameters TYPE if_apj_dt_exec_object=>tt_templ_val .

    METHODS init_application_log.
    METHODS add_text_to_app_log_or_console IMPORTING i_text TYPE cl_bali_free_text_setter=>ty_text
                                                     i_type TYPE cl_bali_free_text_setter=>ty_severity OPTIONAL.
*                                           RAISING   cx_bali_runtime.
    METHODS add_except_to_log_or_console IMPORTING ix_exception TYPE REF TO cx_root.

    METHODS add_msg_to_app_log_or_console IMPORTING messages TYPE bapirettab.
ENDCLASS.



CLASS ZZCL_FI_007 IMPLEMENTATION.


  METHOD add_except_to_log_or_console.
    TRY.
        IF sy-batch = abap_true.

*          DATA(application_log_free_text) = cl_bali_free_text_setter=>create(
*                                 severity = COND #( WHEN i_type IS NOT INITIAL
*                                                    THEN i_type
*                                                    ELSE if_bali_constants=>c_severity_status )
*                                 text     = i_text ).
          DATA(l_ref) = cl_bali_exception_setter=>create( severity = if_bali_constants=>c_severity_error
                                                           exception = ix_exception ).

          l_ref->set_detail_level( detail_level = '1' ).
          application_log->add_item( item = l_ref ).
          cl_bali_log_db=>get_instance( )->save_log( log = application_log
                                                     assign_to_current_appl_job = abap_true ).

        ELSE.
*          out->write( |sy-batch = abap_false | ).
          out->write( ix_exception->get_longtext(  ) ).
        ENDIF.
      CATCH cx_bali_runtime INTO DATA(lx_bali_runtime).
        ##NO_HANDLER
        EXIT.      " 从 lv_text 中截取匹配的子串，ls_result_tab-offset 为起始位置，
        " ls_result_tab-length 为匹配长度
    ENDTRY.


  ENDMETHOD.


  METHOD add_msg_to_app_log_or_console.
    TRY.
        IF sy-batch = abap_true.
          LOOP AT messages ASSIGNING FIELD-SYMBOL(<message>).
            DATA(application_log_msg) = cl_bali_message_setter=>create_from_bapiret2(
                <message>
            ).
            application_log_msg->set_detail_level( detail_level = '7' ).
            application_log->add_item( item = application_log_msg ).
          ENDLOOP.
          cl_bali_log_db=>get_instance( )->save_log( log = application_log
                                           assign_to_current_appl_job = abap_true ).
        ELSE.
*          out->write( |sy-batch = abap_false | ).
          out->write( messages ).
        ENDIF.
      CATCH cx_bali_runtime INTO DATA(lx_bali_runtime).
        ##NO_HANDLER
        EXIT.
    ENDTRY.


  ENDMETHOD.


  METHOD add_text_to_app_log_or_console.
    TRY.
        IF sy-batch = abap_true.

          DATA(application_log_free_text) = cl_bali_free_text_setter=>create(
                                 severity = COND #( WHEN i_type IS NOT INITIAL
                                                    THEN i_type
                                                    ELSE if_bali_constants=>c_severity_status )
                                 text     = i_text ).

          application_log_free_text->set_detail_level( detail_level = '1' ).
          application_log->add_item( item = application_log_free_text ).
          cl_bali_log_db=>get_instance( )->save_log( log = application_log
                                                     assign_to_current_appl_job = abap_true ).

        ELSE.
*          out->write( |sy-batch = abap_false | ).
          out->write( i_text ).
        ENDIF.
      CATCH cx_bali_runtime INTO DATA(lx_bali_runtime).
        ##NO_HANDLER
        EXIT.
    ENDTRY.
  ENDMETHOD.


  METHOD get_parameters.
    LOOP AT it_parameters INTO DATA(ls_parameter).
      CASE ls_parameter-selname.
        WHEN 'P_FRDATE'.
          start_date = ls_parameter-low.
        WHEN 'P_TODATE'.
          end_date = ls_parameter-low.
        WHEN 'P_RTYPE'.
          rate_type = ls_parameter-low.
        WHEN 'S_CURR'.
*          ls_parameter-low.
          APPEND VALUE #( sign   = ls_parameter-sign
                                    option = ls_parameter-option
                                    low    = ls_parameter-low
                                    high   = ls_parameter-high ) TO currency_range.
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_ratefile.

    DATA(destination) = cl_http_destination_provider=>create_by_comm_arrangement(
           comm_scenario  = 'ZZCS_FI_002'
           service_id     = 'ZZOS_FI_005_REST'
           comm_system_id = 'PBC'
      ).
    DATA(http_client) = cl_web_http_client_manager=>create_by_http_destination( destination ).
    DATA(request) = http_client->get_http_request( ).
    request->set_uri_path( '/CcprHisNew' ).
    DATA : start_date_str TYPE c LENGTH 10,
           end_date_str   TYPE c LENGTH 10.
    cl_abap_datfm=>conv_date_int_to_ext(
       EXPORTING
        im_datint = start_date
        im_datfmdes = '6'
       IMPORTING
        ex_datext = start_date_str
    ).
    request->set_form_field(
        i_name = 'startDate'
        i_value = CONV string( start_date_str )
    ).

    cl_abap_datfm=>conv_date_int_to_ext(
       EXPORTING
        im_datint = end_date
        im_datfmdes = '6'
       IMPORTING
        ex_datext = end_date_str
    ).
    request->set_form_field(
        i_name = 'endDate'
        i_value = CONV string( end_date_str )
    ).

*    request->set_form_field(
*        i_name = 'pageSize'
*        i_value = CONV string( 99 )
*    ).


    DATA(response) = http_client->execute( if_web_http_client=>get ).

    file = response->get_binary(  ).

    DATA(text) = response->get_text(  ).
    DATA(status) = response->get_status(  ).

  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.
    et_parameter_def = VALUE #(
        (
            selname = 'P_FRDATE'
            kind = if_apj_dt_exec_object=>parameter
            datatype = 'D'
            length = 8
            param_text = 'From Date'
            component_type = 'BUDAT'
            changeable_ind = abap_true
            mandatory_ind = abap_true
        )
        (
            selname = 'P_TODATE'
            kind = if_apj_dt_exec_object=>parameter
            datatype = 'D'
            length = 8
            param_text = 'To Date'
            component_type = 'BUDAT'
            changeable_ind = abap_true
            mandatory_ind = abap_false
        )
        (
            selname = 'S_CURR'
            kind = if_apj_dt_exec_object=>select_option
            datatype = 'C'
            length = 11
            param_text = 'Currency Pairs(Maintain in format: ISO/ISO, e.g., USD/CNY)'
            component_type = 'ZZEFI039'
            changeable_ind = abap_true
            mandatory_ind = abap_false
            section_text = 'Maintain in format: ISO/ISO, e.g., USD/CNY'
        )
        (
            selname = 'P_RTYPE'
            kind = if_apj_dt_exec_object=>parameter
            datatype = 'C'
            length = 4
            param_text = 'Rate Type'
            component_type = 'KURST_CURR'
            changeable_ind = abap_true
            mandatory_ind = abap_true
        )
    ).
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    init_application_log(  ).
    get_parameters( it_parameters ).
    TRY.
        DATA(file) = get_ratefile(  ).
      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_abap_datfm_format_unknown INTO DATA(lx_http).
        "handle exception
*        out->write( lx_http->get_longtext(  ) ).
        add_except_to_log_or_console(
            ix_exception = lx_http
        ).
        RETURN.
        "handle exception
    ENDTRY.

    TRY.
        DATA(rates) = parse_ratefile(
            file = file
            start_date = start_date
            end_date = end_date
            currency_range = currency_range
            rate_type = rate_type
         ).
      CATCH zzcx_fi_001 cx_abap_datfm_no_date cx_abap_datfm_invalid_date cx_abap_datfm_format_unknown cx_abap_datfm_ambiguous INTO DATA(lx_parse).
        "handle exception
*        out->write( lx_parse->get_longtext(  ) ).
        add_except_to_log_or_console(
            ix_exception = lx_http
        ).
        RETURN.
        "handle exception
    ENDTRY.

    DATA(results) = sync_rates( rates = rates ).

*    out->write( results ).

    add_msg_to_app_log_or_console( messages = CONV bapirettab( results ) ).

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    DATA(current_date) = cl_abap_context_info=>get_system_date(  ).
    DATA: s_curr    TYPE RANGE OF zzefi039,
          rate_type TYPE kurst_curr.

    s_curr = VALUE #(
        (
            low = 'USD/CNY'
            sign = 'I'
            option = 'EQ'
        )
        (
            low = 'CNY/USD'
            sign = 'I'
            option = 'EQ'
        )
        (
            low = 'HKD/CNY'
            sign = 'I'
            option = 'EQ'
        )
        (
            low = 'EUR/CNY'
            sign = 'I'
            option = 'EQ'
        )
    ).
    rate_type = 'M'.
    start_date = CONV datum(   xco_cp_time=>date(
                            iv_year = current_date(4)
                            iv_month = current_date+4(2)
                            iv_day = current_date+6(2)
                         )->subtract( iv_year = 0 iv_month = 0 iv_day = 1 )->as( io_format = xco_cp_time=>format->abap  )->value ).
    end_date = current_date.

    TRY.
        DATA(file) = get_ratefile(  ).
      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_abap_datfm_format_unknown INTO DATA(lx_http).
        "handle exception
        out->write( lx_http->get_longtext(  ) ).
        RETURN.
    ENDTRY.


    TRY.
        DATA(rates) = parse_ratefile(
            file = file
            start_date = start_date
            currency_range = s_curr
            rate_type = rate_type
         ).
      CATCH zzcx_fi_001 cx_abap_datfm_no_date cx_abap_datfm_invalid_date cx_abap_datfm_format_unknown cx_abap_datfm_ambiguous INTO DATA(lx_parse).
        "handle exception
        out->write( lx_parse->get_longtext(  ) ).
        RETURN.
    ENDTRY.

    DATA(results) = sync_rates( rates = rates ).

    out->write( results ).


  ENDMETHOD.


  METHOD init_application_log.
    DATA : external_id TYPE c LENGTH 100.
    TRY.
        external_id = cl_system_uuid=>create_uuid_x16_static(  ).
        application_log = cl_bali_log=>create_with_header(
                               header = cl_bali_header_setter=>create( object = 'ZZ_ALO_EXCHANGERATE'
                                                                       subobject = 'PBC'
                                                                       external_id = external_id ) ).
      CATCH cx_bali_runtime cx_uuid_error INTO DATA(lx_bali_runtime).
        "handle exception
        EXIT.
    ENDTRY.
  ENDMETHOD.


  METHOD parse_ratefile.
*    DATA(document) = xco_cp_xlsx=>document->for_file_content( file ).
*    DATA(worksheet) = document->read_access(  )->get_workbook(  )->worksheet->for_name( xlsx_sheet_name ).
*    IF worksheet->exists(  ) = abap_false.
*
*      RAISE EXCEPTION TYPE zzcx_fi_001
*        EXPORTING
*          textid = VALUE #(
*              msgid = 'ZZFI'
*              msgno = '005'
*              attr1 = xlsx_sheet_name
*          ).
**      RETURN.
*    ENDIF.
    DATA(data_in_json) = xco_cp=>xstring( file
        )->as_string( xco_cp_character=>code_page->utf_8
        )->value.


    DATA(xlsx_process_rates) = NEW lcl_xlsx_process_rates(
                                    start_date = start_date
                                    end_date = end_date
                                    currency_range = currency_range
*                                    worksheet = worksheet
                                    data_in_json = data_in_json
                                    rate_type = rate_type
                                ).
    DATA(lt_rates) = xlsx_process_rates->process(  ).

    rates = VALUE #(
        FOR rate IN lt_rates
        FOR rate_in_date IN rate-rates
        (
            from_curr = rate-from_currency
            from_factor = rate_in_date-from_factor
            rate_type = rate_type
            to_currncy = rate-to_currency
            to_factor = rate_in_date-to_factor
            valid_from = rate_in_date-date
            exch_rate = rate_in_date-exchangerate
        )
    ).

  ENDMETHOD.


  METHOD sync_rates.
    results = cl_exchange_rates=>put(
        exchange_rates = rates
        is_update_allowed = abap_false
    ).
    LOOP AT results ASSIGNING FIELD-SYMBOL(<result>) WHERE id = 'E!' AND number = '020'.
      <result>-type = 'W'.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
