@EndUserText.label: 'CGL Group Intro-co Loan List'
@ObjectModel.query.implementedBy:'ABAP:ZZCL_R_SFI001'
@Metadata.allowExtensions: true
define custom entity ZR_SFI023
{
  key uuid              : sysuuid_x16;
  key CompanyCode       : bukrs;
      ReportingDate     : abap.dats;
      Counterparty      : abap.char( 30 );
      Currency          : waers;
      @Semantics.amount.currencyCode: 'Currency'
      PrincipalLender   : abap.curr( 15, 2 );
      @Semantics.amount.currencyCode: 'Currency'
      InterestLender    : abap.curr( 15, 2 );
      @Semantics.amount.currencyCode: 'Currency'
      PrincipalBorrower : abap.curr( 15, 2 );
      @Semantics.amount.currencyCode: 'Currency'
      InterestBorrower  : abap.curr( 15, 2 );
      @Semantics.amount.currencyCode: 'Currency'
      PrincipalTotal    : abap.curr( 15, 2 );
      @Semantics.amount.currencyCode: 'Currency'
      InterestTotal     : abap.curr( 15, 2 );

}
