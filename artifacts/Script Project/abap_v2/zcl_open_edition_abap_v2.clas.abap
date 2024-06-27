class ZCL_OPEN_EDITION_ABAP_V2 definition
  public
  create public .

public section.

  interfaces /NEPTUNE/IF_OE_SERVER_SCRIPT .
  interfaces /NEPTUNE/IF_OE_SSCR_APIHANDLER .
protected section.
private section.
ENDCLASS.



CLASS ZCL_OPEN_EDITION_ABAP_V2 IMPLEMENTATION.


METHOD /neptune/if_oe_sscr_apihandler~handle_request.

  DATA lt_headers TYPE /neptune/if_oe_types=>tt_name_value.
  DATA ls_header LIKE LINE OF lt_headers.
  DATA: lv_response_body TYPE string.
  DATA: lv_error_text TYPE string.
  DATA: ls_user_details TYPE /neptune/if_oe_types=>user_details,
        lo_p9 TYPE REF TO /neptune/if_oe_p9,
        lo_classdescr TYPE REF TO cl_abap_classdescr,
        lo_obj TYPE REF TO object.
  DATA: ls_started_wf TYPE /neptune/if_oe_types=>workflow_rt_details.
  DATA lx_oe_p9_wf TYPE REF TO /neptune/cx_oe_p9_wf.

  FIELD-SYMBOLS: <ls_attribute> LIKE LINE OF lo_classdescr->attributes,
                 <la_any> TYPE any.

  lv_response_body = '<html><body><h1>Hello world from ABAP!!</h1><br><br>'.


  IF server IS NOT INITIAL AND
     server->request IS NOT INITIAL.
    CONCATENATE lv_response_body '<u>INCOMING HEADER VALUES:</u>' INTO lv_response_body.

    lt_headers = server->request->get_header_fields( ).

    LOOP AT lt_headers INTO ls_header.

      CONCATENATE lv_response_body '<br>'
                'HEADER-NAME: '  ls_header-name
                ' | HEADER-VALUE: '  ls_header-value
      INTO lv_response_body.
    ENDLOOP.
  ENDIF.


  " write: '@KERNEL console.log(await p9.wf.list({usernames: [ "admin" ]}));'.
  "  write: '@KERNEL console.log(await p9.user.getDetails("fbdaa53b-0a0e-4c3a-a630-a2a206bc064c"));'.
  "write: '@KERNEL console.log(await p9.wf.get("da946364-00fd-4200-b00d-e790ae871215"));'.
  " write: '@KERNEL console.log( await p9.wf.start({ id: "ea280f51-9b1a-4234-8672-ca90ac430742", username: "asd", objectType: "My document", objectKey: "key", amount: 100, currency: "EUR" }));'.

  " call function 'BA'.


  CONCATENATE lv_response_body '<br><br><br><u>SERVER->REQUEST->USER[*]:</u>' INTO lv_response_body.

  lo_obj = server->request->user.

  lo_classdescr ?= cl_abap_classdescr=>describe_by_object_ref( server->request->user ).

  LOOP AT lo_classdescr->attributes ASSIGNING <ls_attribute>.
    ASSIGN lo_obj->(<ls_attribute>-name) TO <la_any>.
    CHECK sy-subrc = 0.

    CONCATENATE lv_response_body '<br>'
                 'USERFIELD-NAME: '  <ls_attribute>-name
                  ' | USERFIELD-VALUE: '  <la_any>
       INTO lv_response_body.
  ENDLOOP.


  lo_p9 = /neptune/cl_oe_p9=>get_instance( ).

  ls_user_details = lo_p9->user->get_details( iv_id = 'fbdaa53b-0a0e-4c3a-a630-a2a206bc064c' ).
  ls_user_details = lo_p9->user->get_details( iv_id = server->request->user->id ).


  CONCATENATE lv_response_body '<br><br><u>P9->USER->GET_DETAILS-UPDATED_AT</u>:'
              ls_user_details-updated_at  '<br>' INTO lv_response_body.

  TRY.
      ls_started_wf = lo_p9->wf->start( iv_id          = 'ea280f51-9b1a-4234-8672-ca90ac430742'
                                        iv_username    = 'thorsten'
                                        iv_object_type = 'SALESORDER'
                                        iv_object_key  = 123456
                                        iv_amount      = 100
                                        iv_currency    = 'EUR' ).
      DATA: lv_status_str TYPE string.
      lv_status_str = ls_started_wf-status.
      CONCATENATE lv_response_body '<br><br><u>P9->WF->START-ID</u>:'
              ls_started_wf-id  '<br>'
             '<br><br><u>P9->WF->START-STATUS</u>:'
              lv_status_str  '<br>'
              INTO lv_response_body.

    CATCH /neptune/cx_oe_p9_wf INTO lx_oe_p9_wf.
      CASE lx_oe_p9_wf->if_t100_message~t100key.
        WHEN /neptune/cx_oe_p9_wf=>definition_does_not_exist.
          lv_error_text = 'WORKFLOW DOES NOT EXIST'.
        WHEN OTHERS.
          lv_error_text = 'UNKNOWN ERROR'.
      ENDCASE.
      CONCATENATE lv_response_body '<br><br><u>P9->WF->ERROR</u>:'
             lv_error_text '<br>'
              INTO lv_response_body.
  ENDTRY.

  DATA: lt_oe_scarr TYPE STANDARD TABLE OF oe_scarr,
        ls_oe_scarr LIKE LINE OF lt_oe_scarr,
        lv_tabix   TYPE string.

  CONCATENATE lv_response_body '<br><br><u>OE_SCARR TABLE</u>:'
'<br><br>' INTO lv_response_body.

  SELECT * FROM oe_scarr
          INTO TABLE lt_oe_scarr
           WHERE currency = 'EUR'
           OR    currency = 'USD'.

  CONCATENATE lv_response_body '<table border=1><thead><tr><td>SCARR-CARRID</td><td>SCARR-CARRNAME</td></tr></thead><tbody>'
          INTO lv_response_body.

  LOOP AT lt_oe_scarr INTO ls_oe_scarr.
    lv_tabix = sy-tabix.
    CONCATENATE lv_response_body '<tr>' INTO lv_response_body.

    CONCATENATE lv_response_body
             '<td>'
              ls_oe_scarr-carrid
               '</td>'
              INTO lv_response_body.
    CONCATENATE lv_response_body
             '<td>'
              ls_oe_scarr-carrname
               '</td>'
              INTO lv_response_body.

    CONCATENATE lv_response_body '</tr>' INTO lv_response_body.
  ENDLOOP.

  CONCATENATE lv_response_body '</tbody></table>' INTO lv_response_body.

  CONCATENATE lv_response_body '</body></html>' INTO lv_response_body.

  server->response->set_cdata( lv_response_body ).
  server->response->set_content_type( /neptune/if_oe_constants=>http_content_type-text-html ).

ENDMETHOD.
ENDCLASS.
