@EndUserText.label: 'Invoice Detail-print'
@ObjectModel.query.implementedBy:'ABAP:ZZCL_INVOICE_PRINT'
define custom entity ZR_SFI043
{
    key Companycode:bukrs;
    key AccountingDocument:abap.char(10);
    key FiscalYear:gjahr;
    key  AccountingDocumentItem:buzei;
    //key InvoicNumber:abap.char(10);
    //key ItemNo:abap.char(5);
      Describtion:abap.char(100);
      TransactionCurrency:abap.cuky;
      unitQuality:abap.unit;
      @Semantics.quantity.unitOfMeasure: 'unitQuality'
      Quality:bpmng;
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      UnitPrice:wrbtr;
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      NetAmount:wrbtr;
      Taxrate:abap.char( 10 );
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      TaxAmount:wrbtr;
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      GrossAmount:wrbtr;
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      TotalNetAmount:wrbtr;
}
