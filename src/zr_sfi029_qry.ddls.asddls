@AccessControl.authorizationCheck: #NOT_ALLOWED
@EndUserText.label: 'Analytics Cube 2 of Loan Platform - By Date'
define transient view entity ZR_SFI029_Qry
  provider contract ANALYTICAL_QUERY
  with parameters
    P_DATE : DATUM
  as projection on ZR_SFI029
  (
    P_DATE : $parameters.P_DATE
  )
{
  @AnalyticsDetails.query: {
    axis: #ROWS, 
    totals: #SHOW
  }
  CONTRACTTYPE,
  @AnalyticsDetails.query: {
    axis: #FREE, 
    totals: #SHOW
  }
  CONTRACTCODE,
  @AnalyticsDetails.query: {
    axis: #COLUMNS, 
    totals: #SHOW
  }
  EXCHANGERATE
  
}
