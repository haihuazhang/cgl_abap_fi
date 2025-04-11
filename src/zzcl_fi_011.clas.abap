CLASS zzcl_fi_011 DEFINITION
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

    DATA : job_template   TYPE cl_apj_rt_api=>ty_template_name,
           start_date     TYPE datum,
           end_date       TYPE datum,
           rate_type      TYPE kurst_curr,
           currency_range TYPE cl_apj_rt_api=>tt_value_range,
           job_text       TYPE cl_apj_rt_api=>ty_job_text.


    METHODS init_application_log.
    METHODS add_text_to_app_log_or_console IMPORTING i_text TYPE cl_bali_free_text_setter=>ty_text
                                                     i_type TYPE cl_bali_free_text_setter=>ty_severity OPTIONAL.
*                                           RAISING   cx_bali_runtime.
    METHODS add_except_to_log_or_console IMPORTING ix_exception TYPE REF TO cx_root.

    METHODS add_msg_to_app_log_or_console IMPORTING messages TYPE bapirettab.

    METHODS : get_parameters IMPORTING it_parameters TYPE if_apj_dt_exec_object=>tt_templ_val
                             RAISING
                                       cx_apj_rt .

    METHODS : get_start_date IMPORTING periodic_granularity TYPE cl_apj_rt_api=>ty_job_periodic_granularity
                                       periodic_value       TYPE cl_apj_rt_api=>ty_periodicity_info-periodic_value
                                       end_date             TYPE datum
                             RETURNING VALUE(start_date)    TYPE datum
                             RAISING
                                       cx_parameter_invalid_range
                                       cx_parameter_invalid_type.

ENDCLASS.



CLASS ZZCL_FI_011 IMPLEMENTATION.


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
        WHEN 'P_JOB'.
          job_template = ls_parameter-low.
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

    DATA: jobname   TYPE cl_apj_rt_api=>ty_jobname.
    DATA: jobcount  TYPE cl_apj_rt_api=>ty_jobcount.
    DATA: catalog   TYPE cl_apj_rt_api=>ty_catalog_name.
    DATA: template  TYPE cl_apj_rt_api=>ty_template_name.
*      TRY.
    cl_apj_rt_api=>get_job_runtime_info(
                        IMPORTING
                          ev_jobname        = jobname
                          ev_jobcount       = jobcount
                          ev_catalog_name   = catalog
                          ev_template_name  = template ).

    "Get Start date and end date
    DATA(periodicity_info) = cl_apj_rt_api=>get_job_periodicity_info(
       EXPORTING
        iv_jobname = jobname
    ).

    DATA(job_info) = cl_apj_rt_api=>get_job_details(
        EXPORTING
            iv_jobcount = jobcount
            iv_jobname = jobname
    ).

    job_text = job_info-job_text.
    end_date = cl_abap_context_info=>get_system_date(  ).
    start_date = get_start_date( end_date = end_date periodic_granularity = periodicity_info-periodic_granularity periodic_value = periodicity_info-periodic_value ).


  ENDMETHOD.


  METHOD get_start_date.
    CASE periodic_granularity.
      WHEN cl_apj_rt_api=>period_minutes OR cl_apj_rt_api=>period_hours.
        start_date = end_date.


      WHEN cl_apj_rt_api=>period_days.
        start_date =   xco_cp_time=>date(
                                    iv_year = end_date(4)
                                    iv_month = end_date+4(2)
                                    iv_day = end_date+6(2)
                                 )->subtract( iv_year = 0 iv_month = 0 iv_day = CONV i( periodic_value ) )->as( io_format = xco_cp_time=>format->abap  )->value .
      WHEN cl_apj_rt_api=>period_weeks.
        DATA(days) = periodic_value * 7.
        start_date =   xco_cp_time=>date(
                                            iv_year = end_date(4)
                                            iv_month = end_date+4(2)
                                            iv_day = end_date+6(2)
                                         )->subtract( iv_year = 0 iv_month = 0 iv_day = days  )->as( io_format = xco_cp_time=>format->abap  )->value .
      WHEN cl_apj_rt_api=>period_months.

        start_date =   xco_cp_time=>date(
                              iv_year = end_date(4)
                              iv_month = end_date+4(2)
                              iv_day = end_date+6(2)
                           )->subtract( iv_year = 0 iv_month = CONV i( periodic_value ) iv_day = 0 )->as( io_format = xco_cp_time=>format->abap  )->value .

    ENDCASE.
  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.
    et_parameter_def = VALUE #(
        (
            selname = 'P_JOB'
            kind = if_apj_dt_exec_object=>parameter
            datatype = 'C'
            length = 40
            param_text = 'Job Template Name of Exchange Rates'
            component_type = 'APJ_JOB_TEMPLATE_NAME'
            changeable_ind = abap_true
            mandatory_ind = abap_true
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
    DATA job_start_info TYPE cl_apj_rt_api=>ty_start_info.
    DATA job_parameters TYPE cl_apj_rt_api=>tt_job_parameter_value.
    DATA job_parameter TYPE cl_apj_rt_api=>ty_job_parameter_value.
    DATA range_value TYPE cl_apj_rt_api=>ty_value_range.
    DATA job_name TYPE cl_apj_rt_api=>ty_jobname.
    DATA job_count TYPE cl_apj_rt_api=>ty_jobcount.

    init_application_log(  ).
    TRY.
        get_parameters( it_parameters ).
      CATCH cx_apj_rt INTO DATA(lx_apj_rt).
        "handle exception
        add_except_to_log_or_console( ix_exception = lx_apj_rt ).
    ENDTRY.







    job_start_info-start_immediately = abap_true.

    job_parameter-name = 'P_RTYPE' . "'INVENT'.
    job_parameter-t_value = VALUE #( (
        sign = 'I'
        option = 'EQ'
        low = rate_type
    ) ).
    APPEND job_parameter TO job_parameters.

    job_parameter-name = 'S_CURR' . "'INVENT'.
    job_parameter-t_value = currency_range.
    APPEND job_parameter TO job_parameters.

    job_parameter-name = 'P_FRDATE'. "'INVENT'.
    job_parameter-t_value = VALUE #( (
    sign = 'I'
    option = 'EQ'
    low = start_date
    ) ).
    APPEND job_parameter TO job_parameters.

    job_parameter-name = 'P_TODATE'.
    job_parameter-t_value = VALUE #( (
        sign = 'I'
        option = 'EQ'
        low = end_date
    ) ).
    APPEND job_parameter TO job_parameters.


    TRY.
*        DATA: job_text TYPE cl_apj_rt_api=>ty_job_text.

        job_text = |Exchange rate sub jobs for - { job_text } - from { start_date } to { end_date }  |.
        cl_apj_rt_api=>schedule_job(
          EXPORTING
          iv_job_template_name = job_template
          iv_job_text = job_text
          is_start_info = job_start_info
          it_job_parameter_value = job_parameters
          IMPORTING
            ev_jobname  = job_name
            ev_jobcount = job_count
          ).
        add_text_to_app_log_or_console( i_text = CONV cl_bali_free_text_setter=>ty_text( job_text ) i_type = if_bali_constants=>c_severity_status ).
      CATCH cx_apj_rt INTO lx_apj_rt.
        "handle exception
        add_except_to_log_or_console( ix_exception = lx_apj_rt ).
    ENDTRY.


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
    start_date =    xco_cp_time=>date(
                            iv_year = current_date(4)
                            iv_month = current_date+4(2)
                            iv_day = current_date+6(2)
                         )->subtract( iv_year = 0 iv_month = 0 iv_day = 1 )->as( io_format = xco_cp_time=>format->abap  )->value .
    end_date = current_date.
    job_text = 'PBC'.
    job_template = 'ZZ_JCE_EXRATE_PBC'.



    DATA job_start_info TYPE cl_apj_rt_api=>ty_start_info.
    DATA job_parameters TYPE cl_apj_rt_api=>tt_job_parameter_value.
    DATA job_parameter TYPE cl_apj_rt_api=>ty_job_parameter_value.
    DATA range_value TYPE cl_apj_rt_api=>ty_value_range.
    DATA job_name TYPE cl_apj_rt_api=>ty_jobname.
    DATA job_count TYPE cl_apj_rt_api=>ty_jobcount.







    job_start_info-start_immediately = abap_true.

    job_parameter-name = 'P_RTYPE' . "'INVENT'.
    job_parameter-t_value = VALUE #( (
        sign = 'I'
        option = 'EQ'
        low = rate_type
    ) ).
    APPEND job_parameter TO job_parameters.

    job_parameter-name = 'S_CURR' . "'INVENT'.
    job_parameter-t_value = currency_range.
    APPEND job_parameter TO job_parameters.

    job_parameter-name = 'P_FRDATE'. "'INVENT'.
    job_parameter-t_value = VALUE #( (
    sign = 'I'
    option = 'EQ'
    low = start_date
    ) ).
    APPEND job_parameter TO job_parameters.

    job_parameter-name = 'P_TODATE'.
    job_parameter-t_value = VALUE #( (
        sign = 'I'
        option = 'EQ'
        low = end_date
    ) ).
    APPEND job_parameter TO job_parameters.


    TRY.
*        DATA: job_text TYPE cl_apj_rt_api=>ty_job_text.

        job_text = |Exchange rate sub jobs for - { job_text } - from { start_date } to { end_date }  |.
        cl_apj_rt_api=>schedule_job(
          EXPORTING
          iv_job_template_name = job_template
          iv_job_text = job_text
          is_start_info = job_start_info
          it_job_parameter_value = job_parameters
          IMPORTING
            ev_jobname  = job_name
            ev_jobcount = job_count
          ).
*        add_text_to_app_log_or_console( i_text = CONV cl_bali_free_text_setter=>ty_text( job_text ) i_type = if_bali_constants=>c_severity_status ).
        out->write( job_text ).
      CATCH cx_apj_rt INTO DATA(lx_apj_rt).
        "handle exception
        add_except_to_log_or_console( ix_exception = lx_apj_rt ).
    ENDTRY.


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
ENDCLASS.
