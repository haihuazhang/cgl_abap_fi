@EndUserText.label: 'Copy Account Scope Configuration'
define abstract entity ZD_CopyAccountScopeConfiguP
{
  @EndUserText.label: 'New Item'
  @UI.defaultValue: #( 'ELEMENT_OF_REFERENCED_ENTITY: Item' )
  Item : ZZEFI044;
  @EndUserText.label: 'New TYPE'
  @UI.defaultValue: #( 'ELEMENT_OF_REFERENCED_ENTITY: Type' )
  Type : ZETYPE;
  @EndUserText.label: 'New Sign'
  @UI.defaultValue: #( 'ELEMENT_OF_REFERENCED_ENTITY: Sign' )
  Sign : DDSIGN;
  @EndUserText.label: 'New Zoption'
  @UI.defaultValue: #( 'ELEMENT_OF_REFERENCED_ENTITY: Zoption' )
  Zoption : DDOPTION;
  @EndUserText.label: 'New G/L Account'
  @UI.defaultValue: #( 'ELEMENT_OF_REFERENCED_ENTITY: Accountfrom' )
  Accountfrom : SAKNR;
  
}
