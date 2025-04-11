CLASS zzcl_fi_006 DEFINITION
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
    CONSTANTS : BEGIN OF file_path,
                  url TYPE string VALUE '/A/',
                END OF file_path.

    DATA : start_date     TYPE datum,
           end_date       TYPE datum,
           rate_type      TYPE kurst_curr,
           currency_range TYPE tt_range_currency.
    TYPES: BEGIN OF ty_rate,
             currency TYPE string,
             code     TYPE string,
             mid      TYPE string,
           END OF ty_rate.
    TYPES: t_rates TYPE STANDARD TABLE OF ty_rate WITH EMPTY KEY.

    TYPES: BEGIN OF ty_get_receive,
             table         TYPE string,
             no            TYPE string,
             effectivedate TYPE string,
             rates         TYPE t_rates,
           END OF ty_get_receive.
    DATA ls_get_receive TYPE TABLE OF ty_get_receive.
    METHODS: get_ratefile RETURNING VALUE(lv_json) TYPE string
                          RAISING
                                    cx_http_dest_provider_error
                                    cx_web_http_client_error.
    METHODS: parse_ratefile
      IMPORTING lv_json        TYPE string
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

    METHODS : get_factor_from_cds
      IMPORTING from_currency TYPE waers
                to_currency   TYPE waers
                rate_type     TYPE kurst
                date          TYPE datum
      EXPORTING
                from_factor   TYPE ffact_curr
                to_factor     TYPE tfact_curr.


ENDCLASS.



CLASS ZZCL_FI_006 IMPLEMENTATION.


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
        EXIT.
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


  METHOD get_factor_from_cds.
    SELECT SINGLE
        numberofsourcecurrencyunits,
        numberoftargetcurrencyunits
        FROM zr_sfi034( p_date = @date ) WITH PRIVILEGED ACCESS
        WHERE exchangeratetype = @rate_type
          AND sourcecurrency = @from_currency
          AND targetcurrency = @to_currency
*          AND validitystartdate <= @date
          INTO ( @from_factor , @to_factor ).
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
           service_id     = 'ZZOS_FI_004_REST'
           comm_system_id = 'NBP'
      ).
    DATA(http_client) = cl_web_http_client_manager=>create_by_http_destination( destination ).
    DATA(request) = http_client->get_http_request( ).

************测试数据
    DATA(current_date) = cl_abap_context_info=>get_system_date(  ).

   " 计算前一天的日期
   DATA : previous_date TYPE DATUM.
    previous_date = cl_abap_context_info=>get_system_date(  ) - 5.

    IF start_date IS INITIAL .
      DATA(lv_start_date) = previous_date+0(4)  && '-' && previous_date+4(2) && '-' && previous_date+6(2).
     ELSE.
     lv_start_date = start_date+0(4)  && '-' && start_date+4(2) && '-' && start_date+6(2).
    ENDIF.

    IF end_date IS INITIAL .
      DATA(lv_end_date) = current_date+0(4) && '-' && current_date+4(2) && '-' && current_date+6(2).
      ELSE.
      lv_end_date = end_date+0(4) && '-' && end_date+4(2) && '-' && end_date+6(2).
    ENDIF.
*************

    request->set_uri_path( zzcl_fi_006=>file_path-url && lv_start_date && '/' && lv_end_date && '/' ).
    request->set_content_type( content_type = 'application/json; charset=utf-8' ).

    DATA(response) = http_client->execute( if_web_http_client=>get ).

    lv_json = response->get_text( ).


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
            param_text = 'Currency Pairs(Maintain in format: ISO/ISO, e.g., USD/EUR)'
            component_type = 'ZZEFI039'
            changeable_ind = abap_true
            mandatory_ind = abap_false
            section_text = 'Maintain in format: ISO/ISO, e.g., USD/EUR'
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
      CATCH cx_http_dest_provider_error cx_web_http_client_error INTO DATA(lx_http).
        "handle exception
*        out->write( lx_http->get_longtext(  ) ).
        add_except_to_log_or_console(
            ix_exception = lx_http
        ).
        RETURN.
    ENDTRY.

    TRY.
        DATA(rates) = parse_ratefile(
            lv_json = file
            currency_range = currency_range
            rate_type = rate_type
         ).
      CATCH cx_abap_datfm_no_date cx_abap_datfm_invalid_date cx_abap_datfm_format_unknown cx_abap_datfm_ambiguous zzcx_fi_001 INTO DATA(lx_parse).
        "handle exception
*        out->write( lx_parse->get_longtext(  ) ).
        add_except_to_log_or_console(
            ix_exception = lx_http
        ).
        RETURN.
    ENDTRY.

    DATA(results) = sync_rates( rates = rates ).

*    out->write( results ).

    add_msg_to_app_log_or_console( messages = CONV bapirettab( results ) ).

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(lv_josn) = get_ratefile(  ).
      CATCH cx_http_dest_provider_error cx_web_http_client_error INTO DATA(lx_http).
        "handle exception
        out->write( lx_http->get_longtext(  ) ).
        RETURN.
    ENDTRY.


    DATA: s_curr    TYPE RANGE OF zzefi039,
          rate_type TYPE kurst_curr.
**********测试数据****************
    IF  currency_range IS INITIAL.

      s_curr = VALUE #(
          (
                low = 'HUF/PLN'
                sign = 'I'
                option = 'EQ'
            )
            (
                low = 'EUR/PLN'
                sign = 'I'
                option = 'EQ'
            )

            (
                low = 'PLN/EUR'
                sign = 'I'
                option = 'EQ'
            )



            (
                low = 'CZK/PLN'
                sign = 'I'
                option = 'EQ'
            )
            (
                low = 'USD/PLN'
                sign = 'I'
                option = 'EQ'
            )
            (
                low = 'CNY/PLN'
                sign = 'I'
                option = 'EQ'
            )

            (
                low = 'PLN/CNY'
                sign = 'I'
                option = 'EQ'
            )
            (
                low = 'HKD/PLN'
                sign = 'I'
                option = 'EQ'
            )
        ).
      currency_range = s_curr.
    ENDIF.

    IF rate_type IS INITIAL.
      rate_type = 'M'.
    ENDIF.
**********************
    TRY.
        DATA(rates) = parse_ratefile(
            lv_json = lv_josn
            currency_range = currency_range
            rate_type = rate_type
         ).
      CATCH zzcx_fi_001 cx_abap_datfm_no_date cx_abap_datfm_invalid_date cx_abap_datfm_format_unknown cx_abap_datfm_ambiguous INTO DATA(lx_parse).
        "handle exception
        out->write( lx_parse->get_longtext(  ) ).
        RETURN.
*      CATCH .
        "handle exception
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
                                                                       subobject = 'NBP'
                                                                       external_id = external_id ) ).
      CATCH cx_bali_runtime cx_uuid_error INTO DATA(lx_bali_runtime).
        "handle exception
        EXIT.
    ENDTRY.
  ENDMETHOD.


  METHOD parse_ratefile.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json
                                     pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                            CHANGING data = ls_get_receive ).
    DATA:lwa_rates TYPE LINE OF   cl_exchange_rates=>ty_exchange_rates.
    DATA:     from_currency      TYPE waers,
              to_currency        TYPE waers.
    DATA:lv_date TYPE DATUM.
    LOOP AT ls_get_receive INTO DATA(lwa_get_receive)   .
      lv_date = lwa_get_receive-effectivedate+0(4) && lwa_get_receive-effectivedate+5(2) && lwa_get_receive-effectivedate+8(2).
      LOOP AT currency_range INTO DATA(lwa_range).
        SPLIT lwa_range-low AT '/' INTO from_currency  to_currency.
        me->get_factor_from_cds(
          EXPORTING
              date = lv_date
              from_currency = from_currency
              to_currency   = to_currency
              rate_type     = rate_type
          IMPORTING
              from_factor   = DATA(from_factor)
              to_factor     = DATA(to_factor)
        ).
        IF   from_currency = 'PLN' .
          READ TABLE lwa_get_receive-rates INTO DATA(rate) WITH KEY code = to_currency.
          IF sy-subrc = 0.
            lwa_rates-from_curr = 'PLN'.
            lwa_rates-from_factor = from_factor.
            lwa_rates-rate_type = rate_type.
            lwa_rates-to_currncy = rate-code.
            lwa_rates-to_factor =  to_factor.
            lwa_rates-valid_from = lwa_get_receive-effectivedate+0(4) && lwa_get_receive-effectivedate+5(2) &&
            lwa_get_receive-effectivedate+8(2).
            lwa_rates-exch_rate = 1 / rate-mid  * from_factor / to_factor.
            APPEND lwa_rates TO  rates.
            CLEAR lwa_rates.
          ENDIF.
        ELSE.
          READ TABLE lwa_get_receive-rates INTO rate WITH KEY code = from_currency.
          IF sy-subrc = 0.
            lwa_rates-from_curr = rate-code.
            lwa_rates-from_factor = from_factor.
            lwa_rates-rate_type = rate_type.
            lwa_rates-to_currncy = 'PLN'.
            lwa_rates-to_factor = to_factor.
            lwa_rates-valid_from = lwa_get_receive-effectivedate+0(4) && lwa_get_receive-effectivedate+5(2) &&
            lwa_get_receive-effectivedate+8(2).
            lwa_rates-exch_rate = rate-mid * from_factor / to_factor.
            APPEND lwa_rates TO  rates.
            CLEAR lwa_rates.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD sync_rates.
    results = cl_exchange_rates=>put(
        exchange_rates = rates
        is_update_allowed = abap_true
    ).
     LOOP AT results ASSIGNING FIELD-SYMBOL(<result>) WHERE id = 'E!' AND number = '020'.
      <result>-type = 'W'.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
