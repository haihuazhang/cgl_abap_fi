@EndUserText.label: 'Copy   Maintain Tax Code'
define abstract entity ZD_CopyMaintainTaxCodeP
{
  @EndUserText.label: 'New Tax Code'
  @UI.defaultValue: #( 'ELEMENT_OF_REFERENCED_ENTITY: Taxcode' )
  Taxcode : MWSKZ;
  @EndUserText.label: 'New Country/Reg.'
  @UI.defaultValue: #( 'ELEMENT_OF_REFERENCED_ENTITY: Taxcounrty' )
  Taxcounrty : LAND1;
  
}
