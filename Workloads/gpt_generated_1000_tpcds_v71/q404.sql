WITH sales_page AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        wp.wp_url,
        d.d_date,
        d.d_year
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2002
      AND regexp_like(wp.wp_url, 'promo')
)
SELECT
    regexp_extract(sales_page.wp_url, 'https?://([^/]+)/', 1) AS domain,
    COUNT(*) AS sales_count,
    SUM(sales_page.ws_net_profit) AS total_profit,
    CASE
        WHEN SUM(sales_page.ws_net_profit) > 100000 THEN 'High'
        WHEN SUM(sales_page.ws_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_page
WHERE substring(sales_page.wp_url, 1, 5) = 'http:'
  AND sales_page.wp_url LIKE '%promo%'
GROUP BY regexp_extract(sales_page.wp_url, 'https?://([^/]+)/', 1)
ORDER BY total_profit DESC
LIMIT 100
