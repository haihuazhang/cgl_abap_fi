@Metadata.allowExtensions: true
@EndUserText.label: 'Repayment'
@AccessControl.authorizationCheck: #CHECK
define view entity ZC_TFI002
  //  provider contract transactional_query
  as projection on ZR_TFI002
  association [0..1] to I_JournalEntry as _BorrowerJournalEntry on _BorrowerJournalEntry.CompanyCode = $projection.Borrower
                                                                and _BorrowerJournalEntry.FiscalYear = $projection.FiscalYear
                                                                and _BorrowerJournalEntry.AccountingDocument = $projection.JournalEntryBorrower
{
  key UUID,
      UUIDInterest,
      CompanyCode,
      FiscalYear,
      //      AccountingDocument,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI002', element: 'value_low' }, useForValidation: true }]
      @ObjectModel.text.element: [ 'RepaymentType1Text' ]
      RepaymentType1,
      RepaymentDate,
      RepaymentAmount,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' }, useForValidation: true}]
      Currency,
      PostingDate,
      RepaymentNumber,
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
      Notes,
      JournalEntryLender,
      JournalEntryBorrower,
      JournalEntryLenderReversed,
      JournalEntryBorrowerReversed,
      JELenderStatusText,
      JELenderStatusCriticality,
      JEBorrowerStatusText,
      JEBorrowerStatusCriticality,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      Lender,
      Borrower,
      LenderCompany,
      BorrowerCompany,
//      _Interest.Lender,
//      _Interest.Borrower,
      _RepaymentType1Text.text as RepaymentType1Text : localized,
      _Interest : redirected to parent ZC_TFI001,
      _RepaymentType1Text,
      _BorrowerJournalEntry
}
