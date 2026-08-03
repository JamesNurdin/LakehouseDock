WITH recent_dates AS (
   SELECT d_date_sk,
          d_date
   FROM date_dim
   WHERE d_year = 2001
),
combined_returns AS (
   SELECT
       sr.sr_returned_date_sk            AS return_date_sk,
       d.d_date                          AS return_date,
       i.i_item_sk                       AS item_sk,
       i.i_item_id                       AS i_item_id,
       i.i_product_name                  AS i_product_name,
       sr.sr_return_quantity             AS return_quantity,
       sr.sr_return_amt                  AS return_amount,
       LAG(sr.sr_return_amt) OVER (PARTITION BY sr.sr_item_sk ORDER BY d.d_date)            AS prev_return_amount,
       SUM(sr.sr_return_amt) OVER (PARTITION BY i.i_item_id ORDER BY d.d_date
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_amount,
       'store'                           AS source
   FROM store_returns sr
   JOIN recent_dates d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE EXISTS (
       SELECT 1
       FROM reason r
       WHERE r.r_reason_sk = sr.sr_reason_sk
         AND r.r_reason_desc LIKE '%defect%'
   )
   UNION ALL
   SELECT
       cr.cr_returned_date_sk            AS return_date_sk,
       d.d_date                          AS return_date,
       i.i_item_sk                       AS item_sk,
       i.i_item_id                       AS i_item_id,
       i.i_product_name                  AS i_product_name,
       cr.cr_return_quantity             AS return_quantity,
       cr.cr_return_amount               AS return_amount,
       LAG(cr.cr_return_amount) OVER (PARTITION BY cr.cr_item_sk ORDER BY d.d_date)            AS prev_return_amount,
       SUM(cr.cr_return_amount) OVER (PARTITION BY i.i_item_id ORDER BY d.d_date
                                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_amount,
       'catalog'                         AS source
   FROM catalog_returns cr
   JOIN recent_dates d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE EXISTS (
       SELECT 1
       FROM reason r
       WHERE r.r_reason_sk = cr.cr_reason_sk
         AND r.r_reason_desc LIKE '%defect%'
   )
)
SELECT
   cr.return_date,
   cr.i_item_id,
   cr.i_product_name,
   cr.return_quantity,
   cr.return_amount,
   cr.prev_return_amount,
   cr.running_total_amount,
   p.p_promo_name,
   ib.ib_lower_bound,
   ib.ib_upper_bound
FROM combined_returns cr
FULL OUTER JOIN promotion p
     ON cr.item_sk = p.p_item_sk
CROSS JOIN income_band ib
WHERE ib.ib_lower_bound >= 30000
  AND ib.ib_upper_bound <= 80000
ORDER BY cr.return_date DESC,
         cr.i_item_id
LIMIT 100
