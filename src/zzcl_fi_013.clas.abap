CLASS zzcl_fi_013 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zzcl_fi_013 IMPLEMENTATION.

  METHOD if_http_service_extension~handle_request.
    DATA : payload TYPE STRUCTURE FOR ACTION IMPORT i_journalentrytp~post.

*    DATA : payload_reverse TYPE STRUCTURE FOR action IMPORT I_JournalEntryTP~Reverse.

    IF request->get_method(  ) = 'POST'.
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      "转换报文
      /ui2/cl_json=>deserialize(
         EXPORTING
             json = request->get_text(  )
         CHANGING
             data = payload

      ).

      "设置返回是json
      response->set_header_field(
        i_name = 'Content-Type'
        i_value = 'application/json'
      ).

      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      "调用 Post
      MODIFY ENTITIES OF i_journalentrytp
        ENTITY journalentry
        EXECUTE post
        FROM VALUE #( ( payload ) )
        FAILED DATA(ls_failed_deep)
        REPORTED DATA(ls_reported_deep)
        MAPPED DATA(ls_mapped_deep).
      IF ls_failed_deep IS NOT INITIAL.
        "失败返回Modify的Reported结构
        LOOP AT ls_reported_deep-journalentry ASSIGNING FIELD-SYMBOL(<fs_reported_deep>).
*          DATA(lv_result) = <fs_reported_deep>-%msg->if_message~get_text( ).
          response->set_text( /ui2/cl_json=>serialize( <fs_reported_deep> ) ).
        ENDLOOP.
      ELSE.
        "成功 返回Commit的Reported 结构
        COMMIT ENTITIES BEGIN
        RESPONSE OF i_journalentrytp
        FAILED DATA(ls_commit_failed)
        REPORTED DATA(ls_commit_reported).
        COMMIT ENTITIES END.
        LOOP AT ls_commit_reported-journalentry ASSIGNING FIELD-SYMBOL(<fs_reported_je>).
*          DATA(lv_result) = <fs_reported_deep>-%msg->.
          response->set_text( /ui2/cl_json=>serialize( <fs_reported_je> ) ).
        ENDLOOP.
      ENDIF.

      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      "写日志



    ENDIF.
  ENDMETHOD.
  METHOD if_oo_adt_classrun~main.
    DATA : payload TYPE STRUCTURE FOR ACTION IMPORT i_journalentrytp~post.
    payload = VALUE #(
        %cid = 'TEST'
        %param = VALUE #(
            accountingdocument = 'TEST'
            companycode = '2001'
            postingdate = '20250101'
            accountingdocumenttype = 'SA'
         )

    ).
    out->write( /ui2/cl_json=>serialize( payload ) ).
  ENDMETHOD.

ENDCLASS.
