WITH filtered_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        ca.ca_city
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2,}')
      AND ca.ca_city LIKE '%York%'
)
SELECT
    concat(fs.i_brand, ' ', fs.i_product_name) AS brand_product,
    regexp_extract(fs.i_item_desc, '(\\d{3})', 1) AS three_digit_code,
    sum(fs.cs_ext_sales_price) AS total_sales,
    count(*) AS order_cnt
FROM filtered_sales fs
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE lower(wp.wp_url) LIKE concat('%', lower(concat(fs.i_brand, ' ', fs.i_product_name)), '%')
)
GROUP BY
    concat(fs.i_brand, ' ', fs.i_product_name),
    regexp_extract(fs.i_item_desc, '(\\d{3})', 1)
ORDER BY total_sales DESC
LIMIT 100
