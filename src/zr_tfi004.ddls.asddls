@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Travel Status Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
 serviceQuality: #A,
 sizeCategory: #S,
 dataClass: #MASTER
 }
define root view entity ZR_TFI004
  as select from ztfi004
  association [0..*] to ZR_SFI004T as _typeText on $projection.Type = _typeText.value_low
  association [0..*] to ZR_SFI005T as _BoLen_Text on $projection.BoLen =  _BoLen_Text.value_low
{
  key uuid as Uuid,
  type as Type,
  bo_len as BoLen,  
  cash_flow as CashFlow,
  cash_flow_code as CashFlowCode,
  @Consumption.valueHelpDefinition: [{ entity : { name : 'I_CurrencyStdVH',
                                        element : 'Currency'  } }]
  currency as Currency,
  debit as Debit,
  credit as Credit,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.lastChangedBy: true
  last_changed_by as LastChangedBy,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  _typeText,
  _BoLen_Text
}
