@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_TFI006
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_TFI006
{
  key Uuid,
  Glaccount,
  Incometype,
  Incomedescribtion,
  CreatedBy,
  CreatedAt,
  LastChangedBy,
  LastChangedAt,
  LocalLastChangedAt
  
}
