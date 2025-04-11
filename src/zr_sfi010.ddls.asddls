@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Principal Repayment - Closing'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI010
  with parameters
    P_Date : datum

  as select from ztfi002

  // I_CalendarDate as _CalendarDate

    join         I_CalendarDate as _CalendarDate on _CalendarDate.CalendarDate = $parameters.P_Date


{
  key    ztfi002.uuid_interest            as UUIDInterest,
         ztfi002.repayment_type           as RepaymentType1,
         @Semantics.amount.currencyCode: 'Currency'
         sum ( ztfi002.repayment_amount ) as Amount,
         ztfi002.currency
}
where
  // ztfi002.CalendarDate = $parameters.P_Date
  ztfi002.repayment_date <= _CalendarDate.LastDayOfMonthDate
 and ztfi002.currency <> ''
group by
  ztfi002.uuid_interest,
  ztfi002.currency,
  ztfi002.repayment_type
