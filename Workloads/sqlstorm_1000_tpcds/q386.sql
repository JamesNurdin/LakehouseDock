WITH normalized_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        i.i_product_name,
        s.s_store_name,
        trim(regexp_replace(lower(i.i_product_name), '[^a-z0-9 ]', '')) AS prod_name_clean,
        regexp_extract(trim(regexp_replace(lower(i.i_product_name), '[^a-z0-9 ]', '')), '^([^ ]+ [^ ]+)', 1) AS prod_prefix
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = year(DATE '2024-10-01') - 1
)
SELECT
    prod_prefix,
    count(DISTINCT ss_item_sk) AS distinct_items,
    sum(ss_quantity) AS total_quantity,
    sum(ss_net_profit) AS total_profit,
    array_join(array_agg(DISTINCT s_store_name), ', ') AS stores,
    length(prod_prefix) AS prefix_length,
    replace(prod_prefix, ' ', '_') AS prefix_underscored,
    reverse(prod_prefix) AS prefix_reversed,
    regexp_like(prod_prefix, '^[a-z]+') AS is_alpha_prefix
FROM normalized_sales
WHERE prod_prefix IS NOT NULL
GROUP BY prod_prefix
ORDER BY total_profit DESC
LIMIT 10
