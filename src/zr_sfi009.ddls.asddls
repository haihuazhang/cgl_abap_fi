@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interests of PrincipalRepayment'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI009
  with parameters
    P_Date : datum
  as select from ztfi002
    join         ztfi001 on ztfi002.uuid_interest = ztfi001.uuid
{

  key ztfi002.uuid_interest                                                                                                                                                                as UUIDInterest,
      ztfi002.currency                                                                                                                                                                     as Currency,
      @Semantics.amount.currencyCode: 'Currency'
      sum ( cast( cast( ztfi002.repayment_amount as abap.decfloat34) * ztfi001.ex_rates / 365 * ( dats_days_between( ztfi001.start_date , ztfi002.repayment_date ) + 1 ) as zzefi015  ) ) as InterestOfPrincipalRepayment
}
where
      ztfi002.repayment_date <= $parameters.P_Date
  and ztfi002.repayment_type = '1'
  and ztfi002.currency <> ''
group by
  ztfi002.uuid_interest,
  ztfi002.currency
