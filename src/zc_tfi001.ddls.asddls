@Metadata.allowExtensions: true
@EndUserText.label: 'Loan Contract'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_TFI001
  provider contract transactional_query
  as projection on ZR_TFI001

{
  key UUID,

      //      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI001', element: 'value_low' }, useForValidation: true , additionalBinding: [{ parameter: 'p_domain_name', localConstant: 'ZZDFI001' }]}]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI001', element: 'value_low' }, useForValidation: true }]
      @ObjectModel.text.element: [ 'ContractTypeText' ]
      ContractType,
      ContractCode,
      ContractName,
      //      LenderCompanyCode,
      //      BorrowerCompanyCode,
      //      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' }, useForValidation: true}]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Globalcompany', element: 'Company' }, useForValidation: true}]
      @ObjectModel.text.element: [ 'LenderName' ]
      LenderCompany,
      //      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' }, useForValidation: true}]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Globalcompany', element: 'Company' }, useForValidation: true}]
      @ObjectModel.text.element: [ 'BorrowerName' ]
      BorrowerCompany,
      Lender,
      Borrower,

      StartDate,
      LoanMaturityDate,
      InitialPrincipal,
      @Semantics.currencyCode: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' }, useForValidation: true}]
      Currency,
      ExchangeRate,
      ExRates,
      OtherExpenses,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_HouseBankBasic', element: 'HouseBank' }}]
      HouseBankLender,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_HouseBankAccountText', element: 'HouseBankAccount' },
                                           useForValidation: true,
                                           additionalBinding: [{
                                                     element: 'HouseBank',
                                                     localElement: 'HouseBankLender'},
                                                     {
                                                     element: 'Language',
                                                     localConstant: '$session.system_language'  }
       ]}]
      AccountIDLender,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_HouseBankBasic', element: 'HouseBank' }, useForValidation: true}]
      HouseBankBorrower,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_HouseBankAccountText', element: 'HouseBankAccount' },
                                           useForValidation: true,
                                           additionalBinding: [{
                                                     element: 'HouseBank',
                                                     localElement: 'HouseBankBorrower'},
                                                     {
                                                     element: 'Language',
                                                     localConstant: '$session.system_language'  }
       ]}]
      AccountIDBorrower,
      CashFlowLender,
      CashFlowBorrower,
      AdditionNote,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      _ContractTypeText.text as ContractTypeText : localized,
      //      _Lender.CompanyCodeName   as LenderName,
      _Lender.CompanyName    as LenderName,
      //      _Borrower.CompanyCodeName as BorrowerName,
      _Borrower.CompanyName  as BorrowerName,
      CurrencyEUR,
      InitialPrincipalEUR,
      PrincipalRepayment,
      PrincipalBalance,
      PrincipalBalanceEUR,
      AccumulatedInterest,
      InterestRepayment,
      InterestBalance,
      InterestBalanceEUR,
      MonthlyInterestAccrual,
      _Repayment : redirected to composition child ZC_TFI002,
      _Accrual   : redirected to composition child ZC_TFI003,
      _ContractTypeText,
      _Lender,
      _Borrower
      //      _Calculation

}
