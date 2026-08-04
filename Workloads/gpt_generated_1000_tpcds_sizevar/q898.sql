WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_color,
        i.i_current_price,
        regexp_extract(i.i_product_name, '(\\d+)', 1) AS product_number,
        CASE WHEN i.i_current_price > (SELECT max(i2.i_current_price) FROM item i2) THEN 'High' ELSE 'Low' END AS price_category,
        l.total_sales,
        l.avg_net_profit
    FROM store_sales ss
    RIGHT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN LATERAL (
        SELECT
            coalesce(sum(ss2.ss_ext_sales_price), 0) AS total_sales,
            coalesce(avg(ss2.ss_net_profit), 0) AS avg_net_profit
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
    ) l ON true
    WHERE regexp_like(i.i_product_name, '^.*[A-Z]{2}.*$')
      AND i.i_color LIKE 'Red%'
      AND substr(i.i_item_id, 1, 3) = '100'
)
SELECT
    i_item_sk,
    i_product_name,
    i_brand,
    i_color,
    i_current_price,
    product_number,
    price_category,
    total_sales,
    avg_net_profit
FROM item_sales
WHERE total_sales > (
        SELECT avg(total_sales)
        FROM (
            SELECT coalesce(sum(ss3.ss_ext_sales_price), 0) AS total_sales
            FROM store_sales ss3
            GROUP BY ss3.ss_item_sk
        ) sub
    )
ORDER BY total_sales DESC
LIMIT 100
