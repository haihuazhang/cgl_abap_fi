@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Analytics Cube 2 of Loan Platform - By Date'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Analytics:{
    dataCategory: #CUBE
}
@Metadata.allowExtensions: true

define view entity ZR_SFI029
  with parameters
    P_Date : datum
  as select from ztfi001                               as Interest
    inner join   ZR_SFI008(P_Date: $parameters.P_Date) as _Calculation on Interest.uuid = _Calculation.uuid
  //  association [0..*] to ZR_SFI001T    as _ContractTypeText on $projection.ContractType = _ContractTypeText.value_low
  association [0..1] to I_Globalcompany as _Lender        on $projection.Lender = _Lender.Company
  association [0..1] to I_Globalcompany as _Borrower      on $projection.Borrower = _Borrower.Company


  association [1..*] to ZR_SFI001T    as _ContractTypeT on _ContractTypeT.value_low = $projection.ContractType

{
  key Interest.uuid                                      as UUID,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI001', element: 'value_low' }, useForValidation: true }]
      @ObjectModel.text.association: '_ContractTypeT'
      Interest.contract_type                             as ContractType,
      Interest.contract_code                             as ContractCode,
      Interest.contract_name                             as ContractName,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Globalcompany', element: 'Company' }, useForValidation: true}]
      @ObjectModel.foreignKey.association: '_Lender'
      @ObjectModel.text.association: '_Lender'
      Interest.lender_company                                    as Lender,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Globalcompany', element: 'Company' }, useForValidation: true}]
      @ObjectModel.foreignKey.association: '_Borrower'
      @ObjectModel.text.association: '_Borrower'
      Interest.borrower_company                                  as Borrower,
      Interest.start_date                                as StartDate,
      Interest.loan_maturity_date                        as LoanMaturityDate,
      @Semantics.amount.currencyCode: 'Currency'
      @Aggregation.default: #SUM
      Interest.initial_principal                         as InitialPrincipal,
      //        @Semantics.currencyCode: true
      Interest.currency                                  as Currency,
      @EndUserText.label: 'Exchange Rate'
//      cast( Interest.exchange_rate as abap.dec( 9, 5 ) ) as ExchangeRate,
      cast( _Calculation.ExchangeRate as abap.dec(9,5) ) as ExchangeRate,
      Interest.ex_rates                                  as ExRates,
      @Semantics.amount.currencyCode: 'Currency'
      @Aggregation.default: #SUM
      Interest.other_expenses                            as OtherExpenses,
      Interest.house_bank_lender                         as HouseBankLender,
      Interest.account_id_lender                         as AccountIDLender,
      Interest.house_bank_borrower                       as HouseBankBorrower,
      Interest.account_id_borrower                       as AccountIDBorrower,
      Interest.cash_flow                                 as CashFlowLender,
      Interest.cash_flow_borrower                        as CashFlowBorrower,

      //      @Semantics.currencyCode: true
      _Calculation.CurrencyEUR,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'CurrencyEUR'
      _Calculation.InitialPrincipalEUR,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'Currency'
      _Calculation.PrincipalRepayment,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'Currency'
      _Calculation.PrincipalBalance,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'CurrencyEUR'
      _Calculation.PrincipalBalanceEUR,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'Currency'
      _Calculation.AccumulatedInterest,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'Currency'
      _Calculation.InterestRepayment,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'Currency'
      _Calculation.InterestBalance,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'CurrencyEUR'
      _Calculation.InterestBalanceEUR,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'Currency'
      _Calculation.MonthlyInterestAccrual,


      @Semantics.user.createdBy: true
      Interest.created_by                                as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      Interest.created_at                                as CreatedAt,
      @Semantics.user.lastChangedBy: true
      Interest.last_changed_by                           as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      Interest.last_changed_at                           as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Interest.local_last_changed_at                     as LocalLastChangedAt,
      //      _Repayment,
      //      _Accrual,
      //      _ContractTypeText,
      _ContractTypeT,
      _Lender,
      _Borrower
      //      _Calculation
}
