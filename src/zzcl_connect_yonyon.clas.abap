CLASS zzcl_connect_yonyon DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
      CLASS-DATA g_result TYPE cl_exchange_rates=>ty_messages.
ENDCLASS.



CLASS ZZCL_CONNECT_YONYON IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
   DATA lv_get_url   TYPE string.

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

 DATA: lv_appkey         TYPE string VALUE '316e8bc8975946ebadc7e84441ec4b85',
      lv_appsecret      TYPE string VALUE '70a48d67d83aab801569e6b5377b9bd99590d4a8',
      lv_string_to_sign TYPE string,
      lv_hmac_xstr      TYPE xstring,
      lv_base64         TYPE string,
      lv_signature      TYPE string,
      lv_url            TYPE string.


DATA: lv_date    TYPE d,
      lv_date1    TYPE d VALUE '19700101' ,
      lv_seconds  TYPE string,
      lv_time     TYPE string,
      lv_msec     TYPE n LENGTH 3,
      diff_days   TYPE i.

" 1. 获取秒级时间戳
DATA: lv_str_timestampl TYPE string,
      lv_timestampl TYPE timestampl.      " UTC Time Stamp in Long  Form (YYYYMMDDhhmmssmmmuuun)
GET TIME STAMP FIELD lv_timestampl.                    " 20231228140928.3582690
lv_str_timestampl = lv_timestampl.

    lv_date      =  lv_str_timestampl(8).            " 20231228
    lv_time      =  lv_str_timestampl+8(6).          " 140928
    lv_msec      =  lv_str_timestampl+15(3)  .       " 358

"  计算1970年以来的秒数
 diff_days = lv_date - lv_date1.
lv_seconds = ( diff_days * 86400 ) +
             ( lv_time(2) * 3600 ) +
             ( lv_time+2(2) * 60 ) +
             lv_time+4(2).



"  生成13位时间戳
DATA(lv_unix_ms) = |{ lv_seconds * 1000 + lv_msec }|.



" 2. 拼接签名字符串
 CONCATENATE 'appKey' lv_appkey 'timestamp' lv_unix_ms INTO lv_string_to_sign.

" 3. 计算HmacSHA256签名
DATA: lv_key         TYPE xstring,
      lv_message     TYPE xstring,
      lv_sign        TYPE xstring,
      lv_base64_sign TYPE string.
* 密钥（替换为你的实际密钥）
TRY.
    lv_key = cl_abap_hmac=>string_to_xstring( lv_appsecret ).
* 消息（替换为你要签名的消息）
    lv_message = cl_abap_hmac=>string_to_xstring( lv_string_to_sign ).

*     计算HMAC-SHA256签名,Base64编码
    CALL METHOD cl_abap_hmac=>calculate_hmac_for_raw
      EXPORTING
        if_algorithm     = 'SHA256'
        if_key           = lv_key
        if_data          = lv_message
      IMPORTING
        ef_hmacb64string = lv_base64_sign.
      CATCH cx_abap_message_digest.
        "handle exception
ENDTRY.

" 4. URL编码处理
    lv_signature = escape( val = lv_base64_sign format = cl_abap_format=>e_url ).
    REPLACE ALL OCCURRENCES OF '+' IN lv_signature WITH '%2B'.  " 确保+被正确编码
    REPLACE ALL OCCURRENCES OF '=' IN lv_signature WITH '%3D'.
    lv_url = 'https://c2.yonyoucloud.com/iuap-api-auth/open-auth/selfAppAuth/getAccessToken?'
       && 'appKey=' && lv_appkey && '&timestamp=' && lv_unix_ms && '&signature=' && lv_signature.
    TRY.

        DATA(lo_destination) = cl_http_destination_provider=>create_by_url( i_url = lv_url ).
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
        out->write( lx_exception->get_text( ) ).
    ENDTRY.
    DATA(token) = ls_receive-data-access_token.

* 定义内层结构体（原数据）
TYPES: BEGIN OF ty_inner,
         pkBo      TYPE string,
         appSource TYPE string,
       END OF ty_inner.

* 定义外层结构体（包含 Body）
TYPES: BEGIN OF ty_outer,
         body TYPE ty_inner, " 将原结构体作为 Body 字段
       END OF ty_outer.

DATA: ls_outer TYPE ty_outer,
      lv_body  TYPE string.

* 填充数据
ls_outer-body-pkBo = '5d6e2bf3470f4590a37bd5d3bb300548'.
ls_outer-body-appSource = ''. " 保持空字符串

* 转换为 JSON
TRY.
  lv_body = /ui2/cl_json=>serialize(
    data          = ls_outer
    pretty_name   = /ui2/cl_json=>pretty_mode-user       " 保持字段名原样
  ).
  CATCH cx_root INTO DATA(lx_error).
   out->write( lx_error->get_text( ) ).
    RETURN.
ENDTRY.
 out->write( lv_body ).
   lv_url = 'https://c2.yonyoucloud.com/iuap-api-gateway/yonbip/uspace/openapi/iform/queryForm?access_token=' && token.

    TRY.
        lo_destination = cl_http_destination_provider=>create_by_url( i_url = lv_url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_destination ).
***********請求
        request = lo_http_client->get_http_request( ).
        request->set_content_type( content_type = 'application/json; charset=utf-8' ).

*设置请求体为 JSON 数据
         request->set_text( lv_body ).

        lo_response = lo_http_client->execute( i_method = if_web_http_client=>post ).
        lv_json = lo_response->get_text( ).
        /ui2/cl_json=>deserialize( EXPORTING json = lv_json
                                     pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                                   CHANGING data = ls_receive ).
        out->write( ls_receive ).
      CATCH cx_root INTO lx_exception.
        out->write( lx_exception->get_text( ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
