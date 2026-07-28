WITH avg_electronics_price AS (
   SELECT AVG(i_current_price) AS avg_price
   FROM item
   WHERE i_category = 'Electronics'
)
SELECT
  d.d_year AS return_year,
  d.d_moy  AS return_month,
  SUM(cr.cr_net_loss) AS total_net_loss,
  COUNT(*) AS return_cnt,
  'catalog' AS channel
FROM catalog_returns cr
JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs         ON cr.cr_order_number = cs.cs_order_number
JOIN customer c               ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i                   ON cr.cr_item_sk = i.i_item_sk
CROSS JOIN avg_electronics_price ae
WHERE ib.ib_lower_bound >= 60000
  AND i.i_current_price > ae.avg_price
GROUP BY d.d_year, d.d_moy

UNION ALL

SELECT
  d.d_year AS return_year,
  d.d_moy  AS return_month,
  SUM(sr.sr_net_loss) AS total_net_loss,
  COUNT(*) AS return_cnt,
  'store' AS channel
FROM store_returns sr
JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
JOIN store s                  ON sr.sr_store_sk = s.s_store_sk
JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i                   ON sr.sr_item_sk = i.i_item_sk
WHERE ib.ib_lower_bound >= 60000
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
          AND cs2.cs_sold_date_sk = d.d_date_sk
          AND cs2.cs_quantity > 0
      )
GROUP BY d.d_year, d.d_moy

ORDER BY return_year, return_month, channel
