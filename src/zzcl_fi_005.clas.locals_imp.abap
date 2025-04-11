*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lcl_xml_process_rates DEFINITION.
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

*              cell_column        TYPE c LENGTH 10,
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
    TYPES : BEGIN OF ts_sender,
              name TYPE string,
            END OF ts_sender,
            BEGIN OF ts_cube_currency,
              currency TYPE string,
              rate     TYPE string,
            END OF ts_cube_currency,
            tt_cube_currency TYPE STANDARD TABLE OF ts_cube_currency WITH DEFAULT KEY,
            BEGIN OF ts_cube_time,
              date TYPE string,
              cube TYPE tt_cube_currency,
            END OF ts_cube_time,
            tt_cube_time TYPE STANDARD TABLE OF ts_cube_time WITH DEFAULT KEY,
            BEGIN OF ts_cube,
              cube TYPE tt_cube_time,
            END OF ts_cube,
            BEGIN OF ts_envelope,
              subject TYPE string,
              sender  TYPE ts_sender,
              cube    TYPE STANDARD TABLE OF ts_cube WITH DEFAULT KEY,
            END OF ts_envelope.

    DATA : lt_envelope TYPE SORTED TABLE OF ts_envelope WITH UNIQUE KEY subject.
*    DATA : lt_cube TYPE TABLE OF ts_cube.
    DATA : currencies     TYPE TABLE OF ts_currency,
           dates          TYPE TABLE OF ts_date,
           start_date     TYPE datum,
           end_date       TYPE datum,
           rate_type      TYPE kurst,
           currency_range TYPE tt_range_currency,
           file           TYPE REF TO if_sxml_reader.

    CONSTANTS : BEGIN OF ecb_currency,
                  currency                      TYPE waers VALUE 'EUR',
                  source_factor_as_from         TYPE ffact_curr VALUE '1', " currently did not get HUF's factor from bank file as source factor, set it default.
                  source_factor_as_to           TYPE tfact_curr VALUE '1',
                  ecb_date_format_in_sap_domain TYPE c VALUE '6',
                END OF ecb_currency.

    METHODS : constructor
      IMPORTING start_date     TYPE datum
                end_date       TYPE datum OPTIONAL
                rate_type      TYPE kurst
                file           TYPE REF TO if_sxml_reader
                currency_range TYPE tt_range_currency OPTIONAL.

    METHODS : get_currencies_from_file
      IMPORTING
        file TYPE REF TO if_sxml_reader
      RAISING
        cx_abap_datfm_no_date
        cx_abap_datfm_invalid_date
        cx_abap_datfm_format_unknown
        cx_abap_datfm_ambiguous.

    METHODS : get_factors_from_file
      IMPORTING
        file TYPE REF TO if_sxml_reader.

    METHODS : get_dates_from_file
      IMPORTING
        file TYPE REF TO if_sxml_reader.

    METHODS : get_rates_from_file
      IMPORTING
        file TYPE REF TO if_sxml_reader
      RAISING
        cx_abap_datfm_no_date
        cx_abap_datfm_invalid_date
        cx_abap_datfm_format_unknown
        cx_abap_datfm_ambiguous.

    METHODS : process
*      IMPORTING
*                file         TYPE REF TO if_sxml_reader
      RETURNING VALUE(currencies) TYPE tt_currency
      RAISING
                cx_abap_datfm_no_date
                cx_abap_datfm_invalid_date
                cx_abap_datfm_format_unknown
                cx_abap_datfm_ambiguous.

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
                  date_from_line       TYPE i VALUE 12403,
                  date_from_column     TYPE string VALUE 'A',
                END OF mnb_cursor.
ENDCLASS.

CLASS lcl_xml_process_rates IMPLEMENTATION.

  METHOD get_currencies_from_file.


    LOOP AT lt_envelope ASSIGNING FIELD-SYMBOL(<envelope>).

      LOOP AT <envelope>-cube ASSIGNING FIELD-SYMBOL(<cube_on_top>).
        LOOP AT <cube_on_top>-cube ASSIGNING FIELD-SYMBOL(<cube_time>).
          cl_abap_datfm=>conv_date_ext_to_int(
            EXPORTING
            im_datext = <cube_time>-date
            im_datfmdes = lcl_xml_process_rates=>ecb_currency-ecb_date_format_in_sap_domain
            IMPORTING
              ex_datint = DATA(date)
           ).

          "Date filtered by Date Range
          IF date NOT BETWEEN start_date AND end_date.
            CONTINUE.
          ENDIF.

          LOOP AT <cube_time>-cube ASSIGNING FIELD-SYMBOL(<cube_currency>).
            DATA(currency_pair) = |{ lcl_xml_process_rates=>ecb_currency-currency }/{ <cube_currency>-currency }|.
            DATA(currency_pair_v) = |{ <cube_currency>-currency }/{ lcl_xml_process_rates=>ecb_currency-currency }|.

            IF currency_pair IN currency_range.
*                currencies
              IF line_exists( currencies[ from_currency = lcl_xml_process_rates=>ecb_currency-currency
                                          to_currency = <cube_currency>-currency ] ).
*                appen
              ELSE.
                APPEND VALUE #(
                    from_currency = lcl_xml_process_rates=>ecb_currency-currency
                    to_currency = <cube_currency>-currency
                    source_from_factor = lcl_xml_process_rates=>ecb_currency-source_factor_as_from
                    source_to_factor  = lcl_xml_process_rates=>ecb_currency-source_factor_as_to

                 ) TO currencies .
              ENDIF.
            ENDIF.


            IF currency_pair_v IN currency_range.
              IF line_exists( currencies[ from_currency = <cube_currency>-currency
                                          to_currency = lcl_xml_process_rates=>ecb_currency-currency ] ).
*                appen
              ELSE.
                APPEND VALUE #(
                    from_currency = <cube_currency>-currency
                    to_currency = lcl_xml_process_rates=>ecb_currency-currency
                    source_from_factor = lcl_xml_process_rates=>ecb_currency-source_factor_as_from
                    source_to_factor  = lcl_xml_process_rates=>ecb_currency-source_factor_as_to

                 ) TO currencies .
              ENDIF.
            ENDIF.

          ENDLOOP.


        ENDLOOP.

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_factors_from_file.
  ENDMETHOD.

  METHOD get_dates_from_file.
  ENDMETHOD.

  METHOD constructor.
    me->start_date = start_date.
    IF end_date IS INITIAL.
      me->end_date = cl_abap_context_info=>get_system_date(  ).
    ELSE.
      me->end_date = end_date.
    ENDIF.
    me->file = file.
    me->currency_range = currency_range.
    me->rate_type = rate_type.
  ENDMETHOD.

  METHOD get_rates_from_file.
    " Parse File


    LOOP AT currencies ASSIGNING FIELD-SYMBOL(<currency>).

      LOOP AT lt_envelope ASSIGNING FIELD-SYMBOL(<envelope>).

        LOOP AT <envelope>-cube ASSIGNING FIELD-SYMBOL(<cube_on_top>).
          LOOP AT <cube_on_top>-cube ASSIGNING FIELD-SYMBOL(<cube_time>).
            cl_abap_datfm=>conv_date_ext_to_int(
              EXPORTING
              im_datext = <cube_time>-date
              im_datfmdes = lcl_xml_process_rates=>ecb_currency-ecb_date_format_in_sap_domain
              IMPORTING
                ex_datint = DATA(date)
             ).
            "Date filtered by Date Range
            IF date NOT BETWEEN start_date AND end_date.
              CONTINUE.
            ENDIF.

            DATA: exchangerate   TYPE string,
                  exchangerate_p TYPE p LENGTH 13 DECIMALS 6.
*            if line(  )

            IF line_exists( <cube_time>-cube[ currency = <currency>-from_currency ] ) .
              exchangerate = <cube_time>-cube[ currency = <currency>-from_currency ]-rate.
              CONDENSE exchangerate.
              exchangerate_p = exchangerate.
              exchangerate_p = 1 / exchangerate_p.
            ELSEIF line_exists( <cube_time>-cube[ currency = <currency>-to_currency ] ).
              exchangerate = <cube_time>-cube[ currency = <currency>-to_currency ]-rate.
              CONDENSE exchangerate.
              exchangerate_p = exchangerate.
            ELSE.
              exchangerate_p = 0.
            ENDIF.

            IF exchangerate_p <> 0 .

              APPEND VALUE #(
                date = date
              ) TO <currency>-rates REFERENCE INTO DATA(rate).
              rate->source_exchangerate = exchangerate_p.
              "Get Factor from CDS
              me->get_factor_from_cds(
                EXPORTING
                    date = date
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
      ENDLOOP.

    ENDLOOP.








*    LOOP AT currencies ASSIGNING FIELD-SYMBOL(<currency>).
*      LOOP AT dates ASSIGNING FIELD-SYMBOL(<date>).
*
*        DATA(cursor) = file->cursor(
*            io_column = xco_cp_xlsx=>coordinate->for_alphabetic_value( <currency>-cell_column )
*            io_row    = xco_cp_xlsx=>coordinate->for_numeric_value( <date>-line )
*        ).
*        IF cursor->has_cell( ) EQ abap_true
*            AND cursor->get_cell( )->has_value( ) EQ abap_true.
*
*          APPEND VALUE #(
*            date = <date>-date
*           ) TO <currency>-rates REFERENCE INTO DATA(rate).
*          DATA exchangerate TYPE string.
*          DATA(cell) = cursor->get_cell( ).
*
*          cell->get_value(
*            )->set_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
*            )->write_to( REF #( exchangerate ) ).
*
*          rate->source_exchangerate = exchangerate.
*          " Check from/to and adjust source exchange rate
*          IF <currency>-from_currency = lcl_xml_process_rates=>mnb_currency-currency.
*            rate->source_exchangerate = 1 / rate->source_exchangerate.
*          ENDIF.
*
*          "Get Factor from CDS
*          me->get_factor_from_cds(
*            EXPORTING
*                date = <date>-date
*                from_currency = <currency>-from_currency
*                to_currency = <currency>-to_currency
*                rate_type = me->rate_type
*            IMPORTING
*                from_factor = rate->from_factor
*                to_factor = rate->to_factor
*          ).
*
*          IF rate->from_factor = 0 OR rate->to_factor = 0.
*            CONTINUE.
*          ENDIF.
*
*          "calculate exchange rate for factor from CDS (fator from source bank will be converted to configuration maintained in SAP)
*          rate->exchangerate = rate->source_exchangerate / <currency>-source_from_factor * <currency>-source_to_factor * rate->from_factor / rate->to_factor.
*
*        ENDIF.
*
*
*      ENDLOOP.
*    ENDLOOP.

  ENDMETHOD.

  METHOD process.
*    me->get_dates_from_file( file ).
    TRY.
        CALL TRANSFORMATION zztr_fi_001 SOURCE XML file
                                      RESULT envelope = lt_envelope.
      CATCH cx_xslt_format_error INTO DATA(lx_xlst).
*        out->write( lx_xlst ).
*        break-point.
        RETURN.
    ENDTRY.

    me->get_currencies_from_file( file ).

*    me->get_factors_from_file( file ).

    me->get_rates_from_file( file ).
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

ENDCLASS.
