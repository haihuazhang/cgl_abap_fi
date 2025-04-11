CLASS zzcl_connect_sap DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
      CLASS-DATA g_result TYPE cl_exchange_rates=>ty_messages.
ENDCLASS.



CLASS ZZCL_CONNECT_SAP IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
   "DATA lv_url   TYPE string VALUE 'http://14.21.43.44:8002/sap/z_code_mapping?sap-client=220'.
    TYPES:BEGIN OF ty_token,
            expire        TYPE string,
            access_token  TYPE string.
    TYPES:END OF ty_token.

    TYPES:BEGIN OF ty_receive,
            code TYPE string,
            message  TYPE string,
            data TYPE ty_token.
    TYPES:END OF ty_receive.
    DATA ls_receive TYPE  ty_receive.


    TRY.
    DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
           comm_scenario  = 'ZZCS_FI_004'
           service_id     = 'ZZOS_FI_004_REST'
           comm_system_id = 'OP'
      ).
        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_destination ).
***********請求
        DATA(request) = lo_http_client->get_http_request( ).
        request->set_content_type( content_type = 'application/json; charset=utf-8' ).

        DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>get ).
        DATA(lv_json) = lo_response->get_text( ).
        /ui2/cl_json=>deserialize( EXPORTING json = lv_json
                                     pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                                   CHANGING data = ls_receive ).
        out->write( ls_receive ).
      CATCH cx_root INTO DATA(lx_exception).
        lv_json = lx_exception->get_text( ).
        out->write( lv_json ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
