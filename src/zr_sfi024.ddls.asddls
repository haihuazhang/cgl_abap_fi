@ObjectModel.query.implementedBy:'ABAP:ZZCL_FI_002'
@Metadata.allowExtensions: true
@EndUserText.label: 'PrincipalInterest_Detail'
define custom entity ZR_SFI024   
{
    //key UUID : sysuuid_x16;
    key CompanyCode : abap.char( 6 );
    //Lender as Lender,
    //Borrower as Borrower,
    key Counterparty : abap.char( 6 );
    key REPORTDATE : abap.dats;
    CompanyName:abap.char(25);
    CounterpartyName:abap.char(25);
    COM_COU : abap.char( 12 );
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
    Navigation : abap.char(10);
    //_items: association to many ZR_SFI030 
    //   on $projection.REPORTDATE = _items.REPORTDATE
    //  and $projection.COM_COU = _items.com_cou;

}
