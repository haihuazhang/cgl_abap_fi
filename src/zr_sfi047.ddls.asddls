@ObjectModel.query.implementedBy:'ABAP:ZZCL_FI_010'
@Metadata.allowExtensions: true
@EndUserText.label: 'Internal reconciliation report'
define custom entity ZR_SFI047   
{
  key CompanyCode:abap.char( 4 );
  key BusinessPartner:abap.char( 5 );
  CompanyName:abap.char(25);
  BusinessPartnerName:abap.char(25);
  TransactionCurrency : abap.cuky;
  @Semantics.amount.currencyCode: 'TransactionCurrency'
  A_B_AR_T:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'TransactionCurrency'
  B_A_AP_T:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'TransactionCurrency'
  Difference1_T:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'TransactionCurrency'
  A_B_AP_T:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'TransactionCurrency'
  B_A_AR_T:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'TransactionCurrency'
  Difference2_T:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'TransactionCurrency'
  TotalDifference_T:abap.curr( 13, 2 );
  GlobalCurrency : abap.cuky;
  @Semantics.amount.currencyCode: 'GlobalCurrency'
  A_B_AR_G:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'GlobalCurrency'
  B_A_AP_G:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'GlobalCurrency'
  Difference1_G:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'GlobalCurrency'
  A_B_AP_G:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'GlobalCurrency'
  B_A_AR_G:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'GlobalCurrency'
  Difference2_G:abap.curr( 13, 2 );
  @Semantics.amount.currencyCode: 'GlobalCurrency'
  TotalDifference_G:abap.curr( 13, 2 );
}
