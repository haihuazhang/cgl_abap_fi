@EndUserText.label: 'Loan Platform - Company Code Status Sing'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'LoanPlatformCompAll'
  }
}
define root view entity ZR_TFI010
  as select from I_Language
    left outer join ZTFI010 on 0 = 0
  association [0..*] to I_ABAPTransportRequestText as _I_ABAPTransportRequestText on $projection.TransportRequestID = _I_ABAPTransportRequestText.TransportRequestID
  composition [0..*] of ZI_LoanPlatformCompany as _LoanPlatformCompany
{
  @UI.facet: [ {
    id: 'ZI_LoanPlatformCompany', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Loan Platform - Company Code Status', 
    position: 1 , 
    targetElement: '_LoanPlatformCompany'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _LoanPlatformCompany,
  @UI.hidden: true
  max( ZTFI010.LAST_CHANGED_AT ) as LastChangedAtMax,
  @ObjectModel.text.association: '_I_ABAPTransportRequestText'
  @UI.identification: [ {
    position: 2 , 
    type: #WITH_INTENT_BASED_NAVIGATION, 
    semanticObjectAction: 'manage'
  } ]
  @Consumption.semanticObject: 'CustomizingTransport'
  cast( '' as SXCO_TRANSPORT) as TransportRequestID,
  _I_ABAPTransportRequestText
  
}
where I_Language.Language = $session.system_language
