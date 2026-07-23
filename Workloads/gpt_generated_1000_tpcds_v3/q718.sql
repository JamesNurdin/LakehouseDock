WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_sales_price,
        i.i_category,
        i.i_brand,
        i.i_formulation,
        s.s_store_id,
        s.s_city,
        s.s_store_name,
        regexp_extract(i.i_formulation, '(\\d+)', 1) AS formulation_number,
        substring(i.i_category, 1, 3) AS cat_prefix,
        substring(s.s_store_name, 1, 5) AS store_prefix,
        concat(i.i_category, '-', i.i_brand) AS cat_brand
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_formulation, '\\d')
      AND s.s_city LIKE 'San%'
)
SELECT
    s_store_id,
    s_city,
    store_prefix,
    i_category,
    cat_prefix,
    i_brand,
    cat_brand,
    formulation_number,
    sum(ss_quantity) AS total_quantity,
    sum(ss_net_paid) AS total_net_paid,
    avg(ss_sales_price) AS avg_sales_price,
    sum(ss_net_profit) AS total_net_profit
FROM filtered_sales
GROUP BY
    s_store_id,
    s_city,
    store_prefix,
    i_category,
    cat_prefix,
    i_brand,
    cat_brand,
    formulation_number
HAVING sum(ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
