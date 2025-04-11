@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Interest'
define root view entity ZR_TFI001
  as select from ztfi001 as Interest
  composition of many ZR_TFI002         as _Repayment
  composition of many ZR_TFI003         as _Accrual
  association [0..*] to ZR_SFI001T      as _ContractTypeText    on  $projection.ContractType = _ContractTypeText.value_low
  association [0..1] to I_CompanyCode   as _LenderCompanyCode   on  $projection.Lender = _LenderCompanyCode.CompanyCode
  association [0..1] to I_CompanyCode   as _BorrowerCompanyCode on  $projection.Borrower = _BorrowerCompanyCode.CompanyCode

  association [0..1] to I_Globalcompany as _Lender              on  $projection.LenderCompany = _Lender.Company
  association [0..1] to I_Globalcompany as _Borrower            on  $projection.BorrowerCompany = _Borrower.Company

  association [0..1] to ZR_SFI008       as _Calculation         on  $projection.UUID = _Calculation.uuid
  association [0..1] to ZR_SFI032       as _ExchangeRate        on  _ExchangeRate.SourceCurrency   = $projection.Currency
                                                                and _ExchangeRate.TargetCurrency   = 'EUR'
                                                                and _ExchangeRate.ExchangeRateType = 'G'

{
  key uuid                                                                                  as UUID,
      contract_type                                                                         as ContractType,
      contract_code                                                                         as ContractCode,
      contract_name                                                                         as ContractName,
      lender_company                                                                        as LenderCompany,
      lender                                                                                as Lender,
      borrower_company                                                                      as BorrowerCompany,
      borrower                                                                              as Borrower,
      start_date                                                                            as StartDate,
      loan_maturity_date                                                                    as LoanMaturityDate,
      @Semantics.amount.currencyCode: 'Currency'
      initial_principal                                                                     as InitialPrincipal,
      currency                                                                              as Currency,
      //      cast( exchange_rate as abap.dec( 9, 5 ) ) as ExchangeRate,
      cast( _ExchangeRate(P_Date : $session.system_date).ExchangeRate as abap.dec( 9, 5 ) ) as ExchangeRate,

      ex_rates                                                                              as ExRates,
      other_expenses                                                                        as OtherExpenses,
      house_bank_lender                                                                     as HouseBankLender,
      account_id_lender                                                                     as AccountIDLender,
      house_bank_borrower                                                                   as HouseBankBorrower,
      account_id_borrower                                                                   as AccountIDBorrower,
      cash_flow                                                                             as CashFlowLender,
      cash_flow_borrower                                                                    as CashFlowBorrower,
      addition_note                                                                         as AdditionNote,

      _Calculation(P_Date : $session.system_date).CurrencyEUR,
      _Calculation(P_Date : $session.system_date).InitialPrincipalEUR,
      _Calculation(P_Date : $session.system_date).PrincipalRepayment,
      _Calculation(P_Date : $session.system_date).PrincipalBalance,
      _Calculation(P_Date : $session.system_date).PrincipalBalanceEUR,
      _Calculation(P_Date : $session.system_date).AccumulatedInterest,
      _Calculation(P_Date : $session.system_date).InterestRepayment,
      _Calculation(P_Date : $session.system_date).InterestBalance,
      _Calculation(P_Date : $session.system_date).InterestBalanceEUR,
      _Calculation(P_Date : $session.system_date).MonthlyInterestAccrual,


      @Semantics.user.createdBy: true
      created_by                                                                            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                                                                            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by                                                                       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                                                                       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at                                                                 as LocalLastChangedAt,
      _Repayment,
      _Accrual,
      _ContractTypeText,
      _Lender,
      _LenderCompanyCode,
      _Borrower,
      _BorrowerCompanyCode,
      _Calculation,
      _ExchangeRate

}
