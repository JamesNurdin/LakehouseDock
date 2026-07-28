WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        i.i_brand,
        i.i_brand_id,
        i.i_color,
        i.i_product_name,
        s.s_store_name,
        d.d_date,
        d.d_month_seq,
        -- string processing examples
        regexp_extract(i.i_product_name, '^([^ ]+)', 1) AS first_word,
        concat(s.s_store_name, ' - ', i.i_brand) AS store_brand
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE regexp_like(i.i_color, '^re')
      AND i.i_product_name LIKE '%Blue%'
)
SELECT
    ds.store_brand,
    ds.i_brand,
    date_format(ds.d_date, '%Y-%m') AS year_month,
    COUNT(*) AS sales_transactions,
    SUM(ds.ss_ext_sales_price) AS total_sales_amount,
    SUM(ds.ss_net_profit) AS total_profit,
    MIN(ds.first_word) AS sample_first_word
FROM filtered_sales ds
GROUP BY
    ds.store_brand,
    ds.i_brand,
    date_format(ds.d_date, '%Y-%m')
ORDER BY total_profit DESC
LIMIT 100
