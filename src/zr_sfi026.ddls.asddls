@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Loan Platform - Analytics Cube'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Analytics:{
    dataCategory: #CUBE
}
define view entity ZR_SFI026
  //  with parameters P_Date : abap.dats
  with parameters
    P_Year : calendaryear
  as select from    ZR_TFI001 as loan
    left outer join ZR_TFI002 as _repayment   on loan.UUID = _repayment.UUIDInterest
    left outer join ZR_TFI003 as _PostingOfIP on  loan.UUID         = _PostingOfIP.UUIDInterest
                                              and _PostingOfIP.Type = '1'
  //    inner join I_Calen
  association [1..1] to I_CalendarDate             as _DocDate         on  _DocDate.CalendarDate = $projection.DocDate
  association [1..1] to ZR_SFI004                  as _DocType         on  _DocType.value_low = $projection.DocType
  association [1..1] to ZR_SFI001                  as _ContractType    on  _ContractType.value_low = $projection.ContractType
  association [1..1] to I_CompanyCode              as _Lender          on  _Lender.CompanyCode = $projection.Lender
  association [1..1] to I_CompanyCode              as _Borrower        on  _Borrower.CompanyCode = $projection.Borrower

  association [0..1] to I_JournalEntry             as _IPJELender      on  _IPJELender.CompanyCode        = $projection.Lender
                                                                       and _IPJELender.FiscalYear         = $projection.InitialPrincipalFiscalYear
                                                                       and _IPJELender.AccountingDocument = $projection.JournalEntryLenderForInterest
  association [0..1] to I_JournalEntry             as _IPJEBorrower    on  _IPJEBorrower.CompanyCode        = $projection.Borrower
                                                                       and _IPJEBorrower.FiscalYear         = $projection.InitialPrincipalFiscalYear
                                                                       and _IPJEBorrower.AccountingDocument = $projection.JournalEntryBorrowerForInter
  association [0..1] to I_JournalEntry             as _DocJELender     on  _DocJELender.CompanyCode        = $projection.Lender
                                                                       and _DocJELender.FiscalYear         = $projection.DocFiscalYear
                                                                       and _DocJELender.AccountingDocument = $projection.JournalEntryLender
  association [0..1] to I_JournalEntry             as _DocJEBorrower   on  _DocJEBorrower.CompanyCode        = $projection.Borrower
                                                                       and _DocJEBorrower.FiscalYear         = $projection.DocFiscalYear
                                                                       and _DocJEBorrower.AccountingDocument = $projection.JournalEntryBorrower
  association [0..1] to I_FiscalYearForCompanyCode as _FiscalYearIP    on  $projection.InitialPrincipalFiscalYear = _FiscalYearIP.FiscalYear
                                                                       and $projection.Lender                     = _FiscalYearIP.CompanyCode
  association [0..1] to I_FiscalYearForCompanyCode as _FiscalYearDoc   on  $projection.DocFiscalYear = _FiscalYearDoc.FiscalYear
                                                                       and $projection.Lender        = _FiscalYearDoc.CompanyCode

  association [0..1] to I_Globalcompany            as _LenderCompany   on  $projection.LenderCompany = _LenderCompany.Company
  association [0..1] to I_Globalcompany            as _BorrowerCompany on  $projection.BorrowerCompany = _BorrowerCompany.Company
  //    left outer join zr_tfi003 as _accrual   on loan.uuid = _accrual.UUIDInterest
{
  key loan.UUID                                                                  as LoanUUID,
  key _repayment.UUID                                                            as DocUUID,
      @ObjectModel.foreignKey.association: '_ContractType'
      loan.ContractType,
      loan.ContractCode,
      loan.ContractName,
      @ObjectModel.foreignKey.association: '_LenderCompany'
      loan.LenderCompany,
      @ObjectModel.foreignKey.association: '_BorrowerCompany'
      loan.BorrowerCompany,
      @ObjectModel.foreignKey.association: '_Lender'
      loan.Lender,
      @ObjectModel.foreignKey.association: '_Borrower'
      loan.Borrower,
      loan.StartDate,
      loan.LoanMaturityDate,
      //      @Semantics.amount.currencyCode: 'Currency'
      //      @Analytics.dataCategory: #DIMENSION
      @Aggregation.default: #NONE
      //      @Semantics.amount.currencyCode: 'Currency'
      cast( curr_to_decfloat_amount( loan.InitialPrincipal ) as abap.char( 50 )) as InitialPrincipal,
      //      loan.InitialPrincipal,
      loan.Currency,
      @ObjectModel.foreignKey.association: '_IPJELender'
      _PostingOfIP.JournalEntryLender                                            as JournalEntryLenderForInterest,
      @ObjectModel.foreignKey.association: '_IPJEBorrower'
      _PostingOfIP.JournalEntryBorrower                                          as JournalEntryBorrowerForInter,
      @ObjectModel.foreignKey.association: '_FiscalYearIP'
      _PostingOfIP.FiscalYear                                                    as InitialPrincipalFiscalYear,

      @ObjectModel.foreignKey.association: '_DocType'
      //      @ObjectModel.text.association: '_DocType'
      case _repayment.RepaymentType1 when '1' then '3'
                                     when '2' then '4' end                       as DocType,
      _repayment.RepaymentDate                                                   as DocDate,

      @ObjectModel.foreignKey.association: '_DocJELender'
      _repayment.JournalEntryLender,
      @ObjectModel.foreignKey.association: '_DocJEBorrower'
      _repayment.JournalEntryBorrower,
      @ObjectModel.foreignKey.association: '_FiscalYearDoc'
      _repayment.FiscalYear                                                      as DocFiscalYear,
      @Semantics.amount.currencyCode: 'DocCurrency'
      @Aggregation.default: #SUM
      cast ( _repayment.RepaymentAmount as zzefi031 )                            as Amount,
      _repayment.Currency                                                        as DocCurrency,


      @Semantics.calendar.year: true
      @ObjectModel.value.derivedFrom: [ 'DocDate' ]
      _DocDate.CalendarYear,

      @Semantics.calendar.month: true
      @ObjectModel.value.derivedFrom: [ 'DocDate' ]
      _DocDate.CalendarMonth,

      @Semantics.calendar.yearMonth: true
      @ObjectModel.value.derivedFrom: [ 'DocDate' ]
      _DocDate.YearMonth,

      _DocDate._CalendarMonth                                                    as _CalendarMonth,
      _DocDate._YearMonth                                                        as _YearMonth,
      _DocDate._CalendarYear                                                     as _CalendarYear,
      _DocType,
      _ContractType,
      _Lender,
      _Borrower,
      _IPJELender,
      _IPJEBorrower,
      _DocJELender,
      _DocJEBorrower,
      _FiscalYearIP,
      _FiscalYearDoc,
      _LenderCompany,
      _BorrowerCompany
}
where
  _DocDate.CalendarYear = $parameters.P_Year

union select from ZR_TFI001 as loan
  left outer join ZR_TFI003 as _accrual     on loan.UUID = _accrual.UUIDInterest
  left outer join ZR_TFI003 as _PostingOfIP on  loan.UUID         = _PostingOfIP.UUIDInterest
                                            and _PostingOfIP.Type = '1'

association [1..1] to I_CalendarDate             as _DocDate         on  _DocDate.CalendarDate = $projection.DocDate
association [1..1] to ZR_SFI004                  as _DocType         on  _DocType.value_low = $projection.DocType
association [1..1] to ZR_SFI001                  as _ContractType    on  _ContractType.value_low = $projection.ContractType
association [1..1] to I_CompanyCode              as _Lender          on  _Lender.CompanyCode = $projection.Lender
association [1..1] to I_CompanyCode              as _Borrower        on  _Borrower.CompanyCode = $projection.Borrower

association [0..1] to I_JournalEntry             as _IPJELender      on  _IPJELender.CompanyCode        = $projection.Lender
                                                                     and _IPJELender.FiscalYear         = $projection.InitialPrincipalFiscalYear
                                                                     and _IPJELender.AccountingDocument = $projection.JournalEntryLenderForInterest
association [0..1] to I_JournalEntry             as _IPJEBorrower    on  _IPJEBorrower.CompanyCode        = $projection.Borrower
                                                                     and _IPJEBorrower.FiscalYear         = $projection.InitialPrincipalFiscalYear
                                                                     and _IPJEBorrower.AccountingDocument = $projection.JournalEntryBorrowerForInter
association [0..1] to I_JournalEntry             as _DocJELender     on  _DocJELender.CompanyCode        = $projection.Lender
                                                                     and _DocJELender.FiscalYear         = $projection.DocFiscalYear
                                                                     and _DocJELender.AccountingDocument = $projection.JournalEntryLender
association [0..1] to I_JournalEntry             as _DocJEBorrower   on  _DocJEBorrower.CompanyCode        = $projection.Borrower
                                                                     and _DocJEBorrower.FiscalYear         = $projection.DocFiscalYear
                                                                     and _DocJEBorrower.AccountingDocument = $projection.JournalEntryBorrower
association [0..1] to I_FiscalYearForCompanyCode as _FiscalYearIP    on  $projection.InitialPrincipalFiscalYear = _FiscalYearIP.FiscalYear
                                                                     and $projection.Lender                     = _FiscalYearIP.CompanyCode
association [0..1] to I_FiscalYearForCompanyCode as _FiscalYearDoc   on  $projection.DocFiscalYear = _FiscalYearDoc.FiscalYear
                                                                     and $projection.Lender        = _FiscalYearDoc.CompanyCode
association [0..1] to I_Globalcompany            as _LenderCompany   on  $projection.LenderCompany = _LenderCompany.Company
association [0..1] to I_Globalcompany            as _BorrowerCompany on  $projection.BorrowerCompany = _BorrowerCompany.Company
{
  key loan.UUID                                                                  as LoanUUID,
  key _accrual.UUID                                                              as DocUUID,
      loan.ContractType,
      loan.ContractCode,
      loan.ContractName,
      loan.LenderCompany,
      loan.BorrowerCompany,
      loan.Lender,
      loan.Borrower,
      loan.StartDate,
      loan.LoanMaturityDate,

      cast( curr_to_decfloat_amount( loan.InitialPrincipal ) as abap.char( 50 )) as InitialPrincipal,
      //      loan.InitialPrincipal,
      loan.Currency,
      _PostingOfIP.JournalEntryLender                                            as JournalEntryLenderForInterest,
      _PostingOfIP.JournalEntryBorrower                                          as JournalEntryBorrowerForInter,
      _PostingOfIP.FiscalYear                                                    as InitialPrincipalFiscalYear,

      case _accrual.Type when '1' then '1'
                                     when '2' then '2' end                       as DocType,
      _accrual.PostingDate                                                       as DocDate,


      _accrual.JournalEntryLender,
      _accrual.JournalEntryBorrower,
      _accrual.FiscalYear                                                        as DocFiscalYear,
      _accrual.Amount                                                            as Amount,
      _accrual.Currency                                                          as DocCurrency,
      _DocDate.CalendarYear,
      _DocDate.CalendarMonth,
      _DocDate.YearMonth,

      _DocDate._CalendarMonth                                                    as _CalendarMonth,
      _DocDate._YearMonth                                                        as _YearMonth,
      _DocDate._CalendarYear                                                     as _CalendarYear,
      _DocType,
      _ContractType,
      _Lender,
      _Borrower,
      _IPJELender,
      _IPJEBorrower,
      _DocJELender,
      _DocJEBorrower,
      _FiscalYearIP,
      _FiscalYearDoc,
      _LenderCompany,
      _BorrowerCompany
}
where
      _DocDate.CalendarYear = $parameters.P_Year
  and _accrual.Type         = '2'


union select from ZR_TFI001 as loan
//  left outer join ZR_TFI003 as _accrual on loan.UUID = _accrual.UUIDInterest
//association [1..1] to I_CalendarDate as _DocDate on _DocDate.CalendarDate = $projection.DocDate
  join            ZR_SFI028 as _CalendarYear on _CalendarYear.CalendarYear = $parameters.P_Year
  left outer join ZR_TFI002 as _Repayment    on loan.UUID = _Repayment.UUIDInterest
  left outer join ZR_TFI003 as _Accrual      on loan.UUID = _Accrual.UUIDInterest

association [1..1] to ZR_SFI004                  as _DocType         on  _DocType.value_low = $projection.DocType
association [1..1] to I_CalendarDate             as _DocDate         on  _DocDate.CalendarDate = $projection.DocDate
association [1..1] to ZR_SFI001                  as _ContractType    on  _ContractType.value_low = $projection.ContractType
association [1..1] to I_CompanyCode              as _Lender          on  _Lender.CompanyCode = $projection.Lender
association [1..1] to I_CompanyCode              as _Borrower        on  _Borrower.CompanyCode = $projection.Borrower

association [0..1] to I_JournalEntry             as _IPJELender      on  _IPJELender.CompanyCode        = $projection.Lender
                                                                     and _IPJELender.FiscalYear         = $projection.InitialPrincipalFiscalYear
                                                                     and _IPJELender.AccountingDocument = $projection.JournalEntryLenderForInterest
association [0..1] to I_JournalEntry             as _IPJEBorrower    on  _IPJEBorrower.CompanyCode        = $projection.Borrower
                                                                     and _IPJEBorrower.FiscalYear         = $projection.InitialPrincipalFiscalYear
                                                                     and _IPJEBorrower.AccountingDocument = $projection.JournalEntryBorrowerForInter
association [0..1] to I_JournalEntry             as _DocJELender     on  _DocJELender.CompanyCode        = $projection.Lender
                                                                     and _DocJELender.FiscalYear         = $projection.DocFiscalYear
                                                                     and _DocJELender.AccountingDocument = $projection.JournalEntryLender
association [0..1] to I_JournalEntry             as _DocJEBorrower   on  _DocJEBorrower.CompanyCode        = $projection.Borrower
                                                                     and _DocJEBorrower.FiscalYear         = $projection.DocFiscalYear
                                                                     and _DocJEBorrower.AccountingDocument = $projection.JournalEntryBorrower
association [0..1] to I_FiscalYearForCompanyCode as _FiscalYearIP    on  $projection.InitialPrincipalFiscalYear = _FiscalYearIP.FiscalYear
                                                                     and $projection.Lender                     = _FiscalYearIP.CompanyCode
association [0..1] to I_FiscalYearForCompanyCode as _FiscalYearDoc   on  $projection.DocFiscalYear = _FiscalYearDoc.FiscalYear
                                                                     and $projection.Lender        = _FiscalYearDoc.CompanyCode
association [0..1] to I_Globalcompany            as _LenderCompany   on  $projection.LenderCompany = _LenderCompany.Company
association [0..1] to I_Globalcompany            as _BorrowerCompany on  $projection.BorrowerCompany = _BorrowerCompany.Company
{
  key loan.UUID                                                                  as LoanUUID,
  key loan.UUID                                                                  as DocUUID,
      loan.ContractType,
      loan.ContractCode,
      loan.ContractName,
      loan.LenderCompany,
      loan.BorrowerCompany,
      loan.Lender,
      loan.Borrower,
      loan.StartDate,
      loan.LoanMaturityDate,

      cast( curr_to_decfloat_amount( loan.InitialPrincipal ) as abap.char( 50 )) as InitialPrincipal,
      //      loan.InitialPrincipal,
      loan.Currency,

      cast( '' as belnr_d )                                                      as JournalEntryLenderForInterest,
      cast( '' as belnr_d )                                                      as JournalEntryBorrowerForInter,
      cast('0000' as gjahr)                                                      as InitialPrincipalFiscalYear,

      '0'                                                                        as DocType,
      _CalendarYear.FirstDayOfYear                                               as DocDate,


      cast( '' as belnr_d )                                                      as JournalEntryLender,
      cast( '' as belnr_d )                                                      as JournalEntryBorrower,
      cast('0000' as gjahr)                                                      as DocFiscalYear,

      cast(0 as zzefi031 )                                                       as Amount,
      loan.Currency                                                              as DocCurrency,
      //      _CalendarYear.CalendarYear,
      //      _CalendarYear.CalendarMonth,
      //      _CalendarYear.YearMonth,
      _DocDate.CalendarYear,
      _DocDate.CalendarMonth,
      _DocDate.YearMonth,

      _DocDate._CalendarMonth                                                    as _CalendarMonth,
      _DocDate._YearMonth                                                        as _YearMonth,
      _DocDate._CalendarYear                                                     as _CalendarYear,
      _DocType,
      _ContractType,
      _Lender,
      _Borrower,
      _IPJELender,
      _IPJEBorrower,
      _DocJELender,
      _DocJEBorrower,
      _FiscalYearIP,
      _FiscalYearDoc,
      _LenderCompany,
      _BorrowerCompany
}
where
      _Repayment.UUIDInterest is null
  and _Accrual.UUIDInterest   is null
