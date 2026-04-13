@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Intelligent Procurement Item'


define view entity ZI_PROC_ITEM_057
  as select from zproc_item_057
  association to parent ZI_PROC_HEAD_057 as _Header on $projection.ProcurementUUID = _Header.ProcurementUUID
{
  key item_uuid             as ItemUUID,
      parent_uuid           as ProcurementUUID,
      item_pos              as ItemPosition,
      material              as Material,
      mat_group             as MaterialGroup,
      
      @Semantics.quantity.unitOfMeasure: 'Unit'
      quantity              as Quantity,
      unit                  as Unit,
      
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,
      
      /* FIXED CALCULATION */
      @Semantics.amount.currencyCode: 'CurrencyCode'
      @EndUserText.label: 'Line Item Total'
      // We perform the math and cast it to a decimal type that RAP supports
      cast( cast( quantity as abap.dec(15,3) ) * cast( price as abap.dec(15,2) ) as abap.dec(15,2) ) as LineItemTotal,
      plant                 as Plant,
      storage_loc           as StorageLocation,
      delivery_date         as DeliveryDate,
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Header
}
