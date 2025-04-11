@ObjectModel.query.implementedBy:'ABAP:ZZCL_FI_002'
@Metadata.allowExtensions: true
@EndUserText.label: 'PrincipalInterest_Summary'
define custom entity ZR_SFI025
{
    key CompanyCode : abap.char(6);
    //Lender as Lender,
    //Borrower as Borrower,
    key REPORTDATE : abap.dats;
    CompanyName :abap.char(25);
    CurrencyEUR : abap.cuky;
    @Semantics.amount.currencyCode: 'CurrencyEUR'
    PrincipalBalanceEUR_lender : abap.curr( 13, 2 );
    @Semantics.amount.currencyCode: 'CurrencyEUR'
    InterestBalanceEUR_lender : abap.curr( 13, 2 );
    @Semantics.amount.currencyCode: 'CurrencyEUR'
    PrincipalBalanceEUR_borrower : abap.curr( 13, 2 );
    @Semantics.amount.currencyCode: 'CurrencyEUR'
    InterestBalanceEUR_borrower : abap.curr( 13, 2 );
    @Semantics.amount.currencyCode: 'CurrencyEUR'
    PrincipalBalanceEUR_sum : abap.curr( 13, 2 );
    @Semantics.amount.currencyCode: 'CurrencyEUR'
    InterestBalanceEUR_sum : abap.curr( 13, 2 );
    @ObjectModel.filter.enabled: false
    _ITEM : association to many ZR_SFI024 on $projection.REPORTDATE = _ITEM.REPORTDATE
                                    and $projection.CompanyCode = _ITEM.CompanyCode;
                                     
     
}
