@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Reconciliation Statements'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true
define root view entity ZR_SFI051_1
  with parameters                                           
   p_FiscalYear: calendaryear,
   p_FiscalPeriod :calendarmonth
  as select from    I_JournalEntryItem  as _JournalEntryItem    
   left outer join   ztfi_ic_acct     as _Config       on  ( 
            ( _Config.zoption = 'BT' and _JournalEntryItem.GLAccount between _Config.accountfrom and _Config.accountto ) or
            ( _Config.zoption = 'EQ' and _JournalEntryItem.GLAccount = _Config.accountfrom )
        )   
             left outer join ZR_SFI063  as   _SFI063  on _SFI063.CalendarYear = $parameters.p_FiscalYear
                                           and _SFI063.CalendarMonth = $parameters.p_FiscalPeriod                                                                                                                                     
{

  key _JournalEntryItem.CompanyCode             as CompanyCode,
  key $parameters.p_FiscalYear                  as FiscalYear,
  key $parameters.p_FiscalPeriod                as  FiscalPeriod,
  key _JournalEntryItem.PartnerCompany          as PartnerCompany,
  key _JournalEntryItem.TransactionCurrency     as TransactionCurrency,
  key _JournalEntryItem.GlobalCurrency          as GlobalCurrency,
  key _Config.item                              as Item,
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
   sum( _JournalEntryItem.AmountInTransactionCurrency ) as TotalAmount ,
    @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
   sum( _JournalEntryItem.AmountInGlobalCurrency ) as TotalAmountGlobal
} where _JournalEntryItem.SourceLedger = '0L'  and _JournalEntryItem.PostingDate <= _SFI063.calendardate
and _JournalEntryItem.PartnerCompany is not initial
group by
    _JournalEntryItem.CompanyCode,
    _JournalEntryItem.PartnerCompany,
    _JournalEntryItem.TransactionCurrency,
    _Config.item,
    _JournalEntryItem.GlobalCurrency
