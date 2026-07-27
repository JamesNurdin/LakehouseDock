WITH filtered_sales AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
)
SELECT
    p.p_promo_name,
    i.i_category,
    i.i_product_name,
    concat(i.i_brand, '-', i.i_color) AS brand_color,
    regexp_extract(i.i_product_name, '(\\w+)-\\w+', 1) AS first_word,
    t.t_hour,
    sum(fs.ss_net_profit) AS total_profit,
    sum(fs.ss_quantity) AS total_quantity
FROM filtered_sales fs
JOIN item i ON fs.ss_item_sk = i.i_item_sk
JOIN time_dim t ON fs.ss_sold_time_sk = t.t_time_sk
JOIN promotion p ON fs.ss_promo_sk = p.p_promo_sk
WHERE i.i_product_name LIKE '%-RED%'
GROUP BY
    p.p_promo_name,
    i.i_category,
    i.i_product_name,
    concat(i.i_brand, '-', i.i_color),
    regexp_extract(i.i_product_name, '(\\w+)-\\w+', 1),
    t.t_hour
ORDER BY total_profit DESC
LIMIT 100
