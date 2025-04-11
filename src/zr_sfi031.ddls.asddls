@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Latest Exchange Rate for giving date'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI031
  with parameters
    P_Date : datum
  as select from I_ExchangeRateRawData
{
  key ExchangeRateType,
  key SourceCurrency,
  key TargetCurrency,
      max( ValidityStartDate ) as ValidityStartDate
      //      ExchangeRate,
      //      NumberOfSourceCurrencyUnits,
      //      NumberOfTargetCurrencyUnits
}
where
  ValidityStartDate <= $parameters.P_Date
group by
  ExchangeRateType,
  SourceCurrency,
  TargetCurrency
