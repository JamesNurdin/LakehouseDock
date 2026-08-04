WITH filtered_item_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        i.i_manufact_id,
        i.i_product_name
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_product_name LIKE '%Sport%'
      AND regexp_like(i.i_color, '^(Red|Blue)$')
),
filtered_page_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        wp.wp_url,
        wp.wp_image_count
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%promo%'
      AND regexp_extract(wp.wp_url, '(?i)promo') IS NOT NULL
),
orders_only_in_items AS (
    SELECT ws_order_number
    FROM filtered_item_sales
    EXCEPT
    SELECT ws_order_number
    FROM filtered_page_sales
)
SELECT
    COALESCE(i.ws_order_number, p.ws_order_number) AS order_number,
    COALESCE(i.i_manufact_id, -1) AS manufact_id,
    COALESCE(i.i_product_name, '') AS product_name,
    COALESCE(p.wp_url, '') AS page_url,
    SUM(COALESCE(i.ws_ext_sales_price, 0) + COALESCE(p.ws_ext_sales_price, 0)) AS total_sales,
    CASE WHEN o.ws_order_number IS NOT NULL THEN TRUE ELSE FALSE END AS only_in_item_side
FROM filtered_item_sales i
FULL OUTER JOIN filtered_page_sales p
    ON i.ws_order_number = p.ws_order_number
LEFT JOIN orders_only_in_items o
    ON COALESCE(i.ws_order_number, p.ws_order_number) = o.ws_order_number
GROUP BY
    COALESCE(i.ws_order_number, p.ws_order_number),
    COALESCE(i.i_manufact_id, -1),
    COALESCE(i.i_product_name, ''),
    COALESCE(p.wp_url, ''),
    o.ws_order_number
ORDER BY total_sales DESC
LIMIT 100
