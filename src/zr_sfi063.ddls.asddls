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
define root view entity ZR_SFI063
//  with parameters                                           
//    p_item : zeitem
  as select from    I_CalendarDate  as _CalendarDate                                                                                                                                      
{ 
  key _CalendarDate.CalendarYear                 as CalendarYear,
  key _CalendarDate.CalendarMonth                as CalendarMonth,
 //     _CalendarDate.calendarmonth             as CompanyCode,  
  max(_CalendarDate.CalendarDate)               as calendardate
}
group by
    _CalendarDate.CalendarYear,
    _CalendarDate.CalendarMonth
 
