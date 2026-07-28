WITH recent_dates AS (
  SELECT d_date_sk
  FROM date_dim
  WHERE d_year = 2020
)
SELECT item_id,
       product_name,
       total_amount,
       source
FROM (
  SELECT i.i_item_id AS item_id,
         i.i_product_name AS product_name,
         SUM(cr.cr_return_amount) AS total_amount,
         'catalog_return' AS source
  FROM catalog_returns cr
  JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc = 'Customer Not Satisfied'
  GROUP BY i.i_item_id, i.i_product_name

  UNION ALL

  SELECT i.i_item_id AS item_id,
         i.i_product_name AS product_name,
         SUM(ss.ss_net_paid) AS total_amount,
         'store_sales' AS source
  FROM store_sales ss
  JOIN recent_dates rd ON ss.ss_sold_date_sk = rd.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE EXISTS (
        SELECT 1
        FROM store s
        WHERE s.s_store_sk = ss.ss_store_sk
          AND s.s_market_manager = 'James Irvin'
      )
  GROUP BY i.i_item_id, i.i_product_name
) AS combined
ORDER BY total_amount DESC
LIMIT 100
