@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Latest Exchange Rate for giving date 2'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI032
  with parameters
    P_Date : abap.dats
  as select from ZR_SFI031(P_Date : $parameters.P_Date)
    inner join   ZR_SFI033(P_Date: $parameters.P_Date)       on  ZR_SFI033.ExchangeRateType = ZR_SFI031.ExchangeRateType
                                                             and ZR_SFI033.SourceCurrency   = ZR_SFI031.SourceCurrency
                                                             and ZR_SFI033.TargetCurrency   = ZR_SFI031.TargetCurrency

    inner join   I_ExchangeRateRawData        as _Rate              on  _Rate.ExchangeRateType  = ZR_SFI031.ExchangeRateType
                                                                    and _Rate.SourceCurrency    = ZR_SFI031.SourceCurrency
                                                                    and _Rate.TargetCurrency    = ZR_SFI031.TargetCurrency
                                                                    and _Rate.ValidityStartDate = ZR_SFI031.ValidityStartDate
    inner join   I_ExchangeRateFactorsRawData as _RateFactor on  _RateFactor.ExchangeRateType  = ZR_SFI033.ExchangeRateType
                                                             and _RateFactor.SourceCurrency    = ZR_SFI033.SourceCurrency
                                                             and _RateFactor.TargetCurrency    = ZR_SFI033.TargetCurrency
                                                             and _RateFactor.ValidityStartDate = ZR_SFI033.ValidityStartDate
{
  key ZR_SFI031.ExchangeRateType,
  key ZR_SFI031.SourceCurrency,
  key ZR_SFI031.TargetCurrency,
      ZR_SFI031.ValidityStartDate,
      _Rate.ExchangeRate,
      _RateFactor.NumberOfSourceCurrencyUnits,
      _RateFactor.NumberOfTargetCurrencyUnits
}

union select from I_Currency
{
  key 'M'                  as ExchangeRateType,
  key Currency             as SourceCurrency,
  key Currency             as TargetCurrency,
      $session.system_date as ValidityStartDate,
      1                    as ExchangeRate,
      1                    as NumberOfSourceCurrencyUnits,
      1                    as NumberOfTargetCurrencyUnits

}

union select from I_Currency
{
  key 'G'                  as ExchangeRateType,
  key Currency             as SourceCurrency,
  key Currency             as TargetCurrency,
      $session.system_date as ValidityStartDate,
      1                    as ExchangeRate,
      1                    as NumberOfSourceCurrencyUnits,
      1                    as NumberOfTargetCurrencyUnits

}
