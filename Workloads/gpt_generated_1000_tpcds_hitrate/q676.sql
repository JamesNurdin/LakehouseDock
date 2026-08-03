WITH RECURSIVE date_range (d_date_sk, d_date) AS (
   SELECT d_date_sk, d_date
   FROM date_dim
   WHERE d_date = DATE '2001-01-01'
   UNION ALL
   SELECT d.d_date_sk, d.d_date
   FROM date_dim d
   JOIN date_range dr ON d.d_date = dr.d_date + INTERVAL '1' DAY
   WHERE d.d_date <= DATE '2001-01-31'
)
SELECT profit_flag,
       item_id,
       net_amount
FROM (
   SELECT
       CASE WHEN cs.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
       i.i_item_id AS item_id,
       cs.cs_net_paid AS net_amount
   FROM catalog_sales cs
   JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE EXISTS (
         SELECT 1
         FROM catalog_returns cr
         WHERE cr.cr_order_number = cs.cs_order_number
   )
) AS sales_set
INTERSECT
SELECT profit_flag,
       item_id,
       net_amount
FROM (
   SELECT
       CASE WHEN cr.cr_return_amount > 0 THEN 'RETURN' ELSE 'NO_RETURN' END AS profit_flag,
       i.i_item_id AS item_id,
       cr.cr_return_amount AS net_amount
   FROM catalog_returns cr
   JOIN date_range dr ON cr.cr_returned_date_sk = dr.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE EXISTS (
         SELECT 1
         FROM catalog_sales cs2
         WHERE cs2.cs_order_number = cr.cr_order_number
   )
) AS return_set
ORDER BY profit_flag DESC, net_amount DESC
LIMIT 100
