@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Latest Exchange Rate Ratio for giving date'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI033
  with parameters
    P_Date : datum
  as select from I_ExchangeRateFactorsRawData
{
  key ExchangeRateType,
  key SourceCurrency,
  key TargetCurrency,
      max ( ValidityStartDate ) as ValidityStartDate
      //    NumberOfSourceCurrencyUnits,
      //    NumberOfTargetCurrencyUnits,
      //    AlternativeExchangeRateType,
      //    AltvExchangeRateTypeValdtyDate,
      //    /* Associations */
      //    _ExchangeRateType,
      //    _SourceCurrency,
      //    _TargetCurrency
}
where
  ValidityStartDate <= $parameters.P_Date
group by
  ExchangeRateType,
  SourceCurrency,
  TargetCurrency
