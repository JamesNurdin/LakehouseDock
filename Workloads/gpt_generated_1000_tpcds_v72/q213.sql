WITH sales_filtered AS (
    SELECT
        ss.ss_net_profit,
        s.s_city,
        s.s_zip,
        i.i_brand,
        regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word,
        substr(s.s_zip, 1, 3) AS zip_prefix,
        CONCAT(s.s_city, '_', i.i_brand) AS city_brand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND regexp_like(i.i_item_desc, '(?i)BRIGHT|LARGE')
      AND s.s_city LIKE '%York%'
)
SELECT
    s_city,
    i_brand,
    city_brand,
    first_word,
    zip_prefix,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS sales_count
FROM sales_filtered
GROUP BY
    s_city,
    i_brand,
    city_brand,
    first_word,
    zip_prefix
ORDER BY total_profit DESC
LIMIT 100
