@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Report of Interest Platform - Repayment'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI007
  with parameters
    P_Date : datum
  as select from ztfi002
{
  key    uuid_interest            as UUIDInterest,
         repayment_type           as RepaymentType1,
         @Semantics.amount.currencyCode: 'Currency'
         sum ( repayment_amount ) as Amount,
         currency                 as Currency
}
where
  //      RepaymentType1 = '1'
  repayment_date <= $parameters.P_Date
  and currency <> ''
group by
  uuid_interest,
  currency,
  repayment_type
