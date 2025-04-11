@EndUserText.label: 'CGL Group Intro-co Loan Summary'
@ObjectModel.query.implementedBy:'ABAP:ZZCL_R_SFI001'
@Metadata.allowExtensions: true
define custom entity ZR_SFI017
{
  key ReportingDate     : abap.dats;
  key CompanyCode       : bukrs;
      Num               : abap.int4;
      Currency          : waers;
      @Semantics.amount.currencyCode: 'Currency'
      PrincipalLender   : abap.curr( 15, 2 );
      @Semantics.amount.currencyCode: 'Currency'
      InterestLender    : abap.curr( 15, 2 );
      @Semantics.amount.currencyCode: 'Currency'
      PrincipalBorrower : abap.curr( 15, 2 );
      @Semantics.amount.currencyCode: 'Currency'
      InterestBorrower  : abap.curr( 15, 2 );
      @ObjectModel.filter.enabled: false
      _Item             : association to many ZR_SFI023 on  $projection.ReportingDate = _Item.ReportingDate
                                                        and $projection.CompanyCode   = _Item.CompanyCode;
}
