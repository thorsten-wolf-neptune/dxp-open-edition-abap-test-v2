
*----------------------------------------------------------------------*
*       CLASS lcl_Test DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_test definition for testing
  duration short
  risk level harmless
.
*?﻿<asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
*?<asx:values>
*?<TESTCLASS_OPTIONS>
*?<TEST_CLASS>lcl_Test
*?</TEST_CLASS>
*?<TEST_MEMBER>f_Cut
*?</TEST_MEMBER>
*?<OBJECT_UNDER_TEST>/NEPTUNE/CL_I18N_PROP
*?</OBJECT_UNDER_TEST>
*?<OBJECT_IS_LOCAL/>
*?<GENERATE_FIXTURE>X
*?</GENERATE_FIXTURE>
*?<GENERATE_CLASS_FIXTURE>X
*?</GENERATE_CLASS_FIXTURE>
*?<GENERATE_INVOCATION>X
*?</GENERATE_INVOCATION>
*?<GENERATE_ASSERT_EQUAL>X
*?</GENERATE_ASSERT_EQUAL>
*?</TESTCLASS_OPTIONS>
*?</asx:values>
*?</asx:abap>
  private section.
* ================
    data:
      f_cut type ref to /neptune/cl_i18n_prop.  "class under test

    methods setup.

    methods parse_and_serialize for testing.
endclass.       "lcl_Test


*----------------------------------------------------------------------*
*       CLASS lcl_Test IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_test implementation.
* ==============================

  method setup.
* =============

    create object f_cut.
  endmethod.       "setup




  method parse_and_serialize.
* =============
    data lv_string type string.
    data ls_properties_data type f_cut->ty_properties_data.
    data lv_serialize_result type string.

    concatenate `# SAPUI5 TRANSLATION-KEY <GUID>`
                ``
                `#XMSG: A message to greet the world`
                `helloWorld=Hello World`
                ``
                `#XBUT,10: Save button text`
                `buttonSave=Save`
                ``
                `#XFLD,30: Greetings displayed in the upper right corner of the screen`
                `welcome=Welcome {0}`
            into lv_string
            separated by f_cut->gc_eol_sign.

    f_cut->parse( lv_string ).

    ls_properties_data = f_cut->get_properties_data( ).

    cl_abap_unit_assert=>assert_equals(
        exp                  = 3
        act                  = lines( ls_properties_data-entries )
        msg                  = `Didn't parse 3 entries` ).

    lv_serialize_result = f_cut->serialize( ).

    cl_abap_unit_assert=>assert_equals(
        exp                  = lv_string
        act                  = lv_serialize_result
        msg                  = `Parsed and serialized result not equal` ).

  endmethod.       "parse




endclass.       "lcl_Test
