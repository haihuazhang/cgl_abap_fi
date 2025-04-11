@EndUserText.label: '  Maintain Tax Code'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_MaintainTaxCode
  as select from ZTFI011
  association to parent ZI_MaintainTaxCode_S as _MaintainTaxCodeAll on $projection.SingletonID = _MaintainTaxCodeAll.SingletonID
{
  key TAXCODE as Taxcode,
  key TAXCOUNRTY as Taxcounrty,
  TAXRATE as Taxrate,
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
  _MaintainTaxCodeAll
  
}
