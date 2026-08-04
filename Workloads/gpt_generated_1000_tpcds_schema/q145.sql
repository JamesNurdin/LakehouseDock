WITH inv_no_ret AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       inv.inv_quantity_on_hand,
       CASE WHEN inv.inv_quantity_on_hand < 10 THEN 'Low Stock' ELSE 'Sufficient' END AS stock_status
   FROM inventory inv
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   WHERE inv.inv_quantity_on_hand > 0
     AND NOT EXISTS (
         SELECT 1
         FROM web_returns wr
         WHERE wr.wr_item_sk = i.i_item_sk
     )
),
ret_no_inv AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       wr.wr_return_quantity,
       CASE WHEN wr.wr_return_amt_inc_tax > 500 THEN 'High Return' ELSE 'Normal Return' END AS return_category
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE wr.wr_return_amt_inc_tax > 0
     AND NOT EXISTS (
         SELECT 1
         FROM inventory inv
         WHERE inv.inv_item_sk = i.i_item_sk
     )
)
SELECT
   i_item_sk,
   i_product_name,
   metric,
   category
FROM (
   SELECT
       i_item_sk,
       i_product_name,
       inv_quantity_on_hand AS metric,
       stock_status AS category
   FROM inv_no_ret
   UNION
   SELECT
       i_item_sk,
       i_product_name,
       wr_return_quantity AS metric,
       return_category AS category
   FROM ret_no_inv
) u
ORDER BY metric DESC
LIMIT 100
