@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AcctgDocItem'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
/*+[hideWarning] { "IDS" : [ "KEY_CHECK" } */
define view entity ZR_SFI036_2 as select from ztfi006 as _ztfi006
{
    key rpad(_ztfi006.glaccount, 10, '0') as glaccount1,
    key rpad(_ztfi006.glaccount, 10, '9') as glaccount2,
        incomedescribtion
}
