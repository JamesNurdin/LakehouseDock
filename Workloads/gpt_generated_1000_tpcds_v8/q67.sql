WITH filtered_sales AS (
    SELECT
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        wp.wp_url
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://[^/]*\\.com')
      AND wp.wp_url LIKE '%sale%'
),
extracted AS (
    SELECT
        fs.ws_net_profit AS net_profit,
        fs.ws_sold_time_sk,
        fs.ws_warehouse_sk,
        fs.ws_web_site_sk,
        regexp_extract(fs.wp_url, 'https?://([^/]+)/', 1) AS domain
    FROM filtered_sales fs
)
SELECT
    ex.domain,
    td.t_hour,
    wh.w_warehouse_name,
    ws.web_name,
    SUM(ex.net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    CASE WHEN SUM(ex.net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
FROM extracted ex
JOIN time_dim td ON ex.ws_sold_time_sk = td.t_time_sk
JOIN warehouse wh ON ex.ws_warehouse_sk = wh.w_warehouse_sk
JOIN web_site ws ON ex.ws_web_site_sk = ws.web_site_sk
WHERE ws.web_name LIKE '%Shop%'
GROUP BY
    ex.domain,
    td.t_hour,
    wh.w_warehouse_name,
    ws.web_name
ORDER BY total_net_profit DESC
LIMIT 100
