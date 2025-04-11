@Metadata.allowExtensions: true
@AccessControl.authorizationCheck: #CHECK
@AbapCatalog.viewEnhancementCategory: [#NONE]
@EndUserText.label: 'Travel Status Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
 serviceQuality: #A,
 sizeCategory: #S,
 dataClass: #MASTER
 }
define root view entity ZC_TFI004
  provider contract transactional_query
  as projection on ZR_TFI004
{
  
  key Uuid,
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI004', element: 'value_low' }, useForValidation: true }]
  @ObjectModel.text.element: [ 'typeText' ]
  Type,
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI005', element: 'value_low' }, useForValidation: true }]
  @ObjectModel.text.element: [ 'boLenText' ]
  BoLen,
  CashFlow,
  CashFlowCode,
  @Semantics.currencyCode: true
  @Consumption.valueHelpDefinition: [{ entity : { name : 'I_CurrencyStdVH',
                                        element : 'Currency'  } }]
  Currency,
  Debit,
  Credit,
  CreatedBy,
  CreatedAt,
  LastChangedBy,
  LastChangedAt,
  LocalLastChangedAt,
  _typeText.text as typeText : localized,
  _typeText,
  _BoLen_Text.text as boLenText : localized,
  _BoLen_Text
}
