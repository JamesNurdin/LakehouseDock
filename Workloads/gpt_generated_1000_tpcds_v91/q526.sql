WITH ws_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    ws.ws_item_sk,
    w.w_warehouse_name,
    seg.url_segment,
    regexp_extract(wp.wp_url, 'promo/([^/]+)', 1) AS promo_code,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt,
    CONCAT('Warehouse: ', w.w_warehouse_name) AS warehouse_label,
    SUBSTRING(wp.wp_url FROM 1 FOR 30) AS url_prefix,
    (
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = ws.ws_item_sk
    ) AS total_return_amount
FROM ws_sample ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS seg(url_segment)
WHERE regexp_like(wp.wp_url, '^https?://.*promo.*')
  AND wp.wp_url LIKE '%sale%'
GROUP BY
    ws.ws_item_sk,
    w.w_warehouse_name,
    seg.url_segment,
    wp.wp_url,
    regexp_extract(wp.wp_url, 'promo/([^/]+)', 1)
ORDER BY total_sales DESC
LIMIT 100
