*----------------------------------------------------------------------*
*       CLASS /NEPTUNE/CL_I18N_PROP DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class /neptune/cl_i18n_prop definition
  public
  create public .

  public section.

    types:
      begin of ty_text_types,
                  type        type string,
                  description type string,
               end of   ty_text_types .
    types:
      ty_t_text_types type standard table of ty_text_types with non-unique key type .
    types:
      begin of ty_classification,
                    text_type type string,
                    maximum_length type i,
                    additional_context_info type string,
                 end of   ty_classification .
    types:
      begin of ty_key_value_info,
                      key   type string,
                      value type string,
                      placeholders type i,
              end of  ty_key_value_info .
    types:
      begin of ty_entry.
            include type ty_key_value_info.
    types:
     classification type ty_classification,
    end of   ty_entry .
    types:
      ty_t_entry type standard table of ty_entry with non-unique default key .
    types:
      begin of ty_properties_data,
                    top_comment type string,
                    entries     type ty_t_entry,
                 end of   ty_properties_data .

    constants:
      begin of gc_text_type,
            " begin short texts (< 120)
                accessibility type string value 'XACT',
                button type string value 'XBUT',
                checkbox type string value 'XCKL',
                column_header type string value 'XCOL',
                label type string value 'XFLD',
                group_title type string value 'XGRP',
                hyperlink type string value 'XLNK',
                log_entry type string value 'XLOG',
                list_box_item type string value 'XLST',
                menu_item type string value 'XMIT',
                message type string value 'XMSG',
                radio_button type string value 'XRBL',
                selection type string value 'XSEL',
                table_title type string value 'XTIT',
                tooltip type string value 'XTOL',
            " end short texts (< 120)
            " begin long texts (> 120)
                instruction type string value 'YINS',
            " end long texts (> 120)
                no_translation type string value 'NOTR',
            end of gc_text_type .
    constants gc_comment_sign type c value '#'.             "#EC NOTEXT
    constants gc_key_value_Separator type c value '='.             "#EC NOTEXT
    constants gc_eol_sign like cl_abap_char_utilities=>cr_lf value cl_abap_char_utilities=>cr_lf.

    class-methods classify_comment_line
      importing
        !iv_line type clike
      returning
        value(rs_classification) type ty_classification .
    methods parse
      importing
        !iv_string type clike .
    methods serialize
      returning
        value(rv_string) type string .
    class-methods get_text_types
      returning
        value(rt_text_types) type ty_t_text_types .
    class-methods get_key_value_line
      importing
        !iv_line type clike
      returning
        value(rs_key_value) type ty_key_value_info .
    methods constructor
      importing
        !is_properties_data type ty_properties_data optional .
    methods get_properties_data
      returning
        value(rs_properties_data) type ty_properties_data .
    methods set_properties_data
      importing
        !is_properties_data type ty_properties_data .
protected section.

  data GS_PROPERTIES_DATA type TY_PROPERTIES_DATA .
private section.

  class-data GT_TEXT_TYPES type TY_T_TEXT_TYPES .
ENDCLASS.



CLASS /NEPTUNE/CL_I18N_PROP IMPLEMENTATION.


method classify_comment_line.

  data: lv_line                type string,
        lv_max_length_str      type string.

  lv_line = iv_line.

  check lv_line is not initial and
        lv_line(1) = gc_comment_sign and
        strlen( lv_line ) >= 5.

  find first occurrence of regex '^#(\C{4})(?:,(\d+))?(?::(.*))'
                           in iv_line submatches rs_classification-text_type
                                                 lv_max_length_str
                                                 rs_classification-additional_context_info.
  if lv_max_length_str co `0123456789`.
    rs_classification-maximum_length = lv_max_length_str.
  endif.

  shift rs_classification-additional_context_info left deleting leading space.

endmethod.


method constructor.

  gs_properties_data = is_properties_data.

endmethod.


method get_key_value_line.

  check iv_line is not initial and iv_line ca gc_key_value_Separator.
  split iv_line at gc_key_value_Separator into rs_key_value-key rs_key_value-value.
  find all occurrences of regex '\{\d+\}' in rs_key_value-value match count rs_key_value-placeholders.

endmethod.


method get_properties_data.
  rs_properties_data = gs_properties_data.
endmethod.


method get_text_types.

  data: lo_structdescr type ref to cl_abap_structdescr,
        ls_text_type   like line of rt_text_types.

  field-symbols: <ls_component> like line of lo_structdescr->components,
                 <l_type>       type string.

  if gt_text_types is initial.
    lo_structdescr ?= cl_abap_structdescr=>describe_by_data( p_data = gc_text_type ).
    loop at lo_structdescr->components assigning <ls_component>.
      assign component <ls_component>-name of structure gc_text_type to <l_type>.
      check sy-subrc = 0.
      ls_text_type-type = <l_type>.
      ls_text_type-description = <ls_component>-name.
      insert ls_text_type into table gt_text_types.
    endloop.
  endif.

  rt_text_types = gt_text_types.
endmethod.


method parse.

  data: lt_string          type string_table,
        l_string           like line of lt_string,
        ls_properties_data type ty_properties_data,
        lv_sep             type string,
        ls_key_value_info  type ty_key_value_info,
        ls_entry           like line of ls_properties_data-entries.

  split iv_string at cl_abap_char_utilities=>cr_lf into table lt_string.

  if sy-subrc <> 0.
    split iv_string at cl_abap_char_utilities=>newline into table lt_string.
  endif.

  loop at lt_string into l_string where table_line is not initial.
    if l_string(1) = gc_comment_sign.
      ls_entry-classification = classify_comment_line( iv_line = l_string ).
      if ls_entry-classification is initial and
         ls_properties_data-entries is initial.
        concatenate ls_properties_data-top_comment lv_sep l_string into ls_properties_data-top_comment.
        lv_sep = gc_eol_sign.
        clear: ls_entry-classification.
      endif.
    elseif l_string ca gc_key_value_Separator. " name value
      ls_key_value_info = get_key_value_line( iv_line = l_string ).
      move-corresponding ls_key_value_info to ls_entry.
      insert ls_entry into table ls_properties_data-entries.
      clear: ls_entry.
    endif.
  endloop.

  me->gs_properties_data = ls_properties_data.

endmethod.


method serialize.

  data: lt_result_lines   type string_table,
        lv_max_length_str type string,
        lv_line           type string.

  field-symbols: <ls_entry> like line of gs_properties_data-entries.

  if gs_properties_data-top_comment is not initial.
    split gs_properties_data-top_comment at gc_eol_sign into table lt_result_lines.
  endif.

  loop at gs_properties_data-entries assigning <ls_entry>.
    insert initial line into table lt_result_lines.
    if <ls_entry>-classification-text_type is not initial.
      concatenate gc_comment_sign <ls_entry>-classification-text_type into lv_line.
      if <ls_entry>-classification-maximum_length is not initial.
        lv_max_length_str = <ls_entry>-classification-maximum_length.
        condense lv_max_length_str no-gaps.
        concatenate lv_line ',' lv_max_length_str into lv_line.
      endif.
      if <ls_entry>-classification-additional_context_info is not initial.
        concatenate lv_line `: ` <ls_entry>-classification-additional_context_info into lv_line.
      endif.
      insert lv_line into table lt_result_lines.
    endif.
    concatenate <ls_entry>-key gc_key_value_separator <ls_entry>-value into lv_line.
    insert lv_line into table lt_result_lines.
  endloop.

  concatenate lines of lt_result_lines into rv_string separated by gc_eol_sign.

endmethod.


method set_properties_data.
  gs_properties_data = is_properties_data.
endmethod.
ENDCLASS.
