@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Intelligent Procurement Header'

define root view entity ZI_PROC_HEAD_057
  as select from zproc_head_057
  composition [0..*] of ZI_PROC_ITEM_057 as _Items
{
  key proc_uuid             as ProcurementUUID,
      proc_id               as ProcurementID,
      description           as Description,
      supplier              as Supplier,
      pur_org               as PurchasingOrg,
      pur_group             as PurchasingGroup,
      pay_terms             as PaymentTerms,
      overall_status        as OverallStatus,
      
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price           as TotalPrice,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      tax_amount            as TaxAmount,
      currency_code         as CurrencyCode,

      /* Admin Data for Framework */
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      /* Associations */
      _Items
}
