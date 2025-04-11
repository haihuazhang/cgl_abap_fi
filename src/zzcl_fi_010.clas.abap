CLASS zzcl_fi_010 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS get_data
      IMPORTING
        io_request  TYPE REF TO if_rap_query_request
        io_response TYPE REF TO if_rap_query_response.
ENDCLASS.



CLASS ZZCL_FI_010 IMPLEMENTATION.


  METHOD get_data.

  ENDMETHOD.


  METHOD if_rap_query_provider~select.
  DATA(i_entity) = io_request->get_entity_id( ).
    CASE i_entity.
      WHEN 'ZR_SFI047'.
        get_data(
          EXPORTING
           io_request = io_request
           io_response = io_response ).
     ENDCASE.
  ENDMETHOD.
ENDCLASS.
