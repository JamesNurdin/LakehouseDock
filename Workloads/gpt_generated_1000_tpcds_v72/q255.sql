WITH expensive_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_current_price
    FROM   item
    WHERE  i_current_price > 100.00
)
SELECT
    'store' AS sales_channel,
    CAST(s.s_market_id AS VARCHAR) AS region,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_quantity) AS total_quantity
FROM   store_sales ss
JOIN   time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN   store s ON ss.ss_store_sk = s.s_store_sk
JOIN   expensive_items ei ON ss.ss_item_sk = ei.i_item_sk
WHERE  td.t_hour BETWEEN 9 AND 17
  AND EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = ss.ss_item_sk)
GROUP BY
    s.s_market_id,
    s.s_state

UNION ALL

SELECT
    'web' AS sales_channel,
    ws_site.web_name AS region,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_quantity) AS total_quantity
FROM   web_sales ws
JOIN   time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN   web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN   expensive_items ei ON ws.ws_item_sk = ei.i_item_sk
WHERE  td.t_hour BETWEEN 9 AND 17
  AND EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = ws.ws_item_sk)
GROUP BY
    ws_site.web_name

ORDER BY total_net_paid DESC
LIMIT 100
