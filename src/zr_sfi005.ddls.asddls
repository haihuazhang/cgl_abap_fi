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
define view entity ZR_SFI005
//  with parameters
  
//    p_domain_name : abp_element_name
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE( p_domain_name: 'ZZDFI033' )
  association [0..*] to ZR_SFI005T as _Text on  $projection.domain_name    = _Text.domain_name
                                            and $projection.value_position = _Text.value_position
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
