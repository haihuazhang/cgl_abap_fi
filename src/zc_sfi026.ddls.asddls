@EndUserText.label: 'Analytics Query 1 of Loan Platform'
@AccessControl.authorizationCheck: #NOT_ALLOWED
define transient view entity ZC_SFI026
  provider contract analytical_query
  with parameters
    P_Year : gjahr
  as projection on ZR_SFI026(P_Year: $parameters.P_Year)
{
  LoanUUID,
  DocUUID,
  @UI.textArrangement: #TEXT_ONLY
  @AnalyticsDetails.query.axis: #ROWS
  ContractType,
  @AnalyticsDetails.query.axis: #ROWS
  ContractCode,
  @AnalyticsDetails.query.axis: #ROWS
  ContractName,
  @AnalyticsDetails.query.axis: #ROWS
  @UI.textArrangement: #TEXT_ONLY
  LenderCompany,
  @AnalyticsDetails.query.axis: #ROWS
  @UI.textArrangement: #TEXT_ONLY
  BorrowerCompany,
  @AnalyticsDetails.query.axis: #ROWS
  @UI.textArrangement: #TEXT_ONLY
  Lender,
  @AnalyticsDetails.query.axis: #ROWS
  @UI.textArrangement: #TEXT_ONLY
  Borrower,
  @AnalyticsDetails.query.axis: #ROWS
  //  @AnalyticsDetails.
  StartDate,
  @AnalyticsDetails.query.axis: #ROWS
  LoanMaturityDate,
  //      @Aggregation.default: #SUM
  @AnalyticsDetails.query.axis: #ROWS
  InitialPrincipal,
  @AnalyticsDetails.query.axis: #ROWS
  Currency,
  @AnalyticsDetails.query.axis: #ROWS
  //  @AnalyticsDetails.query.display:
  @Analytics.settings.displayOriginalInitialValue: true
  JournalEntryLenderForInterest,
  @AnalyticsDetails.query.axis: #ROWS
  JournalEntryBorrowerForInter,
  @AnalyticsDetails.query.axis: #COLUMNS
  CalendarMonth,
  @UI.textArrangement: #TEXT_ONLY
  @AnalyticsDetails.query.axis: #COLUMNS
  DocType,
  DocDate,
  @AnalyticsDetails.query.axis: #COLUMNS
  JournalEntryLender,
  @AnalyticsDetails.query.axis: #COLUMNS
  JournalEntryBorrower,
  @Aggregation.default: #SUM
  Amount,
  DocCurrency,
  CalendarYear,
  //  @AnalyticsDetails.
  YearMonth
  //      /* Associations */
  //      _CalendarMonth,
  //      _CalendarYear,
  //      _YearMonth
}
