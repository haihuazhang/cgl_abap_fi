@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AcctgDocItem'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI036 as select from I_OperationalAcctgDocItem
{
    key CompanyCode,
    key AccountingDocument,
    key FiscalYear,
    GLAccount,
    Customer,
    PaymentReference,
    NetDueDate,
    HouseBankAccount,
    HouseBank,
    TransactionCurrency,
    @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
    max( AmountInTransactionCurrency )  as AmountInTransactionCurrency
}  where GLAccount like '11220%' and Customer not like 'E%'
group by CompanyCode , AccountingDocument , FiscalYear,GLAccount,Customer,PaymentReference,HouseBankAccount,HouseBank,NetDueDate,
    TransactionCurrency
