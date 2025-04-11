@Metadata.allowExtensions: true
@EndUserText.label: 'Accrual'
@AccessControl.authorizationCheck: #CHECK
define view entity ZC_TFI003
  //  provider contract transactional_query
  as projection on ZR_TFI003

{
  key UUID,
      UUIDInterest,
      CompanyCode,
      FiscalYear,
      //      AccountingDocument,
      @ObjectModel.text.element: [ 'TypeText' ]
      Type,
      PostingDate,
      Amount,
      Currency,
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
      _TypeText.text as TypeText : localized,
      _Interest : redirected to parent ZC_TFI001,
      _TypeText,
      _LenderJournalEntry,
      _BorrowerJournalEntry
}
where JournalEntryLenderReversed = '' or JournalEntryBorrowerReversed = ''
