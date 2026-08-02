WITH
joined_data AS (
   SELECT
      i.i_item_id,
      i.i_product_name,
      i.i_manager_id,
      i.i_size,
      ws.ws_ext_list_price,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_web_site_sk,
      web_site.web_name,
      cr.cr_return_amount,
      inventory.inv_quantity_on_hand,
      ws.ws_order_number
   FROM catalog_returns cr
   JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
   JOIN inventory
        ON inventory.inv_item_sk = i.i_item_sk
   JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
   JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
   WHERE i.i_size = 'large'
     AND i.i_manager_id = 23
     AND ws.ws_ext_list_price > 5000
     AND inventory.inv_quantity_on_hand < 100
),
agg AS (
   SELECT
      i_item_id,
      i_product_name,
      web_name,
      SUM(ws_net_paid) AS total_net_paid,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(DISTINCT ws_order_number) AS distinct_orders,
      AVG(ws_ext_list_price) AS avg_list_price,
      MAX(inv_quantity_on_hand) AS max_on_hand,
      MIN(inv_quantity_on_hand) AS min_on_hand
   FROM joined_data
   GROUP BY i_item_id, i_product_name, web_name
),
high_sales AS (
   SELECT i_item_id, total_net_paid, total_return_amount
   FROM agg
   WHERE total_net_paid > 10000
),
high_returns AS (
   SELECT i_item_id, total_net_paid, total_return_amount
   FROM agg
   WHERE total_return_amount > 5000
),
combined AS (
   SELECT DISTINCT i_item_id, total_net_paid, total_return_amount
   FROM (
     SELECT i_item_id, total_net_paid, total_return_amount FROM high_sales
     UNION ALL
     SELECT i_item_id, total_net_paid, total_return_amount FROM high_returns
   )
),
final_items AS (
   SELECT i_item_id
   FROM high_sales
   EXCEPT
   SELECT i_item_id
   FROM high_returns
)
SELECT
   f.i_item_id,
   a.i_product_name,
   a.web_name,
   a.total_net_paid,
   a.total_return_amount,
   a.distinct_orders,
   a.avg_list_price,
   a.max_on_hand,
   a.min_on_hand
FROM final_items f
JOIN agg a ON f.i_item_id = a.i_item_id
ORDER BY a.total_net_paid DESC
LIMIT 100
