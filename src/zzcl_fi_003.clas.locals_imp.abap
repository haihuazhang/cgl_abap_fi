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

              cell_column        TYPE c LENGTH 10,
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
            tt_range_currency TYPE STANDARD TABLE OF ts_range_currency WITH DEFAULT KEY.
    DATA : currencies     TYPE TABLE OF ts_currency,
           dates          TYPE TABLE OF ts_date,
           start_date     TYPE datum,
           end_date       TYPE datum,
           rate_type      TYPE kurst,
           currency_range TYPE tt_range_currency,
           worksheet      TYPE REF TO if_xco_xlsx_ra_worksheet.

    CONSTANTS : BEGIN OF mnb_currency,
                  currency              TYPE waers VALUE 'HUF',
                  source_factor_as_from TYPE ffact_curr VALUE '1', " currently did not get HUF's factor from bank file as source factor, set it default.
                  source_factor_as_to   TYPE tfact_curr VALUE '1',
                END OF mnb_currency.

    METHODS : constructor
      IMPORTING start_date     TYPE datum
                end_date       TYPE datum OPTIONAL
                rate_type      TYPE kurst
                worksheet      TYPE REF TO if_xco_xlsx_ra_worksheet
                currency_range TYPE tt_range_currency OPTIONAL.

    METHODS : get_currencies_from_file
      IMPORTING
        worksheet TYPE REF TO if_xco_xlsx_ra_worksheet.

    METHODS : get_factors_from_file
      IMPORTING
        worksheet TYPE REF TO if_xco_xlsx_ra_worksheet.

    METHODS : get_dates_from_file
      IMPORTING
        worksheet TYPE REF TO if_xco_xlsx_ra_worksheet.

    METHODS : get_rates_from_file
      IMPORTING
        worksheet TYPE REF TO if_xco_xlsx_ra_worksheet.

    METHODS : process
*      IMPORTING
*                worksheet         TYPE REF TO if_xco_xlsx_ra_worksheet
      RETURNING VALUE(currencies) TYPE tt_currency.

    METHODS : get_factor_from_cds
      IMPORTING from_currency TYPE waers
                to_currency   TYPE waers
                rate_type     TYPE kurst
                date          TYPE datum
      EXPORTING
                from_factor   TYPE ffact_curr
                to_factor     TYPE tfact_curr.

*    METHODS :
  PRIVATE SECTION.
    CONSTANTS : BEGIN OF mnb_cursor,
                  currency_from_line   TYPE i VALUE 1,
                  currency_from_column TYPE string VALUE 'B',
                  factor_from_line     TYPE i VALUE 2,
                  factor_from_column   TYPE string VALUE 'B',
                  rate_from_line       TYPE i VALUE 3,
                  rate_from_column     TYPE string VALUE 'B',
                  date_from_line       TYPE i VALUE 8438,
                  date_from_column     TYPE string VALUE 'A',
                END OF mnb_cursor.
ENDCLASS.

CLASS lcl_xlsx_process_rates IMPLEMENTATION.

  METHOD get_currencies_from_file.

    DATA(cursor) = worksheet->cursor(
        io_column = xco_cp_xlsx=>coordinate->for_alphabetic_value( lcl_xlsx_process_rates=>mnb_cursor-currency_from_column )
        io_row    = xco_cp_xlsx=>coordinate->for_numeric_value( lcl_xlsx_process_rates=>mnb_cursor-currency_from_line )
    ).
    WHILE cursor->has_cell( ) EQ abap_true
    AND cursor->get_cell( )->has_value( ) EQ abap_true.

      DATA(cell) = cursor->get_cell( ).
      DATA: from_currency TYPE string.

      cell->get_value(
        )->set_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
        )->write_to( REF #( from_currency ) ).

      DATA(currency_pair) = |{ from_currency }/{ lcl_xlsx_process_rates=>mnb_currency-currency }|.
      DATA(currency_pair_v) = |{ lcl_xlsx_process_rates=>mnb_currency-currency }/{ from_currency }|.

      IF currency_pair IN currency_range.

        APPEND VALUE #(
          to_currency = lcl_xlsx_process_rates=>mnb_currency-currency
          source_to_factor = lcl_xlsx_process_rates=>mnb_currency-source_factor_as_to
          from_currency = from_currency
          cell_column = cursor->position->column->get_alphabetic_value(  )
        ) TO currencies REFERENCE INTO DATA(currency).

      ENDIF.

      IF currency_pair_v IN currency_range.
        APPEND VALUE #(
            to_currency = from_currency
            from_currency = lcl_xlsx_process_rates=>mnb_currency-currency
            source_from_factor = lcl_xlsx_process_rates=>mnb_currency-source_factor_as_from
            cell_column = cursor->position->column->get_alphabetic_value(  )
          ) TO currencies.
      ENDIF.

      " Move the cursor right one column.
      cursor->move_right( ).

    ENDWHILE.

  ENDMETHOD.

  METHOD get_factors_from_file.
    LOOP AT currencies ASSIGNING FIELD-SYMBOL(<currency>).
      DATA(cursor) = worksheet->cursor(
           io_column = xco_cp_xlsx=>coordinate->for_alphabetic_value( <currency>-cell_column )
           io_row    = xco_cp_xlsx=>coordinate->for_numeric_value( lcl_xlsx_process_rates=>mnb_cursor-factor_from_line )
       ).
      IF cursor->has_cell( ) EQ abap_true
      AND cursor->get_cell( )->has_value( ) EQ abap_true.

        DATA(cell_column) = cursor->position->column->get_alphabetic_value(  ).

        DATA(cell) = cursor->get_cell( ).
        "check from or to
        IF <currency>-to_currency = lcl_xlsx_process_rates=>mnb_currency-currency.
          cell->get_value(
            )->set_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
            )->write_to( REF #( <currency>-source_from_factor  ) ).
        ELSE.
          cell->get_value(
            )->set_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
            )->write_to( REF #( <currency>-source_to_factor  ) ).
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_dates_from_file.
    DATA(cursor) = worksheet->cursor(
        io_column = xco_cp_xlsx=>coordinate->for_alphabetic_value( lcl_xlsx_process_rates=>mnb_cursor-date_from_column )
        io_row    = xco_cp_xlsx=>coordinate->for_numeric_value( lcl_xlsx_process_rates=>mnb_cursor-date_from_line )
    ).
    WHILE cursor->has_cell( ) EQ abap_true
    AND cursor->get_cell( )->has_value( ) EQ abap_true.

      DATA : lv_date TYPE datum.
      DATA(cell) = cursor->get_cell( ).
      cell->get_value(
        )->set_transformation( xco_cp_xlsx_read_access=>value_transformation->best_effort
        )->write_to( REF #( lv_date ) ).

      IF lv_date >= start_date AND lv_date <= end_date.
        APPEND VALUE #(
          line = cursor->position->row->get_numeric_value(  )
          date = lv_date
        ) TO dates REFERENCE INTO DATA(date).
      ENDIF.

      CLEAR lv_date.

      cursor->move_down( ).
    ENDWHILE.
  ENDMETHOD.

  METHOD constructor.
    me->start_date = start_date.
    IF end_date IS INITIAL.
      me->end_date = cl_abap_context_info=>get_system_date(  ).
    ELSE.
      me->end_date = end_date.
    ENDIF.
    me->worksheet = worksheet.
    me->currency_range = currency_range.
    me->rate_type = rate_type.
  ENDMETHOD.

  METHOD get_rates_from_file.

    LOOP AT currencies ASSIGNING FIELD-SYMBOL(<currency>).
      LOOP AT dates ASSIGNING FIELD-SYMBOL(<date>).

        DATA(cursor) = worksheet->cursor(
            io_column = xco_cp_xlsx=>coordinate->for_alphabetic_value( <currency>-cell_column )
            io_row    = xco_cp_xlsx=>coordinate->for_numeric_value( <date>-line )
        ).
        IF cursor->has_cell( ) EQ abap_true
            AND cursor->get_cell( )->has_value( ) EQ abap_true.

          APPEND VALUE #(
            date = <date>-date
           ) TO <currency>-rates REFERENCE INTO DATA(rate).
          DATA exchangerate TYPE string.
          DATA(cell) = cursor->get_cell( ).

          cell->get_value(
            )->set_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
            )->write_to( REF #( exchangerate ) ).

          rate->source_exchangerate = exchangerate.
          " Check from/to and adjust source exchange rate
          IF <currency>-from_currency = lcl_xlsx_process_rates=>mnb_currency-currency.
            rate->source_exchangerate = 1 / rate->source_exchangerate.
          ENDIF.

          "Get Factor from CDS
          me->get_factor_from_cds(
            EXPORTING
                date = <date>-date
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

        ENDIF.


      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD process.
    me->get_dates_from_file( worksheet ).

    me->get_currencies_from_file( worksheet ).

    me->get_factors_from_file( worksheet ).

    me->get_rates_from_file( worksheet ).
    currencies = me->currencies.
  ENDMETHOD.

  METHOD get_factor_from_cds.
    SELECT SINGLE
        numberofsourcecurrencyunits,
        numberoftargetcurrencyunits
        FROM ZR_SFI034( p_date = @date ) WITH PRIVILEGED ACCESS
        WHERE exchangeratetype = @rate_type
          AND sourcecurrency = @from_currency
          AND targetcurrency = @to_currency
*          AND validitystartdate <= @date
          INTO ( @from_factor , @to_factor ).
  ENDMETHOD.

ENDCLASS.
