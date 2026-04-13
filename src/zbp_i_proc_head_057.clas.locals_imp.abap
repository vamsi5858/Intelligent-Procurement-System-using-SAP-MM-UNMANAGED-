CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_buffer,
             header TYPE TABLE OF zproc_head_057 WITH EMPTY KEY,
             items  TYPE TABLE OF zproc_item_057 WITH EMPTY KEY,
           END OF ty_buffer.
    CLASS-DATA mt_buffer TYPE ty_buffer.
    CLASS-METHODS recalculate_totals IMPORTING iv_proc_uuid TYPE sysuuid_x16.
ENDCLASS.

CLASS lcl_buffer IMPLEMENTATION.
  METHOD recalculate_totals.
    DATA lv_total TYPE zproc_head_057-total_price.
    " Calculate item totals from buffer (snake_case table fields)
    LOOP AT mt_buffer-items INTO DATA(ls_item) WHERE parent_uuid = iv_proc_uuid.
      lv_total += ( ls_item-quantity * ls_item-price ).
    ENDLOOP.

    READ TABLE mt_buffer-header ASSIGNING FIELD-SYMBOL(<ls_header>)
         WITH KEY proc_uuid = iv_proc_uuid.
    IF sy-subrc = 0.
      <ls_header>-total_price = lv_total.
      <ls_header>-tax_amount  = lv_total * '0.18'. " 18% Tax logic
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES IMPORTING keys REQUEST requested_features FOR Header RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION IMPORTING keys REQUEST requested_authorizations FOR Header RESULT result.
    METHODS create FOR MODIFY IMPORTING entities FOR CREATE Header.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Header.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE Header.
    METHODS read FOR READ IMPORTING keys FOR READ Header RESULT result.
    METHODS lock FOR LOCK IMPORTING keys FOR LOCK Header.
    METHODS rba_Items FOR READ IMPORTING keys_rba FOR READ Header\_Items FULL result_requested RESULT result LINK association_links.
    METHODS cba_Items FOR MODIFY IMPORTING entities_cba FOR CREATE Header\_Items.
    METHODS approveOrder FOR MODIFY IMPORTING keys FOR ACTION Header~approveOrder RESULT result.
ENDCLASS.

CLASS lhc_Header IMPLEMENTATION.

  METHOD create.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      DATA(ls_header) = VALUE zproc_head_057(
        proc_id       = <ls_entity>-ProcurementID
        description   = <ls_entity>-Description
        supplier      = <ls_entity>-Supplier
        currency_code = <ls_entity>-CurrencyCode
      ).

      " Generate UUID for the new record
      TRY.
          ls_header-proc_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
      ENDTRY.

      ls_header-overall_status = 'O'. " Set initial status to Open

      INSERT ls_header INTO TABLE lcl_buffer=>mt_buffer-header.

      " CRITICAL: Link the %cid to the new UUID to prevent Shortdump
      APPEND VALUE #( %cid = <ls_entity>-%cid
                      ProcurementUUID = ls_header-proc_uuid ) TO mapped-header.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_upd>).
      READ TABLE lcl_buffer=>mt_buffer-header ASSIGNING FIELD-SYMBOL(<ls_head>)
           WITH KEY proc_uuid = <ls_upd>-ProcurementUUID.
      IF sy-subrc = 0.
        " Use %control to check for changed fields (PascalCase)
        IF <ls_upd>-%control-Description = if_abap_behv=>mk-on.
           <ls_head>-description = <ls_upd>-Description.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Items.
    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<ls_cba>).
      LOOP AT <ls_cba>-%target ASSIGNING FIELD-SYMBOL(<ls_item_in>).
        DATA(ls_item) = VALUE zproc_item_057(
            parent_uuid = <ls_cba>-ProcurementUUID
            material    = <ls_item_in>-Material
            quantity    = <ls_item_in>-Quantity
            price       = <ls_item_in>-Price
            currency_code = <ls_item_in>-CurrencyCode ).

        TRY.
            ls_item-item_uuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.

        INSERT ls_item INTO TABLE lcl_buffer=>mt_buffer-items.

        " Fill mapped for items
        APPEND VALUE #( %cid = <ls_item_in>-%cid
                        ItemUUID = ls_item-item_uuid ) TO mapped-item.
      ENDLOOP.
      " Update header totals
      lcl_buffer=>recalculate_totals( <ls_cba>-ProcurementUUID ).
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    " Manual mapping to avoid 'No mapping defined' error
    IF keys IS NOT INITIAL.
      SELECT * FROM zproc_head_057 FOR ALL ENTRIES IN @keys
        WHERE proc_uuid = @keys-ProcurementUUID INTO TABLE @DATA(lt_heads).
      result = VALUE #( FOR head IN lt_heads (
        ProcurementUUID = head-proc_uuid
        ProcurementID   = head-proc_id
        Description     = head-description
        Supplier        = head-supplier
        OverallStatus   = head-overall_status
        TotalPrice      = head-total_price
      ) ).
    ENDIF.
  ENDMETHOD.

  METHOD approveOrder.
    " Action logic: Change status to Approved ('A')
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      READ TABLE lcl_buffer=>mt_buffer-header ASSIGNING FIELD-SYMBOL(<ls_head>)
           WITH KEY proc_uuid = <ls_key>-ProcurementUUID.
      IF sy-subrc = 0.
        <ls_head>-overall_status = 'A'.
        APPEND VALUE #( %tky = <ls_key>-%tky %param = CORRESPONDING #( <ls_head> MAPPING TO ENTITY ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete. ENDMETHOD.
  METHOD lock. ENDMETHOD.
  METHOD rba_Items. ENDMETHOD.
  METHOD get_instance_authorizations. ENDMETHOD.
  METHOD get_instance_features. ENDMETHOD.
ENDCLASS.

CLASS lhc_Item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Item.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE Item.
    METHODS read   FOR READ   IMPORTING keys FOR READ Item RESULT result.
    METHODS rba_Header FOR READ IMPORTING keys_rba FOR READ Item\_Header FULL result_requested RESULT result LINK association_links.
ENDCLASS.

CLASS lhc_Item IMPLEMENTATION.
  METHOD update.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_upd>).
      READ TABLE lcl_buffer=>mt_buffer-items ASSIGNING FIELD-SYMBOL(<ls_item>)
           WITH KEY item_uuid = <ls_upd>-ItemUUID.
      IF sy-subrc = 0.
        IF <ls_upd>-%control-Price = if_abap_behv=>mk-on. <ls_item>-price = <ls_upd>-Price. ENDIF.
        IF <ls_upd>-%control-Quantity = if_abap_behv=>mk-on. <ls_item>-quantity = <ls_upd>-Quantity. ENDIF.
        lcl_buffer=>recalculate_totals( <ls_item>-parent_uuid ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete. ENDMETHOD.
  METHOD read. ENDMETHOD.
  METHOD rba_Header. ENDMETHOD.
ENDCLASS.

CLASS lsc_ZI_PROC_HEAD_057 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_ZI_PROC_HEAD_057 IMPLEMENTATION.
  METHOD save.
    " Final persistent write to the database
    IF lcl_buffer=>mt_buffer-header IS NOT INITIAL.
      MODIFY zproc_head_057 FROM TABLE @lcl_buffer=>mt_buffer-header.
    ENDIF.
    IF lcl_buffer=>mt_buffer-items IS NOT INITIAL.
      MODIFY zproc_item_057 FROM TABLE @lcl_buffer=>mt_buffer-items.
    ENDIF.
  ENDMETHOD.

  METHOD finalize. ENDMETHOD.
  METHOD check_before_save. ENDMETHOD.
  METHOD cleanup. CLEAR lcl_buffer=>mt_buffer. ENDMETHOD.
  METHOD cleanup_finalize. ENDMETHOD.
ENDCLASS.
