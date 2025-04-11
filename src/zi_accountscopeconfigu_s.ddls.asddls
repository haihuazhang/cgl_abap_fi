@EndUserText.label: 'Account Scope Configuration Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'AccountScopeConfAll'
  }
}
define root view entity ZI_AccountScopeConfigu_S
  as select from I_Language
    left outer join ZTFI_IC_ACCT on 0 = 0
  association [0..*] to I_ABAPTransportRequestText as _ABAPTransportRequestText on $projection.TransportRequestID = _ABAPTransportRequestText.TransportRequestID
  composition [0..*] of ZI_AccountScopeConfigu as _AccountScopeConfigu
{
  @UI.facet: [ {
    id: 'ZI_AccountScopeConfigu', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Account Scope Configuration', 
    position: 1 , 
    targetElement: '_AccountScopeConfigu'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _AccountScopeConfigu,
  @UI.hidden: true
  max( ZTFI_IC_ACCT.LASTCHANGEDAT ) as LastChangedAtMax,
  @ObjectModel.text.association: '_ABAPTransportRequestText'
  @UI.identification: [ {
    position: 2 , 
    type: #WITH_INTENT_BASED_NAVIGATION, 
    semanticObjectAction: 'manage'
  } ]
  @Consumption.semanticObject: 'CustomizingTransport'
  cast( '' as SXCO_TRANSPORT) as TransportRequestID,
  _ABAPTransportRequestText
  
}
where I_Language.Language = $session.system_language
