WITH cat_sales AS (
    SELECT i.i_item_id,
           cs.cs_net_paid AS sales_amount
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_brand = (SELECT i_brand FROM item WHERE i_item_id = 'ITEM123' LIMIT 1)
      AND i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_category = 'Electronics')
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = i.i_item_sk
            AND cr.cr_return_quantity > 0
      )
),
web_sales_cte AS (
    SELECT i.i_item_id,
           ws.ws_net_paid AS sales_amount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND sm.sm_type = 'AIR'
      AND i.i_brand = (SELECT i_brand FROM item WHERE i_item_id = 'ITEM123' LIMIT 1)
      AND i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_category = 'Electronics')
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = i.i_item_sk
            AND cr.cr_return_quantity > 0
      )
),
combined AS (
    SELECT i_item_id, sales_amount FROM cat_sales
    UNION ALL
    SELECT i_item_id, sales_amount FROM web_sales_cte
)
SELECT combined.i_item_id,
       SUM(combined.sales_amount) AS total_sales_amount
FROM combined
GROUP BY combined.i_item_id
HAVING SUM(combined.sales_amount) > 10000
ORDER BY total_sales_amount DESC
