@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_TFI011
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_TFI011
{
  key Taxcode,
  key Taxcounrty,
  Taxrate,
  Createdby,
  Createdat,
  Lastchangedby,
  Lastchangedat,
  Locallastchangedat
  
}
