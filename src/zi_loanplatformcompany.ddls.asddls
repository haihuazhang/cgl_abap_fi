@EndUserText.label: 'Loan Platform - Company Code Status'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZI_LoanPlatformCompany
  as select from ZTFI010
  association to parent ZR_TFI010 as _LoanPlatformCompAll on $projection.SingletonID = _LoanPlatformCompAll.SingletonID
{
  key COMPANY_CODE as CompanyCode,
  POST_STATUS as PostStatus,
  @Semantics.user.createdBy: true
  CREATED_BY as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  CREATED_AT as CreatedAt,
  @Semantics.user.lastChangedBy: true
  LAST_CHANGED_BY as LastChangedBy,
  @Semantics.systemDateTime.lastChangedAt: true
  LAST_CHANGED_AT as LastChangedAt,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  @Consumption.hidden: true
  LOCAL_LAST_CHANGED_AT as LocalLastChangedAt,
  @Consumption.hidden: true
  1 as SingletonID,
  _LoanPlatformCompAll
  
}
