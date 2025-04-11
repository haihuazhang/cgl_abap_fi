@EndUserText.label: '  Maintain Tax Code Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'MaintainTaxCodeAll'
  }
}
define root view entity ZI_MaintainTaxCode_S
  as select from I_Language
    left outer join ZTFI011 on 0 = 0
  association [0..*] to I_ABAPTransportRequestText as _ABAPTransportRequestText on $projection.TransportRequestID = _ABAPTransportRequestText.TransportRequestID
  composition [0..*] of ZI_MaintainTaxCode as _MaintainTaxCode
{
  @UI.facet: [ {
    id: 'ZI_MaintainTaxCode', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: '  Maintain Tax Code', 
    position: 1 , 
    targetElement: '_MaintainTaxCode'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _MaintainTaxCode,
  @UI.hidden: true
  max( ZTFI011.LASTCHANGEDAT ) as LastChangedAtMax,
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
