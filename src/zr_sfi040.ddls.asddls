@EndUserText.label: 'Seller Information'
@ObjectModel.query.implementedBy:'ABAP:ZZCL_INVOICE_PRINT'
define custom entity ZR_SFI040
{
    key Companycode:bukrs;
    key AccountingDocument:abap.char(10);
    key FiscalYear:gjahr;
      CompanyName:abap.char(80);
      CompanyCountry:abap.char(50);
      CompanyCity:abap.char(25);
      CompanyPostalCode:abap.char(10);
      CompanyHouseNumber:abap.char(10);
      CompanyStreetName:abap.char(60);
      CompanyStreetHouse:abap.char(70);
      CompanyPostalCity:abap.char(35);
      BusinessIdentificationNumber1:abap.char(10);
      TaxIdentificationNumber1:abap.char(10);
      VATIdentificationNumber1:abap.char(60);
}
