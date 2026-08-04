WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        sr.sr_store_credit,
        sr.sr_reversed_charge
    FROM store_returns sr
    WHERE sr.sr_return_amt_inc_tax > 0
      AND sr.sr_reversed_charge < 500
      AND regexp_like(CAST(sr.sr_store_credit AS VARCHAR), '^\\d+\\.\\d{2}$')
)
SELECT
    COALESCE(d.d_year, -1) AS year,
    COALESCE(d.d_month_seq, -1) AS month_seq,
    COALESCE(t.t_shift, 'unknown') AS shift,
    SUM(fr.sr_net_loss) AS total_net_loss,
    SUM(CASE WHEN d.d_holiday = 'Y' THEN fr.sr_net_loss ELSE 0 END) AS holiday_net_loss,
    COUNT(DISTINCT fr.sr_item_sk) AS distinct_items,
    (SELECT AVG(s2.sr_return_amt_inc_tax) FROM store_returns s2) AS avg_return_amt_inc_tax,
    concat(CAST(COALESCE(d.d_year, 0) AS VARCHAR), '-', t.t_shift) AS year_shift_key,
    substring(d.d_day_name FROM 1 FOR 3) AS day_prefix
FROM filtered_returns fr
FULL OUTER JOIN date_dim d
    ON fr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN time_dim t
    ON fr.sr_return_time_sk = t.t_time_sk
WHERE fr.sr_item_sk NOT IN (
        SELECT sr2.sr_item_sk FROM store_returns sr2 WHERE sr2.sr_return_amt_inc_tax > 1000
    )
  AND d.d_day_name IS NOT NULL
  AND lower(d.d_day_name) LIKE '%day%'
  AND regexp_like(d.d_holiday, '^[NY]$')
GROUP BY
    COALESCE(d.d_year, -1),
    COALESCE(d.d_month_seq, -1),
    COALESCE(t.t_shift, 'unknown'),
    concat(CAST(COALESCE(d.d_year, 0) AS VARCHAR), '-', t.t_shift),
    substring(d.d_day_name FROM 1 FOR 3)
ORDER BY total_net_loss DESC
LIMIT 100
