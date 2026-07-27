WITH filtered_web_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_net_profit,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://[^/]*\\.example\\.com/.*sale')
      AND wp.wp_type LIKE 'Category%'
)
SELECT
    w.w_state,
    w.w_warehouse_name,
    substring(w.w_warehouse_name, 1, 10) AS short_warehouse_name,
    SUM(fws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT fws.ws_order_number) AS orders_count,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY SUM(fws.ws_net_profit) DESC) AS profit_rank_in_state
FROM filtered_web_sales fws
JOIN warehouse w ON fws.ws_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_warehouse_sk = w.w_warehouse_sk
      AND regexp_like(r.r_reason_desc, '(?i)damage')
)
GROUP BY w.w_state, w.w_warehouse_name
HAVING SUM(fws.ws_net_profit) > 10000
ORDER BY w.w_state, profit_rank_in_state
