@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_TFI_IC_ACCT
  as select from ztfi_ic_acct
   association [0..*] to ZR_SFI048T      as _TypeText    on  $projection.Type = _TypeText.value_low
   association [0..*] to ZR_SFI049T      as _SignText    on  $projection.Sign = _SignText.value_low
   association [0..*] to ZR_SFI050T      as _OptionText    on  $projection.Zoption = _OptionText.value_low
{
  key item as Item,
  key type as Type,
  key sign as Sign,
  key zoption as Zoption,
  key accountfrom as Accountfrom,
  accountto as Accountto,
  @Semantics.user.createdBy: true
  createdby as Createdby,
  @Semantics.systemDateTime.createdAt: true
  createdat as Createdat,
  @Semantics.user.lastChangedBy: true
  lastchangedby as Lastchangedby,
  @Semantics.systemDateTime.lastChangedAt: true
  lastchangedat as Lastchangedat,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  locallastchangedat as Locallastchangedat,
  _TypeText ,
  _SignText,
  _OptionText
}
