@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_TFI_IC_ACCT
  provider contract transactional_query
  as projection on ZR_TFI_IC_ACCT
{
  key Item,
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI048', element: 'value_low' }, useForValidation: true }]
  @ObjectModel.text.element: [ 'TypeText' ]
  key Type,
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI049', element: 'value_low' }, useForValidation: true }]
  @ObjectModel.text.element: [ 'SignText' ]
  key Sign,
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI050', element: 'value_low' }, useForValidation: true }]
  @ObjectModel.text.element: [ 'OptionText' ]
  key Zoption,
  key Accountfrom,
  Accountto,
  Createdby,
  Createdat,
  Lastchangedby,
  Lastchangedat,
  Locallastchangedat,
  _TypeText,
  _SignText,
  _TypeText.text as TypeText : localized,
  _SignText.text as SignText : localized,
  _OptionText.text as OptionText : localized
}
