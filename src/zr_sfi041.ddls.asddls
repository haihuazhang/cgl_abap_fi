@EndUserText.label: 'Buyer Information'
@ObjectModel.query.implementedBy:'ABAP:ZZCL_INVOICE_PRINT'
define custom entity ZR_SFI041
{
    key Companycode:bukrs;
    key AccountingDocument:abap.char(10);
    key FiscalYear:gjahr;
      CustomerCode:abap.char(10);
      CustomerName:abap.char(80);
      CustomerCountry:abap.char(50);
      CustomerCity:abap.char(20);
      CustomerPostalCode:abap.char(10);
      CustomerHouseNumber:abap.char(10);
      CustomerStreetName:abap.char(60);
      CustomerStreetHouse:abap.char(70);
      CustomerPostalCity:abap.char(30);
      BusinessIdentificationNumber:abap.char(10);
      TaxIdentificationNumber:abap.char(10);
      VATIdentificationNumber:abap.char(10);
}
