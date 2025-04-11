@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_TFI009
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_TFI009
{
  key Uuid,
  Emailtype,
  Emailsubject,
  Emailcontent,
  Createdby,
  Createdat,
  Lastchangedby,
  Lastchangedat,
  Locallastchangedat
  
}
