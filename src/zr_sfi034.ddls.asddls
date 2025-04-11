@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Latest Exchange Rate Factor for giving date 2'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI034
  with parameters
    P_Date : abap.dats
  //  as select from ZR_SFI031(P_Date : $parameters.P_Date)
  as select from ZR_SFI033(P_Date: $parameters.P_Date)

    inner join   I_ExchangeRateFactorsRawData as _RateFactor on  _RateFactor.ExchangeRateType  = ZR_SFI033.ExchangeRateType
                                                             and _RateFactor.SourceCurrency    = ZR_SFI033.SourceCurrency
                                                             and _RateFactor.TargetCurrency    = ZR_SFI033.TargetCurrency
                                                             and _RateFactor.ValidityStartDate = ZR_SFI033.ValidityStartDate
{
  key ZR_SFI033.ExchangeRateType,
  key ZR_SFI033.SourceCurrency,
  key ZR_SFI033.TargetCurrency,
      ////      ZR_SFI031.ValidityStartDate,
      //      _Rate.ExchangeRate,
      _RateFactor.NumberOfSourceCurrencyUnits,
      _RateFactor.NumberOfTargetCurrencyUnits
}
