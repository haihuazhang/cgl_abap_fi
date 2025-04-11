@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Fixed Asset Valuation for Ledger - Fix'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI056 as select from I_AssetValuationForLedger
{
    key CompanyCode,
    key MasterFixedAsset,
    key FixedAsset,
    key Ledger,
    key AssetRealDepreciationArea,
    key ValidityEndDate,
    ValidityStartDate,
    DepreciationStartDate,
    SpecialDeprStartDate,
    DeprKeyChangeoverYear,
    DeprKeyChangeoverPeriod,
    DepreciationKey,
    InvestmentSupportMeasure,
    PlannedUsefulLifeInPeriods,
    PlannedUsefulLifeInYears,
    VintageYear,
    VintageMonth,
    OriglAstUsefulLifeInPerds,
    OriglAstUsefulLifeInYears,
//    ReplacementValueIndexSers,
//    RplcmtValueAgingIndexSers,
    AcqnProdnCostScrapPercent,
    VariableDeprPercent,
    ShiftOperationFactor,
    IsShutDown,
    DeprCalcBaseValuePercent,
    LastRetirementValueDate,
    DepreciationAreaType,
    @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
    ScrapAmountInCoCodeCrcy,
    CompanyCodeCurrency,
    AssetOpgReadinessDate,
    FixedAssetUsageObject,
    AssetRevaluationIndex,
    /* Associations */
    _AssetRevaluationIndex,
    _CompanyCode,
    _CompanyCodeCurrency,
    _DepreciationArea,
    _FixedAsset,
    _FixedAssetUsageObject,
    _Ledger,
    _MasterFixedAsset,
//    _ReplacementValueIndexSers,
    _ScrapAmount
}
