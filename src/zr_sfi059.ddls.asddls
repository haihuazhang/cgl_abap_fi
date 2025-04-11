@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exchange Rate Raw Data'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI059
  as select from I_ExchangeRateRawData
{
  key ExchangeRateType,
  key SourceCurrency,
  key TargetCurrency,
  key ValidityStartDate,
      cast(  ExchangeRate as abap.dec( 9, 5 ) ) as ExchangeRate,
//      NumberOfSourceCurrencyUnits,
//      NumberOfTargetCurrencyUnits,
      /* Associations */
      _ExchangeRateType,
      _SourceCurrency,
      _TargetCurrency
}
