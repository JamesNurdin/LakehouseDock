WITH sr AS (
   SELECT
       d.d_year AS year,
       i.i_category AS category,
       SUM(sr.sr_return_amt_inc_tax) AS metric
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year BETWEEN 1998 AND 2000
     AND i.i_category IN ('Electronics', 'Furniture')
     AND EXISTS (
         SELECT 1
         FROM inventory inv
         JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
         WHERE inv.inv_item_sk = i.i_item_sk
           AND d2.d_year = d.d_year
           AND inv.inv_quantity_on_hand > 0
     )
   GROUP BY d.d_year, i.i_category
),
inv AS (
   SELECT
       d.d_year AS year,
       i.i_category AS category,
       SUM(inv.inv_quantity_on_hand) AS metric
   FROM inventory inv
   JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year BETWEEN 1998 AND 2000
     AND w.w_state = 'CA'
     AND i.i_category IN ('Electronics', 'Furniture')
   GROUP BY d.d_year, i.i_category
)
SELECT year, category, metric
FROM sr
UNION ALL
SELECT year, category, metric
FROM inv
ORDER BY year DESC, metric DESC
LIMIT 100
