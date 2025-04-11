@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'A->B  AR'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZR_SFI052
  with parameters                                           
   p_FiscalYear: calendaryear,
   p_FiscalPeriod :calendarmonth
  as select from    I_JournalEntryItem  as _JournalEntryItem  
  left outer join   ztfi_ic_acct     as _Config       on  ( 
            ( _Config.zoption = 'BT' and _JournalEntryItem.GLAccount between _Config.accountfrom and _Config.accountto ) or
            ( _Config.zoption = 'EQ' and _JournalEntryItem.GLAccount = _Config.accountfrom )
        )   and  _Config.type  = 'X'    
  left outer join ZR_SFI063  as   _SFI063  on _SFI063.CalendarYear = $parameters.p_FiscalYear
                                           and _SFI063.CalendarMonth = $parameters.p_FiscalPeriod                 
{
//head
  key _JournalEntryItem.CompanyCode             as CompanyCode,
  key $parameters.p_FiscalYear                  as FiscalYear,
  key $parameters.p_FiscalPeriod                as  FiscalPeriod,
  key _JournalEntryItem.PartnerCompany          as PartnerCompany,
  key _Config.item                              as Item,
  key _JournalEntryItem.GlobalCurrency          as GlobalCurrency,   
  key _JournalEntryItem.TransactionCurrency     as TransactionCurrency,
//  key _JournalEntryItem.PostingDate             as PostingDate,
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
   sum( _JournalEntryItem.AmountInTransactionCurrency ) as TotalAmount,
   @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
   sum( _JournalEntryItem.AmountInGlobalCurrency ) as TotalAmountGlobal
   
} where _JournalEntryItem.SourceLedger = '0L'   and _JournalEntryItem.PostingDate <= _SFI063.calendardate
group by 
    _JournalEntryItem.CompanyCode,
    _JournalEntryItem.PartnerCompany,
    _JournalEntryItem.TransactionCurrency,
    _Config.item,
    _JournalEntryItem.GlobalCurrency
//    _JournalEntryItem.PostingDate
