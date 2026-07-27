WITH ss AS (
   SELECT
       ss.ss_item_sk,
       SUM(ss.ss_net_profit) AS sum_store_profit,
       SUM(ss.ss_quantity) AS sum_store_qty
   FROM store_sales ss
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE t.t_hour BETWEEN 9 AND 17
     AND i.i_units = 'Each'
     AND cd.cd_gender = 'M'
   GROUP BY ss.ss_item_sk
),
ws AS (
   SELECT
       ws.ws_item_sk,
       SUM(ws.ws_net_profit) AS sum_web_profit,
       SUM(ws.ws_quantity) AS sum_web_qty
   FROM web_sales ws
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE t.t_hour BETWEEN 9 AND 17
     AND cd.cd_marital_status = 'S'
   GROUP BY ws.ws_item_sk
),
cr AS (
   SELECT
       cr.cr_item_sk,
       SUM(cr.cr_net_loss) AS sum_return_loss,
       COUNT(*) AS cnt_returns
   FROM catalog_returns cr
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE t.t_hour BETWEEN 9 AND 17
     AND cr.cr_return_quantity > 0
   GROUP BY cr.cr_item_sk
),
inv AS (
   SELECT
       inv.inv_item_sk,
       SUM(inv.inv_quantity_on_hand) AS total_on_hand,
       COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
   FROM inventory inv
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE i.i_color = 'Red'
   GROUP BY inv.inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    COALESCE(ss.sum_store_profit, 0) + COALESCE(ws.sum_web_profit, 0) AS total_profit,
    COALESCE(cr.sum_return_loss, 0) AS total_return_loss,
    COALESCE(inv.total_on_hand, 0) AS inventory_on_hand,
    CASE
        WHEN COALESCE(ss.sum_store_profit, 0) + COALESCE(ws.sum_web_profit, 0) > 10000 THEN 'High'
        WHEN COALESCE(ss.sum_store_profit, 0) + COALESCE(ws.sum_web_profit, 0) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(ss.sum_store_profit, 0) + COALESCE(ws.sum_web_profit, 0)) DESC) AS profit_rank
FROM item i
LEFT JOIN ss ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN cr ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN inv ON i.i_item_sk = inv.inv_item_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws2
    JOIN web_page wp ON ws2.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws2.ws_item_sk = i.i_item_sk
      AND wp.wp_type = 'product'
)
  AND i.i_current_price BETWEEN 10 AND 100
  AND i.i_brand_id IN (1, 2, 3)
ORDER BY total_profit DESC
LIMIT 100
