@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'First Day of Year'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI028
  as select from I_CalendarYear as Year
    inner join   I_CalendarDate as _Date on _Date.CalendarYear = Year.CalendarYear
{
  key Year.CalendarYear,
      min( _Date.CalendarDate)  as FirstDayOfYear,
      min( _Date.CalendarMonth) as CalendarMonth,
      min( _Date.YearMonth)     as YearMonth
      //    IsLeapYear,
      //    NumberOfDays
}
group by
  Year.CalendarYear
