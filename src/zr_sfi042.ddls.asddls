@EndUserText.label: 'Bank Information-print'
@ObjectModel.query.implementedBy:'ABAP:ZZCL_INVOICE_PRINT'
define custom entity ZR_SFI042
{
    key Companycode:bukrs;
    key AccountingDocument:abap.char(10);
    key FiscalYear:gjahr;
        BankName:abap.char(60);
        HouseBank:abap.char(5);
        Swift:abap.char(11);
        BankKey:abap.char(15);
        Iban:abap.char(34);
        AccountId:abap.char(5);
        BankAccount:abap.char(18);
        BankKey_SK:abap.char(4);
}
