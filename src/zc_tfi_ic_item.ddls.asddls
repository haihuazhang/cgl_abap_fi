@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_TFI_IC_ITEM
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_TFI_IC_ITEM
{
  key Item,
  Description,
  Column1,
  Column2,
  Column3,
  Column4,
  Createdby,
  Createdat,
  Lastchangedby,
  Lastchangedat,
  Locallastchangedat
  
}
