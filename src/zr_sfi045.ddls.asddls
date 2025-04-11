@EndUserText.label: 'Parameter CDS of Sales Invoice - Send Email'
define abstract entity ZR_SFI045
  //  with parameters parameter_name : parameter_type
{
  @EndUserText.label: 'Recipients(separate with semicolon)'
  @UI.multiLineText: true
  Recipients : abap.string( 1000 );
}
