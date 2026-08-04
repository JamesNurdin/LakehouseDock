WITH sampled_ws AS (
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_web_page_sk,
           ws_quantity,
           ws_ext_sales_price,
           ws_ext_discount_amt,
           ws_ext_tax,
           ws_net_profit,
           ws_order_number
    FROM web_sales TABLESAMPLE BERNOULLI (5)
),
item_info AS (
    SELECT i_item_sk,
           i_product_name,
           i_category,
           i_color
    FROM item
    WHERE regexp_like(i_product_name, '.*[A-Z]{2}.*')
),
page_filtered AS (
    SELECT wp_web_page_sk,
           wp_url,
           wp_type
    FROM web_page
    WHERE wp_url LIKE '%example.com%'
      AND regexp_like(wp_url, '^https?://')
),
high_tax_items AS (
    SELECT DISTINCT ws_item_sk
    FROM sampled_ws
    WHERE ws_ext_tax > 20
),
large_qty_items AS (
    SELECT DISTINCT ws_item_sk
    FROM sampled_ws
    WHERE ws_quantity > 5
),
intersect_items AS (
    SELECT ws_item_sk FROM high_tax_items
    INTERSECT
    SELECT ws_item_sk FROM large_qty_items
),
returned_items AS (
    SELECT DISTINCT wr_item_sk AS ws_item_sk
    FROM web_returns
),
valid_items AS (
    SELECT ws_item_sk FROM intersect_items
    EXCEPT
    SELECT ws_item_sk FROM returned_items
),
avg_discount AS (
    SELECT avg(ws_ext_discount_amt) AS avg_discount
    FROM sampled_ws
)
SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    SUBSTRING(i.i_product_name, 1, 10) AS short_name,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    CASE WHEN SUM(ws.ws_ext_discount_amt) > (SELECT avg_discount FROM avg_discount)
         THEN 'Above Avg Discount'
         ELSE 'Below Avg Discount'
    END AS discount_level,
    CONCAT('URL:', wp.wp_url) AS page_url
FROM sampled_ws ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN page_filtered wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN valid_items vi ON ws.ws_item_sk = vi.ws_item_sk
WHERE regexp_like(i.i_product_name, '^.{5,}$')
  AND i.i_color IS NOT NULL
GROUP BY
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    SUBSTRING(i.i_product_name, 1, 10),
    wp.wp_url
ORDER BY total_sales DESC
LIMIT 100
