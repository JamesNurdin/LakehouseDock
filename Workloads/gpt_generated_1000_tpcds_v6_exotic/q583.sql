WITH high_income_returns AS (
   SELECT
       CAST(s.s_store_id AS varchar) AS entity_id,
       d.d_date AS return_date,
       sr.sr_net_loss AS net_loss,
       ib.ib_lower_bound AS income_lower,
       'store' AS source_type
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE d.d_current_quarter = 'Y'
     AND ib.ib_lower_bound >= 50000
     AND d.d_date >= DATE '2023-01-01'
   UNION ALL
   SELECT
       CAST(cr.cr_refunded_customer_sk AS varchar) AS entity_id,
       d.d_date AS return_date,
       cr.cr_net_loss AS net_loss,
       ib.ib_lower_bound AS income_lower,
       'catalog' AS source_type
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE d.d_current_week = 'N'
     AND cr.cr_return_amount > 1000
     AND ib.ib_lower_bound >= 50000
     AND d.d_date >= DATE '2023-01-01'
)
SELECT
    entity_id,
    return_date,
    net_loss,
    income_lower,
    source_type
FROM high_income_returns
ORDER BY net_loss DESC
LIMIT 100
