@EndUserText.label: 'Invoice header'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_SFI038
  provider contract transactional_query
  as projection on ZR_SFI038
{
  key CompanyCode,
  key FiscalYear,
  key AccountingDocument,
      CompanyName,
      AccountingDocumentType,
      PostingDate,
      Documentdate,
      
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI054', element: 'value_low' }, useForValidation: true }]
      @ObjectModel.text.element: [ 'DocumentStatusText' ]
      DocumentStatus,
      _DocumentStatus.text as DocumentStatusText : localized,
      IncomeDescribtion,
      TransactionCurrency,
      @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
      TotalGrossAmount,
      Customer,
      InvoiceNo,

      InvoiceDate,
      TaxFulfillmentDate,
      FinalRecipient,
      OrderNumber,
      OrderDate,
      DueDate,

      //Buyer Information
      CustomerCode,
      CustomerName,
      CustomerCountry,
      CustomerCity,
      CustomerPostalCode,
      CustomerHouseNumber,
      CustomerStreetName,
      BusinessIdentificationNumber,
      TaxIdentificationNumber,
      VatIdentificationNumber,

      //Seller Information
      CompanyCountry,
      CompanyCity,
      CompanyPostalCode,
      CompanyHouseNumber,
      CompanyStreetName,
      BusinessIdentificationNumber1,
      TaxIdentificationNumber1,
      VATIdentificationNumber1,

      PaymentMethod,
      @Consumption.valueHelpDefinition: [{
                                            entity: { name: 'I_Bank_2', element: 'BankName' },
                                            useForValidation: true,
                                            additionalBinding: [{
                                                     element: 'BankInternalID',
                                                     localElement: 'BankKey'},
                                                     {
                                                     element: 'SWIFTCode',
                                                     localElement: 'Swift',
                                                     usage: #RESULT}
                                            ]
                                        }]
      BankName,
      @Consumption.valueHelpDefinition: [{
                                      entity: { name: 'I_HouseBank', element: 'HouseBank' },
                                      useForValidation: true,
                                      additionalBinding: [{
                                               element: 'CompanyCode',
                                               localElement: 'CompanyCode'}
                                      ]
                                  }]
      HouseBank,
      @Consumption.valueHelpDefinition: [{
                                            entity: { name: 'I_Bank_2', element: 'SWIFTCode' },
                                            useForValidation: true,
                                            additionalBinding: [{
                                                     element: 'BankInternalID',
                                                     localElement: 'BankKey'}
                                            ]
                                        }]
      Swift,
      @Consumption.valueHelpDefinition: [{
                                              entity: { name: 'I_HouseBankAccountLinkage', element: 'IBAN' },
                                              useForValidation: true,
                                              additionalBinding: [{
                                                       element: 'CompanyCode',
                                                       localElement: 'CompanyCode'},
                                                       {
                                                       element: 'HouseBank',
                                                       localElement: 'HouseBank'},
                                                       {element: 'HouseBankAccount',
                                                       localElement: 'AccountId'}
                                              ]
                                          }]
      Iban,
      @Consumption.valueHelpDefinition: [{
                                            entity: { name: 'I_HouseBankAccountLinkage', element: 'BankInternalID' },
                                            useForValidation: true,
                                            additionalBinding: [
                                                     {
                                                     element: 'CompanyCode',
                                                     localElement: 'CompanyCode'},
                                                     {
                                                     element: 'HouseBank',
                                                     localElement: 'HouseBank'},
                                                     {element: 'HouseBankAccount',
                                                     localElement: 'AccountId'},
                                                     {
                                                        element: 'BankName',
                                                     localElement: 'BankName'
                                                     } 
                                            ]
                                        }]
      BankKey,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_HouseBankAccountLinkage', element: 'HouseBankAccount' },
                                     useForValidation: true,
                                     additionalBinding: [{
                                               element: 'HouseBank',
                                               localElement: 'HouseBank'},
                                               {
                                               element: 'CompanyCode',
                                               localConstant: 'CompanyCode'  }
      ]}]
      AccountId,
      @Consumption.valueHelpDefinition: [{
                                            entity: { name: 'I_HouseBankAccountLinkage', element: 'BankAccountNumber' },
                                            useForValidation: true,
                                            additionalBinding: [{
                                                     element: 'CompanyCode',
                                                     localElement: 'CompanyCode'},
                                                     {
                                                     element: 'HouseBank',
                                                     localElement: 'HouseBank'},
                                                     {element: 'HouseBankAccount',
                                                     localElement: 'AccountId'},
                                                     {
                                                        element: 'BankInternalID',
                                                     localElement: 'BankKey'
                                                     },
                                                     {
                                                        element: 'BankName',
                                                     localElement: 'BankName'
                                                     }
                                            ]
                                        }]
      BankKey_SK,                                  
      BankAccount,
      InvoiceNumber,
      ConstantSymbol,
      InvoiceInstructions,
      IssuerEmail,
      IssuerName,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SFI046', element: 'value_low' }, useForValidation: true }]
      @ObjectModel.text.element: [ 'InvoiceStatusText' ]
      Status,
      _InvoiceStatusText.text as InvoiceStatusText : localized,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      _Item,
      _InvoiceStatusText,
      _DocumentStatus 
}
