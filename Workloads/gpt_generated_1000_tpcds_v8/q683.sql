WITH url_parts AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        split(wp.wp_url, '/') AS url_segments
    FROM web_page wp
),
sales_enriched AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        dd.d_year,
        wp.wp_url,
        p.url_segments
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN url_parts p ON wp.wp_web_page_sk = p.wp_web_page_sk
    WHERE wp.wp_url LIKE '%product%'
),
aggregated AS (
    SELECT
        d_year,
        ws_web_site_sk,
        ws_item_sk,
        ws_web_page_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag,
        CONCAT('Site_', CAST(ws_web_site_sk AS varchar)) AS site_code,
        (SELECT MAX(d_date) FROM date_dim d2 WHERE d2.d_year = d_year) AS max_date_of_year
    FROM sales_enriched
    GROUP BY CUBE (d_year, ws_web_site_sk, ws_item_sk, ws_web_page_sk)
    HAVING SUM(ws_net_profit) > 0
)
SELECT
    a.d_year,
    a.site_code,
    a.profit_flag,
    a.total_profit,
    a.sales_cnt,
    regexp_extract(p.wp_url, 'https?://([^/]+)/', 1) AS domain,
    seg AS url_segment,
    a.max_date_of_year
FROM aggregated a
JOIN url_parts p ON a.ws_web_page_sk = p.wp_web_page_sk
CROSS JOIN UNNEST(p.url_segments) AS t(seg)
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    WHERE ws.ws_web_site_sk = a.ws_web_site_sk
      AND ws.ws_item_sk = a.ws_item_sk
)
AND a.ws_item_sk IN (
    SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_quantity > 5
    INTERSECT
    SELECT wr.wr_item_sk FROM web_returns wr WHERE wr.wr_return_quantity > 0
)
LIMIT 100
