@EndUserText.label: 'invoice head print'
@ObjectModel.query.implementedBy:'ABAP:ZZCL_INVOICE_PRINT'
define root custom entity ZR_SFI039
{
  

    key Companycode:bukrs;
    key AccountingDocument:abap.char(10);
    key FiscalYear:gjahr;
   InvoiceNumber :abap.char(30);
   CompanyName:abap.char(80);
   Customer:abap.char(10);
   IncomeType:abap.char(2);
   PostingDate:abap.dats;
   //TotalgrossAmount
   DocumentDate : abap.dats;
   ConstantSymbol : abap.char(10);
   DueDate: abap.dats;
   TaxFulfillmentDate:abap.dats;
   PaymentMethod:abap.char(30);
   InvoiceInstructions:abap.char(220);
   IssuerName: abap.char(40);
   IssuerEmail:abap.char(40);
   UnitPrice:abap.cuky;
   @Semantics.amount.currencyCode: 'UnitPrice'
   NetAmountSum:abap.curr( 13, 2 );
   @Semantics.amount.currencyCode: 'UnitPrice'
   TaxAmountSUM:abap.curr( 13, 2 );
   @Semantics.amount.currencyCode: 'UnitPrice'
   GrossAmountSum:abap.curr( 13, 2 );
   TaxRate:abap.char( 10 );
   TotalPageNum:abap.char( 5 );
   @ObjectModel.filter.enabled: false
   @ObjectModel.sort.enabled: false
   _sellerinfo:association[0..1] to ZR_SFI040 on $projection.Companycode = _sellerinfo.Companycode
                                              and $projection.AccountingDocument = _sellerinfo.AccountingDocument
                                              and $projection.FiscalYear = _sellerinfo.FiscalYear ;
   @ObjectModel.filter.enabled: false
   @ObjectModel.sort.enabled: false
   _buyerinfo:association[0..1] to ZR_SFI041 on $projection.Companycode = _buyerinfo.Companycode
                                             and $projection.AccountingDocument = _buyerinfo.AccountingDocument
                                             and $projection.FiscalYear = _buyerinfo.FiscalYear;
   @ObjectModel.filter.enabled: false
   @ObjectModel.sort.enabled: false
   _BankInformation:association[0..1] to ZR_SFI042 on $projection.Companycode = _BankInformation.Companycode 
                                                   and $projection.AccountingDocument = _BankInformation.AccountingDocument
                                                   and $projection.FiscalYear = _BankInformation.FiscalYear ;
   @ObjectModel.filter.enabled: false
   _InvoiceDetail:association to many ZR_SFI043 on $projection.Companycode = _InvoiceDetail.Companycode 
                                                   and $projection.AccountingDocument = _InvoiceDetail.AccountingDocument
                                                   and $projection.FiscalYear = _InvoiceDetail.FiscalYear ;                                        
 
}
