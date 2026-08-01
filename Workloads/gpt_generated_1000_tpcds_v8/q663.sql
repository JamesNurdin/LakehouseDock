WITH sampled_ws AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
),
filtered_ws AS (
    SELECT DISTINCT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        wsite.web_name,
        wp.wp_url,
        CONCAT(i.i_brand, '-', i.i_color) AS brand_color
    FROM sampled_ws ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ws.ws_net_paid > 0
      AND regexp_like(i.i_product_name, '[A-Z]{2}')
      AND wp.wp_url LIKE 'http%://%/store/%'
      AND ws.ws_item_sk NOT IN (
            SELECT sr_item_sk
            FROM store_returns
            WHERE sr_return_quantity > 5
        )
)
SELECT
    COALESCE(web_name, 'All Sites') AS web_site,
    COALESCE(i_category, 'All Categories') AS category,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    COUNT(DISTINCT i_item_id) AS distinct_items,
    COUNT(DISTINCT brand_color) AS distinct_brand_color,
    SUM(ws_net_paid) AS total_net_paid,
    CASE
        WHEN SUM(ws_net_paid) > 100000 THEN 'High'
        ELSE 'Low'
    END AS revenue_bracket
FROM filtered_ws
GROUP BY ROLLUP (web_name, i_category)
ORDER BY total_net_paid DESC
LIMIT 100
