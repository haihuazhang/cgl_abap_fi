@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Master of lucanet GLaccount'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI060 as select from I_GLAccountInCompanyCode
{
    key GLAccount,
    key CompanyCode,
    AuthorizationGroup,
    AccountingClerk,
    LastInterestCalcRunDate,
    CreationDate,
    CreatedByUser,
    LastChangeDateTime,
    PlanningLevel,
    HouseBank,
    HouseBankAccount,
    ExchRateDifferencesAccountDetn,
    ReconciliationAccountType,
    TaxCategory,
    InterestCalculationCode,
    GLAccountCurrency,
    ReconciliationAcctIsChangeable,
    IsManagedExternally,
    IsAutomaticallyPosted,
    LineItemDisplayIsEnabled,
    SupplementIsAllowed,
    IsOpenItemManaged,
    InterestCalculationDate,
    IntrstCalcFrequencyInMonths,
    AcctgDocItmDisplaySequenceRule,
    AlternativeGLAccount,
    JointVentureRecoveryCode,
//    CommitmentItem,
    CommitmentItemShortID,
    TaxCodeIsRequired,
    BalanceHasLocalCurrency,
    ValuationGroup,
    APARToleranceGroup,
    AccountIsBlockedForPosting,
    AccountIsMarkedForDeletion,
    ClearingIsLedgerGroupSpecific,
    CashPlanningGroup,
    IsCashFlowAccount,
    GLAcctInflationKey,
    FieldStatusGroup,
    MultiCurrencyAccountingCode,
    IsExtendedOpenItemManaged
}
