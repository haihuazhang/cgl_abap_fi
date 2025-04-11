@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Repayment'
define view entity ZR_TFI002
  as select from ztfi002 as Repayment
  association        to parent ZR_TFI001 as _Interest             on  $projection.UUIDInterest = _Interest.UUID
  association [0..*] to ZR_SFI002T       as _RepaymentType1Text   on  $projection.RepaymentType1 = _RepaymentType1Text.value_low
  association [0..1] to I_JournalEntry   as _LenderJournalEntry   on  _LenderJournalEntry.CompanyCode        = $projection.Lender
                                                                  and _LenderJournalEntry.FiscalYear         = $projection.FiscalYear
                                                                  and _LenderJournalEntry.AccountingDocument = $projection.JournalEntryLender
  association [0..1] to I_JournalEntry   as _BorrowerJournalEntry on  _BorrowerJournalEntry.CompanyCode        = $projection.Borrower
                                                                  and _BorrowerJournalEntry.FiscalYear         = $projection.FiscalYear
                                                                  and _BorrowerJournalEntry.AccountingDocument = $projection.JournalEntryBorrower
{
  key uuid                             as UUID,
      uuid_interest                    as UUIDInterest,
      company_code                     as CompanyCode,
      fiscal_year                      as FiscalYear,
      //      accounting_document    as AccountingDocument,
      repayment_type                   as RepaymentType1,
      repayment_date                   as RepaymentDate,
      repayment_amount                 as RepaymentAmount,
      currency                         as Currency,
      posting_date                     as PostingDate,
      repayment_number                 as RepaymentNumber,
      house_bank_lender                as HouseBankLender,
      account_id_lender                as AccountIDLender,
      house_bank_borrower              as HouseBankBorrower,
      account_id_borrower              as AccountIDBorrower,
      cash_flow                        as CashFlowLender,
      cash_flow_borrower               as CashFlowBorrower,
      notes                            as Notes,
      journal_entry_lender             as JournalEntryLender,
      journal_entry_borrower           as JournalEntryBorrower,
      lender                           as Lender,
      borrower                         as Borrower,
      lender_company                   as LenderCompany,
      borrower_company                 as BorrowerCompany,
      _LenderJournalEntry.IsReversed   as JournalEntryLenderReversed,
      _BorrowerJournalEntry.IsReversed as JournalEntryBorrowerReversed,

      cast( case when _LenderJournalEntry.IsReversed = 'X' then  'Reversed'
            when journal_entry_lender <> '' and _LenderJournalEntry.IsReversed = '' then 'Posted'
      else '' end as abap.char( 10 ) ) as JELenderStatusText,
      //
      cast( case when _LenderJournalEntry.IsReversed = 'X' then  1
            when journal_entry_lender <> '' and _LenderJournalEntry.IsReversed = '' then 3
            else 0 end as abap.int1 )  as JELenderStatusCriticality,

      cast( case when _BorrowerJournalEntry.IsReversed = 'X' then  'Reversed'
            when journal_entry_borrower <> '' and _BorrowerJournalEntry.IsReversed = '' then 'Posted'
      else '' end as abap.char( 10 ) ) as JEBorrowerStatusText,
      //
      cast( case when _BorrowerJournalEntry.IsReversed = 'X' then  1
            when journal_entry_borrower <> '' and _BorrowerJournalEntry.IsReversed = '' then 3
            else 0 end as abap.int1 )  as JEBorrowerStatusCriticality,
      @Semantics.user.createdBy: true
      created_by                       as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                       as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by                  as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                  as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at            as LocalLastChangedAt,
      _Interest,
      _RepaymentType1Text,
      _LenderJournalEntry,
      _BorrowerJournalEntry
}
