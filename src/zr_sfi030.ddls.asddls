@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Loan Contracts Report-Repayment'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
//@Analytics:{
//    dataCategory: #CUBE
//}
@Metadata.allowExtensions: true
define view entity ZR_SFI030
  as select from ZR_TFI002
  //  association [0..1] to ZR_TFI001       as _Interest on $projection.UUIDInterest = _Interest.UUID
  association [0..1] to I_Globalcompany as _Lender   on $projection.lendercompany = _Lender.Company
  association [0..1] to I_Globalcompany as _Borrower on $projection.borrowercompany = _Borrower.Company
  association [0..*] to ZR_SFI001T      as _ContractTypeText    on  $projection.contracttype = _ContractTypeText.value_low
{
  key UUID,
      UUIDInterest,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI001', element: 'value_low' }, useForValidation: true}]
      @ObjectModel.text.association: '_ContractTypeText'
      _Interest.ContractType,
      _Interest.ContractCode,
      _Interest.ContractName,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Globalcompany', element: 'Company' }, useForValidation: true}]
//      @ObjectModel.foreignKey.association: '_Lender'
      @ObjectModel.text.association: '_Lender'
      _Interest.LenderCompany,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Globalcompany', element: 'Company' }, useForValidation: true}]
//      @ObjectModel.foreignKey.association: '_Borrower'
      @ObjectModel.text.association: '_Borrower'
      _Interest.BorrowerCompany,
      _Interest.StartDate,
      _Interest.LoanMaturityDate,
      @Semantics.amount.currencyCode: 'Currency'
      _Interest.InitialPrincipal,
      FiscalYear,
      @ObjectModel.text.association: '_RepaymentType1Text'
      RepaymentType1,
      RepaymentDate,
      @Semantics.amount.currencyCode: 'Currency'
      @Aggregation.default: #SUM
      RepaymentAmount,
      Currency,
      //      PostingDate,
      RepaymentNumber,
      //      HouseBankLender,
      //      AccountIDLender,
      //      HouseBankBorrower,
      //      AccountIDBorrower,
      //      CashFlowLender,
      //      CashFlowBorrower,
      //      Notes,
      JournalEntryLender,
      JournalEntryBorrower,
      Lender,
      Borrower,
      Notes,

      //      JournalEntryLenderReversed,
      //      JournalEntryBorrowerReversed,
      //      JELenderStatusText,
      //      JELenderStatusCriticality,
      //      JEBorrowerStatusText,
      //      JEBorrowerStatusCriticality,
      //      CreatedBy,
      //      CreatedAt,
      //      LastChangedBy,
      //      LastChangedAt,
      //      LocalLastChangedAt,
      /* Associations */
      _BorrowerJournalEntry,
      _Interest,
      _LenderJournalEntry,
      _RepaymentType1Text,
      _Lender,
      _Borrower,
      _ContractTypeText
}
