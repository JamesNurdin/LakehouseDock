WITH web_agg AS (
   SELECT
       ws.ws_item_sk AS item_sk,
       SUM(ws.ws_ext_sales_price) AS total_web_sales,
       SUM(ws.ws_quantity) AS total_quantity,
       MAX(d.d_year) AS last_year
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Furniture'
   GROUP BY ws.ws_item_sk
),
store_agg AS (
   SELECT
       sr.sr_item_sk AS item_sk,
       SUM(sr.sr_net_loss) AS total_store_loss,
       SUM(sr.sr_return_quantity) AS total_return_qty,
       MAX(d.d_year) AS last_year
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Furniture'
   GROUP BY sr.sr_item_sk
),
intersect_items AS (
   SELECT item_sk FROM web_agg
   INTERSECT
   SELECT item_sk FROM store_agg
),
final_union AS (
   SELECT
       i.i_item_id AS item_id,
       i.i_product_name AS product_name,
       wa.total_web_sales AS metric,
       'Web' AS source
   FROM web_agg wa
   JOIN item i ON wa.item_sk = i.i_item_sk
   WHERE wa.item_sk IN (SELECT item_sk FROM intersect_items)
     AND NOT EXISTS (
         SELECT 1 FROM promotion p
         WHERE p.p_item_sk = i.i_item_sk
           AND p.p_start_date_sk = (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
     )
   UNION
   SELECT
       i.i_item_id AS item_id,
       i.i_product_name AS product_name,
       sa.total_store_loss AS metric,
       'Store' AS source
   FROM store_agg sa
   JOIN item i ON sa.item_sk = i.i_item_sk
   WHERE sa.item_sk IN (SELECT item_sk FROM intersect_items)
     AND NOT EXISTS (
         SELECT 1 FROM promotion p
         WHERE p.p_item_sk = i.i_item_sk
           AND p.p_start_date_sk = (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
     )
)
SELECT
    item_id,
    product_name,
    metric,
    source
FROM final_union
ORDER BY metric DESC
OFFSET 0
LIMIT 100
