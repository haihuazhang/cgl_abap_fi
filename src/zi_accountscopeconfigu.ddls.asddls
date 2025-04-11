@EndUserText.label: 'Account Scope Configuration'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_AccountScopeConfigu
  as select from ZTFI_IC_ACCT
  association to parent ZI_AccountScopeConfigu_S as _AccountScopeConfAll on $projection.SingletonID = _AccountScopeConfAll.SingletonID
{
  key ITEM as Item,
  key TYPE as Type,
  key SIGN as Sign,
  key ZOPTION as Zoption,
  key ACCOUNTFROM as Accountfrom,
  ACCOUNTTO as Accountto,
  @Semantics.user.createdBy: true
  CREATEDBY as Createdby,
  @Semantics.systemDateTime.createdAt: true
  CREATEDAT as Createdat,
  @Semantics.user.lastChangedBy: true
  LASTCHANGEDBY as Lastchangedby,
  @Semantics.systemDateTime.lastChangedAt: true
  LASTCHANGEDAT as Lastchangedat,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  @Consumption.hidden: true
  LOCALLASTCHANGEDAT as Locallastchangedat,
  @Consumption.hidden: true
  1 as SingletonID,
  _AccountScopeConfAll
  
}
