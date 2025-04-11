*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
*if_xco_xlsx_ra_cs_visitor
*CLASS lcl_xlsx_visitor_currency DEFINITION.
*  PUBLIC SECTION.
*    INTERFACES if_xco_xlsx_ra_cs_visitor.
*    TYPES: BEGIN OF ts_currency,
*             currency TYPE waers,
*             cell     TYPE c,
*           END OF ts_currency.
*
*ENDCLASS.
*
*CLASS lcl_xlsx_visitor_currency IMPLEMENTATION.
*
*  METHOD if_xco_xlsx_ra_cs_visitor~visit_cell.
*
*  ENDMETHOD.
*
*ENDCLASS.
CLASS lcl_xlsx_process_rates DEFINITION.
  PUBLIC SECTION.
    TYPES : BEGIN OF ts_rates,
              source_exchangerate TYPE p LENGTH 16 DECIMALS 10,
              exchangerate        TYPE fin_exchange_rate,
              from_factor         TYPE ffact_curr,
              to_factor           TYPE tfact_curr,
              date                TYPE datum,
            END OF ts_rates,
            tt_rates TYPE STANDARD TABLE OF ts_rates WITH DEFAULT KEY,
            BEGIN OF ts_currency,
              from_currency      TYPE waers,
              to_currency        TYPE waers,
              source_from_factor TYPE ffact_curr,
              source_to_factor   TYPE tfact_curr,

              position           TYPE i,
              rates              TYPE tt_rates,
            END OF ts_currency,
            tt_currency TYPE STANDARD TABLE OF ts_currency WITH DEFAULT KEY,
            BEGIN OF ts_date,
              date TYPE datum,
              line TYPE i,
            END OF ts_date,
            BEGIN OF ts_range_currency,
              sign   TYPE c LENGTH 1,
              option TYPE c LENGTH 2,
              low    TYPE zzefi039,
              high   TYPE zzefi039,
            END OF ts_range_currency,
            tt_range_currency TYPE STANDARD TABLE OF ts_range_currency WITH DEFAULT KEY,
            BEGIN OF ts_head,
              version     TYPE string,
              provider    TYPE string,
              req_code    TYPE string,
              rep_code    TYPE string,
              rep_message TYPE string,
            END OF ts_head,
            BEGIN OF ts_data,
              total       TYPE i,
              startdate   TYPE string,
              pagetotal   TYPE i,
              searchlist  TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
              head        TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
              pagesize    TYPE i,
              enddate     TYPE string,
              flagmessage TYPE string,
              currency    TYPE string,
              pagenum     TYPE i,
            END OF ts_data,
            BEGIN OF ts_record,
              date   TYPE string,
              values TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
            END OF ts_record,
            tt_record TYPE STANDARD TABLE OF ts_record WITH DEFAULT KEY,
            BEGIN OF ts_json,
              head    TYPE ts_head,
              data    TYPE ts_data,
              records TYPE tt_record,
            END OF ts_json.



    DATA : currencies     TYPE TABLE OF ts_currency,
           dates          TYPE TABLE OF ts_date,
           start_date     TYPE datum,
           end_date       TYPE datum,
           rate_type      TYPE kurst,
           currency_range TYPE tt_range_currency,
           data_in_json   TYPE string,
           json           TYPE ts_json.

    CONSTANTS : BEGIN OF cny_currency,
                  currency              TYPE waers VALUE 'CNY',
                  source_factor_as_from TYPE ffact_curr VALUE '1', " currently did not get HUF's factor from bank file as source factor, set it default.
                  source_factor_as_to   TYPE tfact_curr VALUE '1',
                END OF cny_currency.

    METHODS : constructor
      IMPORTING start_date     TYPE datum
                end_date       TYPE datum OPTIONAL
                rate_type      TYPE kurst
*                worksheet      TYPE REF TO if_xco_xlsx_ra_worksheet
                data_in_json   TYPE string
                currency_range TYPE tt_range_currency OPTIONAL.

    METHODS : get_currencies_from_file
      IMPORTING
*        worksheet TYPE REF TO if_xco_xlsx_ra_worksheet.
        json TYPE ts_json.

    METHODS : get_factors_from_file
      IMPORTING
*        worksheet TYPE REF TO if_xco_xlsx_ra_worksheet.
        json TYPE ts_json.

    METHODS : get_dates_from_file
      IMPORTING
*        worksheet TYPE REF TO if_xco_xlsx_ra_worksheet
        json TYPE ts_json
      RAISING
        cx_abap_datfm_no_date
        cx_abap_datfm_invalid_date
        cx_abap_datfm_format_unknown
        cx_abap_datfm_ambiguous.

    METHODS : get_rates_from_file
      IMPORTING
*        worksheet TYPE REF TO if_xco_xlsx_ra_worksheet.
        json TYPE ts_json
      RAISING
        cx_abap_datfm_no_date
        cx_abap_datfm_invalid_date
        cx_abap_datfm_format_unknown
        cx_abap_datfm_ambiguous.

    METHODS : process
*      IMPORTING
*                worksheet         TYPE REF TO if_xco_xlsx_ra_worksheet
      RETURNING VALUE(currencies) TYPE tt_currency
      RAISING
                cx_abap_datfm_no_date
                cx_abap_datfm_invalid_date
                cx_abap_datfm_format_unknown
                cx_abap_datfm_ambiguous
                zzcx_fi_001.

    METHODS : get_factor_from_cds
      IMPORTING from_currency TYPE waers
                to_currency   TYPE waers
                rate_type     TYPE kurst
                date          TYPE datum
      EXPORTING
                from_factor   TYPE ffact_curr
                to_factor     TYPE tfact_curr.

    METHODS : get_str_by_regex
      IMPORTING
                source_string TYPE string
                regex         TYPE string
      RETURNING VALUE(str)
                  TYPE string.

*    METHODS :
  PRIVATE SECTION.
    CONSTANTS : BEGIN OF cny_cursor,
                  currency_from_line   TYPE i VALUE 1,
                  currency_from_column TYPE string VALUE 'B',
                  factor_from_line     TYPE i VALUE 2,
                  factor_from_column   TYPE string VALUE 'B',
                  rate_from_line       TYPE i VALUE 2,
                  rate_from_column     TYPE string VALUE 'B',
                  date_from_line       TYPE i VALUE 2,
                  date_from_column     TYPE string VALUE 'A',
                END OF cny_cursor.
ENDCLASS.

CLASS lcl_xlsx_process_rates IMPLEMENTATION.

  METHOD get_currencies_from_file.

    DATA: from_currency     TYPE string,
          to_currency       TYPE string,
          currency_pair_str TYPE string,
          from_factor_str   TYPE string,
          to_factor_str     TYPE string,
          position          TYPE i.

    LOOP AT json-data-head INTO currency_pair_str.
      position = sy-tabix.


      SPLIT currency_pair_str AT '/' INTO DATA(lv_curr_from_str) DATA(lv_curr_to_str).

      from_factor_str = me->get_str_by_regex( regex = '[0-9]+' source_string = lv_curr_from_str ).
      from_currency = me->get_str_by_regex( regex = '[^0-9]+' source_string = lv_curr_from_str ).

      to_factor_str = me->get_str_by_regex( regex = '[0-9]+' source_string = lv_curr_to_str ).
      to_currency = me->get_str_by_regex( regex = '[^0-9]+' source_string = lv_curr_to_str ).





      DATA(currency_pair) = |{ from_currency }/{ to_currency }|.
      DATA(currency_pair_v) = |{ to_currency }/{ from_currency }|.

      IF currency_pair IN currency_range.

        APPEND VALUE #(
          to_currency = to_currency
          from_currency = from_currency
          source_to_factor = COND #(   WHEN to_factor_str = space THEN 1 ELSE to_factor_str )
          source_from_factor = COND #(   WHEN from_factor_str = space THEN 1 ELSE from_factor_str )
          position = position
        ) TO currencies REFERENCE INTO DATA(currency).

      ENDIF.

      IF currency_pair_v IN currency_range.
        APPEND VALUE #(
            to_currency = from_currency
            from_currency = to_currency
            source_to_factor = COND #(   WHEN from_factor_str = space THEN 1 ELSE from_factor_str )
            source_from_factor = COND #(   WHEN to_factor_str = space THEN 1 ELSE to_factor_str )
            position = position
          ) TO currencies.
      ENDIF.
    ENDLOOP.



  ENDMETHOD.

  METHOD get_factors_from_file.
*    LOOP AT currencies ASSIGNING FIELD-SYMBOL(<currency>).
*      DATA(cursor) = worksheet->cursor(
*           io_column = xco_cp_xlsx=>coordinate->for_alphabetic_value( <currency>-cell_column )
*           io_row    = xco_cp_xlsx=>coordinate->for_numeric_value( lcl_xlsx_process_rates=>cny_cursor-factor_from_line )
*       ).
*      IF cursor->has_cell( ) EQ abap_true
*      AND cursor->get_cell( )->has_value( ) EQ abap_true.
*
*        DATA(cell_column) = cursor->position->column->get_alphabetic_value(  ).
*
*        DATA(cell) = cursor->get_cell( ).
*        "check from or to
*        IF <currency>-to_currency = lcl_xlsx_process_rates=>cny_currency-currency.
*          cell->get_value(
*            )->set_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
*            )->write_to( REF #( <currency>-source_from_factor  ) ).
*        ELSE.
*          cell->get_value(
*            )->set_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
*            )->write_to( REF #( <currency>-source_to_factor  ) ).
*        ENDIF.
*
*      ENDIF.
*    ENDLOOP.
  ENDMETHOD.

  METHOD get_dates_from_file.
*    DATA(cursor) = worksheet->cursor(
*        io_column = xco_cp_xlsx=>coordinate->for_alphabetic_value( lcl_xlsx_process_rates=>cny_cursor-date_from_column )
*        io_row    = xco_cp_xlsx=>coordinate->for_numeric_value( lcl_xlsx_process_rates=>cny_cursor-date_from_line )
*    ).
*    WHILE cursor->has_cell( ) EQ abap_true
*    AND cursor->get_cell( )->has_value( ) EQ abap_true.
*
*      DATA : lv_date     TYPE datum,
*             lv_date_str TYPE c LENGTH 10.
*      DATA(cell) = cursor->get_cell( ).
*      cell->get_value(
*        )->set_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
*        )->write_to( REF #( lv_date_str ) ).
*      cl_abap_datfm=>conv_date_ext_to_int(
*        EXPORTING
*            im_datext = lv_date_str
*            im_datfmdes = '6'
*        IMPORTING
*            ex_datint = lv_date
*
*      ).
*
*      IF lv_date >= start_date AND lv_date <= end_date.
*        APPEND VALUE #(
*          line = cursor->position->row->get_numeric_value(  )
*          date = lv_date
*        ) TO dates REFERENCE INTO DATA(date).
*      ENDIF.
*
*      CLEAR lv_date.
*
*      cursor->move_down( ).
*    ENDWHILE.
  ENDMETHOD.

  METHOD constructor.
    me->start_date = start_date.
    IF end_date IS INITIAL.
      me->end_date = cl_abap_context_info=>get_system_date(  ).
    ELSE.
      me->end_date = end_date.
    ENDIF.
*    me->worksheet = worksheet.
    me->data_in_json = data_in_json.
    me->currency_range = currency_range.
    me->rate_type = rate_type.
  ENDMETHOD.

  METHOD get_rates_from_file.

    LOOP AT currencies ASSIGNING FIELD-SYMBOL(<currency>).
      LOOP AT json-records ASSIGNING FIELD-SYMBOL(<date>).

        cl_abap_datfm=>conv_date_ext_to_int(
            EXPORTING
                im_datext = <date>-date
                im_datfmdes = '6'
             IMPORTING
                ex_datint = DATA(dat_int)
        ).

        APPEND VALUE #(
          date = dat_int
         ) TO <currency>-rates REFERENCE INTO DATA(rate).

        DATA exchangerate TYPE string.

        exchangerate = <date>-values[ <currency>-position ].
        CONDENSE exchangerate.

        rate->source_exchangerate = exchangerate.
        " Check from/to and adjust source exchange rate
        IF <currency>-from_currency = lcl_xlsx_process_rates=>cny_currency-currency.
          rate->source_exchangerate = 1 / rate->source_exchangerate.
        ENDIF.

        "Get Factor from CDS
        me->get_factor_from_cds(
          EXPORTING
              date = dat_int
              from_currency = <currency>-from_currency
              to_currency = <currency>-to_currency
              rate_type = me->rate_type
          IMPORTING
              from_factor = rate->from_factor
              to_factor = rate->to_factor
        ).

        IF rate->from_factor = 0 OR rate->to_factor = 0.
          CONTINUE.
        ENDIF.

        "calculate exchange rate for factor from CDS (fator from source bank will be converted to configuration maintained in SAP)
        rate->exchangerate = rate->source_exchangerate / <currency>-source_from_factor * <currency>-source_to_factor * rate->from_factor / rate->to_factor.


      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD process.
    "parse as json
    /ui2/cl_json=>deserialize(
        EXPORTING
            json = data_in_json
        CHANGING
            data = json
    ).


    IF json-head-rep_code <> '200'.
      RAISE EXCEPTION TYPE zzcx_fi_001
        EXPORTING
          textid = VALUE #(
          msgid = 'ZZFI'
          msgno = '013'
          attr1 = json-head-rep_message
          ).
    ENDIF.


*    me->get_dates_from_file( json ).

    me->get_currencies_from_file( json ).

*    me->get_factors_from_file( worksheet ).

    me->get_rates_from_file( json ).
    currencies = me->currencies.
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

  METHOD get_str_by_regex.
    DATA: lo_regex   TYPE REF TO cl_abap_regex,
          lo_matcher TYPE REF TO cl_abap_matcher.
    lo_regex = cl_abap_regex=>create_pcre(
                 pattern = regex ).
    lo_matcher = lo_regex->create_matcher(
                text = source_string ).
    DATA(lt_result_tab) = lo_matcher->find_all( ).
    LOOP AT lt_result_tab INTO DATA(ls_result_tab).
      " 从 lv_text 中截取匹配的子串，ls_result_tab-offset 为起始位置，
      " ls_result_tab-length 为匹配长度
      CONCATENATE str source_string+ls_result_tab-offset(ls_result_tab-length) INTO str.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
