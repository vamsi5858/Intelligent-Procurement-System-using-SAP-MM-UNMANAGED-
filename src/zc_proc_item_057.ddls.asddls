@EndUserText.label: 'Procurement Projection - Item'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Search.searchable: true
@Metadata.allowExtensions: true

define view entity ZC_PROC_ITEM_057
  as projection on ZI_PROC_ITEM_057
{
  key ItemUUID,
      ProcurementUUID,
      ItemPosition,
      
      @Search.defaultSearchElement: true
      Material,
      
      MaterialGroup,
      Quantity,
      Unit,
      Price,
      
      @Semantics.amount.currencyCode: 'CurrencyCode'
      LineItemTotal,
      
      CurrencyCode,
      Plant,
      StorageLocation,
      DeliveryDate,
      LocalLastChangedAt,
      
      /* Association */
      _Header : redirected to parent ZC_PROC_HEAD_057
}
