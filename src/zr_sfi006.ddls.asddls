@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report for Interest'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI006
  with parameters
    P_Date : abap.dats
  as select from ztfi001

  association [1]    to I_CalendarDate as _CalendarDate                  on  _CalendarDate.CalendarDate = $parameters.P_Date



  association [0..1] to ZR_SFI007      as _PrincipalRepayment            on  $projection.uuid                   = _PrincipalRepayment.UUIDInterest
                                                                         and _PrincipalRepayment.RepaymentType1 = '1'
  association [0..1] to ZR_SFI007      as _InterestRepayment             on  $projection.uuid                  = _InterestRepayment.UUIDInterest
                                                                         and _InterestRepayment.RepaymentType1 = '2'

  association [0..1] to ZR_SFI009      as _InterestOfPrincipalRepayment  on  $projection.uuid = _InterestOfPrincipalRepayment.UUIDInterest


  association [0..1] to ZR_SFI010      as _PrincipalRepaymentClosing     on  ztfi001.uuid                              = _PrincipalRepaymentClosing.UUIDInterest
                                                                         and _PrincipalRepaymentClosing.RepaymentType1 = '1'

  association [0..1] to ZR_SFI011      as _InterestOfPRClosing           on  $projection.uuid = _InterestOfPRClosing.UUIDInterest


  association [0..1] to ZR_SFI012      as _PrincipalRepaymentOpening     on  ztfi001.uuid                              = _PrincipalRepaymentOpening.UUIDInterest
                                                                         and _PrincipalRepaymentOpening.RepaymentType1 = '1'

  association [0..1] to ZR_SFI013      as _InterestOfPROpening           on  $projection.uuid = _InterestOfPROpening.UUIDInterest

  association [0..1] to ZR_SFI014      as _InterestRepaymentCurrentMonth on  $projection.uuid = _InterestRepaymentCurrentMonth.UUIDInterest

{
  key uuid,
      @Semantics.amount.currencyCode: 'Currency'
      initial_principal                                                                                                                                                                                                             as InitialPrincipal, //贷款总额
      currency                                                                                                                                                                                                                      as Currency,
      start_date                                                                                                                                                                                                                    as StartDate,
      exchange_rate                                                                                                                                                                                                                 as ExchangeRate,
      ex_rates                                                                                                                                                                                                                      as ExRates,
      $parameters.P_Date                                                                                                                                                                                                            as P_Date_Parameter,

      @Semantics.amount.currencyCode: 'Currency'
      cast( _PrincipalRepayment(P_Date : $parameters.P_Date).Amount as zzefi010 )                                                                                                                                                   as PrincipalRepayment, //已还款总额


      /*******************
        cast as decfloat34: 将货币字段直接转换成dec字段再参与计算
        !!!不能使用 curr_to_decfloat_amount，这个参数会对日元类货币进行字段decimal shift(例：乘以100).

      */

      cast( initial_principal as abap.decfloat34 ) - 2                                                                                                                                                                              as Test,

      @Semantics.amount.currencyCode: 'Currency'
      cast( cast(initial_principal as abap.decfloat34) - coalesce(cast(_PrincipalRepayment(P_Date : $parameters.P_Date).Amount as abap.decfloat34 ),0) as zzefi011 )                                                                as PrincipalBalance, //剩余欠款总额

      //      @Semantics.amount.currencyCode: 'Currency'
      //      _InterestOfPrincipalRepayment(P_Date : $parameters.P_Date).InterestOfPrincipalRepayment, //已还本金的利息总额

      @Semantics.amount.currencyCode: 'Currency'
      cast(
        (cast(initial_principal as abap.decfloat34) -  coalesce(cast(_PrincipalRepayment(P_Date : $parameters.P_Date).Amount as abap.decfloat34),0) ) //剩余欠款总额计算出来的利息
            * ex_rates / 365 * ( dats_days_between( start_date , $parameters.P_Date ) + 1 )
      + coalesce(cast( _InterestOfPrincipalRepayment(P_Date : $parameters.P_Date).InterestOfPrincipalRepayment as abap.decfloat34),0) as zzefi014 )                                                                                 as AccumulatedInterest, //利息总额

//      (cast(initial_principal as abap.decfloat34) -  coalesce(cast(_PrincipalRepayment(P_Date : $parameters.P_Date).Amount as abap.decfloat34),0) ) //剩余欠款总额计算出来的利息
//            * ex_rates / 365 * ( dats_days_between( start_date , $parameters.P_Date ) + 1 )
//      + coalesce(cast( _InterestOfPrincipalRepayment(P_Date : $parameters.P_Date).InterestOfPrincipalRepayment as abap.decfloat34),0)                                                                                               as AccumulatedInterest2,
//
//      ( cast(initial_principal as abap.decfloat34) -  coalesce(cast(_PrincipalRepayment(P_Date : $parameters.P_Date).Amount as abap.decfloat34),0)) * ex_rates / 365  as AccumulatedInterest3,

      @Semantics.amount.currencyCode: 'Currency'
      cast( _InterestRepayment(P_Date : $parameters.P_Date).Amount  as zzefi015 )                                                                                                                                                   as InterestRepayment, //已偿还利息

      @Semantics.amount.currencyCode: 'Currency'
      cast(
       ( cast(initial_principal as abap.decfloat34) -  coalesce(cast (_PrincipalRepayment(P_Date : $parameters.P_Date).Amount as abap.decfloat34),0) )
           * ex_rates / 365 * ( dats_days_between( start_date , $parameters.P_Date ) + 1 )
      + coalesce(cast ( _InterestOfPrincipalRepayment(P_Date : $parameters.P_Date).InterestOfPrincipalRepayment as abap.decfloat34),0)
      - coalesce(cast(_InterestRepayment(P_Date : $parameters.P_Date).Amount as abap.decfloat34),0)
       as zzefi016 )                                                                                                                                                                                                                as InterestBalance, //剩余利息

      /**
        月末利息
      **/
      @Semantics.amount.currencyCode: 'Currency'
      cast(
      ( cast(initial_principal as abap.decfloat34) -  coalesce(cast(_PrincipalRepaymentClosing(P_Date :  $parameters.P_Date).Amount as abap.decfloat34),0) ) //剩余欠款总额计算出来的利息
      * ex_rates / 365 * ( dats_days_between( start_date , _CalendarDate.LastDayOfMonthDate ) + 1 )
      + coalesce(cast( _InterestOfPRClosing(P_Date :  $parameters.P_Date).InterestOfPrincipalRepayment as abap.decfloat34),0) as zzefi014 )                                                                                        as AccumulatedInterestClose, //月末利息

      /**
        月初利息
      **/
      @Semantics.amount.currencyCode: 'Currency'
      cast(
      ( cast(initial_principal as abap.decfloat34) -  coalesce(cast(_PrincipalRepaymentOpening(P_Date :  $parameters.P_Date).Amount as abap.decfloat34),0) )  //剩余欠款总额计算出来的利息
      * ex_rates / 365 * ( dats_days_between( start_date , _CalendarDate.FirstDayOfMonthDate )  )
      + coalesce(cast( _InterestOfPROpening(P_Date :  $parameters.P_Date).InterestOfPrincipalRepayment as abap.decfloat34),0) as zzefi014 )                                                                                        as AccumulatedInterestOpen, //月初利息

      /**
        本月已还利息
      **/
      @Semantics.amount.currencyCode: 'Currency'
      cast(coalesce(cast(_InterestRepaymentCurrentMonth(P_Date :  $parameters.P_Date).Amount as abap.decfloat34),0) as zzefi015)                                                                                                    as InterestRepaymentCurrentMonth, //本月已还利息



      //      CreatedBy,
      //      CreatedAt,
      //      LastChangedBy,
      //      LastChangedAt,
      //      LocalLastChangedAt,
      //      /* Associations */
      //      _Accrual,
      //      _Borrower,
      //      _ContractTypeText,
      //      _Lender,
      //      _Repayment,
      _PrincipalRepayment,
      _InterestRepayment,
      _InterestOfPrincipalRepayment,
      _CalendarDate,
      _PrincipalRepaymentClosing,
      _InterestOfPRClosing,
      _PrincipalRepaymentOpening,
      _InterestOfPROpening,
      _InterestRepaymentCurrentMonth
}
