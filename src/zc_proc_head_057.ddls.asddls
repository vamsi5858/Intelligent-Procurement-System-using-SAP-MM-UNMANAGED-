@EndUserText.label: 'Procurement Projection - Header'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Search.searchable: true
@Metadata.allowExtensions: true

define root view entity ZC_PROC_HEAD_057
  provider contract transactional_query
  as projection on ZI_PROC_HEAD_057
{
  key ProcurementUUID,
  
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      ProcurementID,
      
      @Search.defaultSearchElement: true
      Description,
      
        // Comment out or remove the definition if I_Supplier is missing
        // @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Supplier', element: 'Supplier' } }]
        Supplier,
      
      PurchasingOrg,
      PurchasingGroup,
      PaymentTerms,
      OverallStatus,
      
      TotalPrice,
      TaxAmount,
      CurrencyCode,
      
      /* Admin Data */
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      /* Composition */
      _Items : redirected to composition child ZC_PROC_ITEM_057
}
