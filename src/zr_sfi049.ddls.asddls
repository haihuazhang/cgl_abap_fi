@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Dropdown List Value help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.supportedCapabilities: [ #CDS_MODELING_ASSOCIATION_TARGET, #CDS_MODELING_DATA_SOURCE ]
@ObjectModel.dataCategory: #VALUE_HELP
@Analytics.dataCategory: #DIMENSION
define view entity ZR_SFI049
//  with parameters
  
//    p_domain_name : abp_element_name
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE( p_domain_name: 'ZZDSING' )
  association [0..*] to ZR_SFI049T as _Text on  $projection.value_low    = _Text.value_low
//                                            and $projection.value_position = _Text.value_position
{
       //    key ,

       @ObjectModel.text.association: '_Text'
  key  value_low,
       @UI.hidden: true
       domain_name,
       @UI.hidden: true
       value_position,
       //    value_high,
       _Text
}
