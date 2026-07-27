WITH warehouse_profit AS (
    SELECT
        w.w_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
    HAVING SUM(ws.ws_net_profit) > 50000
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_profit) AS net_profit,
    CASE
        WHEN SUM(ws.ws_net_profit) >= 100000 THEN 'Very High'
        WHEN SUM(ws.ws_net_profit) >= 50000 THEN 'High'
        ELSE 'Medium'
    END AS profit_category,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    SUBSTR(w.w_warehouse_name, 1, 10) AS warehouse_name_prefix
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE REGEXP_LIKE(wp.wp_url, '^https?://.*\\.com/.*$')
  AND wp.wp_type LIKE 'C%'
  AND cd.cd_gender = 'M'
  AND EXISTS (
        SELECT 1 FROM warehouse_profit wp2
        WHERE wp2.w_warehouse_sk = w.w_warehouse_sk
    )
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    wp.wp_type,
    wp.wp_url,
    SUBSTR(w.w_warehouse_name, 1, 10),
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1)
ORDER BY net_profit DESC
LIMIT 20
