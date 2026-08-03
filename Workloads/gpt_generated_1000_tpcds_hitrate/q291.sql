/*
Goal: Identify the top 100 items in the year 2001 by net amount, combining net sales from catalog_sales and net returns (as negative amounts) from catalog_returns. Only include rows where the item was in stock on the transaction date (checked via a correlated EXISTS on inventory).
*/
WITH sales_cte AS (
   SELECT
       i.i_item_id AS item_id,
       d.d_year   AS year,
       SUM(cs.cs_ext_sales_price) AS amount
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND EXISTS (
           SELECT 1
           FROM inventory inv
           WHERE inv.inv_item_sk = cs.cs_item_sk
             AND inv.inv_date_sk = cs.cs_sold_date_sk
             AND inv.inv_quantity_on_hand > 0
       )
   GROUP BY i.i_item_id, d.d_year
),
returns_cte AS (
   SELECT
       i.i_item_id AS item_id,
       d.d_year   AS year,
       SUM(cr.cr_return_amount) * -1 AS amount
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND EXISTS (
           SELECT 1
           FROM inventory inv
           WHERE inv.inv_item_sk = cr.cr_item_sk
             AND inv.inv_date_sk = cr.cr_returned_date_sk
             AND inv.inv_quantity_on_hand > 0
       )
   GROUP BY i.i_item_id, d.d_year
)
SELECT item_id, year, amount
FROM sales_cte
UNION ALL
SELECT item_id, year, amount
FROM returns_cte
ORDER BY amount DESC
LIMIT 100
