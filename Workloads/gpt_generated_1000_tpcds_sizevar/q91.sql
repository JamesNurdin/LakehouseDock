/*
Goal: Calculate total sales and profit per web site for the year 2001 on web pages whose URL contains the '/sports/' segment and whose page type starts with 'C'. The query extracts the domain from the URL, classifies the order quantity, and assigns a ranking to each site based on profit.
*/
WITH base AS (
    SELECT
        ws.ws_web_site_sk AS web_site_sk,
        regexp_extract(wp.wp_url, '^https?://([^/]+)/', 1) AS domain,
        CASE WHEN ws.ws_quantity > 5 THEN 'High' ELSE 'Low' END AS quantity_category,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(wp.wp_url, '^https?://[^/]+/sports/.*$')
      AND wp.wp_type LIKE 'C%'
)
SELECT
    ws.web_site_id,
    ws.web_name,
    base.domain,
    base.quantity_category,
    SUM(base.ws_ext_sales_price) AS total_sales,
    SUM(base.ws_net_profit)       AS total_profit,
    ROW_NUMBER() OVER (ORDER BY SUM(base.ws_net_profit) DESC) AS row_num
FROM base
JOIN web_site ws ON base.web_site_sk = ws.web_site_sk
GROUP BY
    ws.web_site_id,
    ws.web_name,
    base.domain,
    base.quantity_category
ORDER BY total_profit DESC
