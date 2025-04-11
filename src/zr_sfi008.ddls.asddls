@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Report for Interest Platform - Interest'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI008
  with parameters
    P_Date : datum
  as select from ZR_SFI006(P_Date : $parameters.P_Date )
  //  as select from ZR_TFI001
  //  association [0..1] to ZR_SFI006 as _CalculateBase on $projection.UUID = _CalculateBase.UUID
  association [0..1] to ZR_SFI032 as _ExchangeRate on  _ExchangeRate.SourceCurrency   = $projection.Currency
                                                   and _ExchangeRate.TargetCurrency   = 'EUR'
                                                   and _ExchangeRate.ExchangeRateType = 'G'
{
  key uuid,
      //      ContractType,
      //      ContractCode,
      //      ContractName,
      //      Lender,
      //      Borrower,
      StartDate,
      //      LoanMaturityDate,
      @Semantics.amount.currencyCode: 'Currency'
      InitialPrincipal,
      Currency,
      //      ExchangeRate,
      _ExchangeRate(P_Date: $parameters.P_Date).ExchangeRate,
      //      ExRates,
      //      @Semantics.amount.currencyCode: 'Currency'
      //      OtherExpenses,
      //      HouseBankLender,
      //      AccountIDLender,
      //      HouseBankBorrower,
      //      AccountIDBorrower,
      //      CashFlow,
      //      CurrencyEUR,
      //      InitialPrincipalEUR,
      @Semantics.amount.currencyCode: 'Currency'
      PrincipalRepayment, //已还款总额

      @Semantics.amount.currencyCode: 'Currency'
      PrincipalBalance, //剩余欠款总额

      @Semantics.amount.currencyCode: 'Currency'
      AccumulatedInterest, //利息总额

      @Semantics.amount.currencyCode: 'Currency'
      InterestRepayment, //已偿还利息

      @Semantics.amount.currencyCode: 'Currency'
      InterestBalance, //剩余利息

      @Semantics.amount.currencyCode: 'Currency'
      AccumulatedInterestClose, //月末利息

      @Semantics.amount.currencyCode: 'Currency'
      AccumulatedInterestOpen, //月初利息

      @Semantics.amount.currencyCode: 'Currency'
      InterestRepaymentCurrentMonth, //本月已还利息


      @Semantics.amount.currencyCode: 'Currency'
      cast( AccumulatedInterestClose -
      AccumulatedInterestOpen as zzefi034 )                                                                                                                                                                                                                                     as MonthlyInterestAccrual, //当月利息计提金额
      //      +
      //      InterestRepaymentCurrentMonth as zzefi034 )                                                                                                                                                                                                                               as MonthlyInterestAccrual, //当月利息计提金额


      cast('EUR' as abap.cuky )                                                                                                                                                                                                                                                 as CurrencyEUR,

      @Semantics.amount.currencyCode: 'CurrencyEUR'
      cast( curr_to_decfloat_amount ( InitialPrincipal ) * _ExchangeRate(P_Date: $parameters.P_Date).ExchangeRate * _ExchangeRate(P_Date: $parameters.P_Date).NumberOfTargetCurrencyUnits / _ExchangeRate(P_Date: $parameters.P_Date).NumberOfSourceCurrencyUnits as zzefi009 ) as InitialPrincipalEUR,

      @Semantics.amount.currencyCode: 'CurrencyEUR'
      cast( curr_to_decfloat_amount ( PrincipalBalance ) * _ExchangeRate(P_Date: $parameters.P_Date).ExchangeRate * _ExchangeRate(P_Date: $parameters.P_Date).NumberOfTargetCurrencyUnits / _ExchangeRate(P_Date: $parameters.P_Date).NumberOfSourceCurrencyUnits as zzefi012 ) as PrincipalBalanceEUR,

      @Semantics.amount.currencyCode: 'CurrencyEUR'
      cast( curr_to_decfloat_amount ( InterestBalance ) * _ExchangeRate(P_Date: $parameters.P_Date).ExchangeRate * _ExchangeRate(P_Date: $parameters.P_Date).NumberOfTargetCurrencyUnits / _ExchangeRate(P_Date: $parameters.P_Date).NumberOfSourceCurrencyUnits as zzefi017 )  as InterestBalanceEUR,

      _ExchangeRate

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
      //      _CalculateBase
}
