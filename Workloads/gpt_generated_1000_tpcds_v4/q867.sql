WITH web_data AS (
    SELECT
        i.i_category AS category,
        i.i_color AS color,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws.ws_quantity > 2
      AND ws.ws_item_sk IN (
          SELECT inv.inv_item_sk
          FROM inventory inv
          WHERE inv.inv_quantity_on_hand > 200
      )
    GROUP BY i.i_category, i.i_color
    HAVING SUM(ws.ws_net_profit) > 1000
),
catalog_data AS (
    SELECT
        i.i_category AS category,
        i.i_color AS color,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cs.cs_quantity > 5
      AND EXISTS (
          SELECT 1
          FROM call_center cc
          WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
            AND cc.cc_gmt_offset > -5
      )
    GROUP BY i.i_category, i.i_color
    HAVING SUM(cs.cs_net_profit) > 1500
)
SELECT *
FROM web_data
UNION ALL
SELECT *
FROM catalog_data
ORDER BY total_profit DESC
LIMIT 100
