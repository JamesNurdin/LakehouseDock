WITH filtered_sales AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_brand,
        i.i_class,
        i.i_item_desc,
        i.i_product_name,
        p.p_promo_name
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
      AND i.i_product_name LIKE '%RED%'
)
SELECT
    fs.p_promo_name,
    fs.i_brand,
    fs.i_class,
    regexp_extract(fs.i_item_id, '\\d+', 0) AS numeric_item_id,
    concat(fs.i_brand, '-', fs.i_class) AS brand_class,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    SUM(fs.ss_net_profit) AS total_profit,
    COUNT(DISTINCT fs.ss_customer_sk) AS distinct_customers
FROM filtered_sales fs
GROUP BY
    fs.p_promo_name,
    fs.i_brand,
    fs.i_class,
    fs.i_item_id
ORDER BY total_profit DESC
LIMIT 100
