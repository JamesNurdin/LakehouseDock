WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        t.t_hour
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_item_sk IN (
        SELECT i2.i_item_sk
        FROM item i2
        WHERE i2.i_brand = 'BrandX'
    )
)
SELECT
    t_hour,
    i_category,
    regexp_extract(i_item_desc, '(\\w+)', 1) AS first_word,
    COUNT(*) AS sales_cnt,
    SUM(ss_net_profit) AS total_profit
FROM filtered_sales
WHERE
    regexp_like(i_item_desc, '.*[0-9]{2}.*')
    AND i_item_desc LIKE '%MAGIC%'
GROUP BY
    t_hour,
    i_category,
    regexp_extract(i_item_desc, '(\\w+)', 1)
ORDER BY
    total_profit DESC
LIMIT 100
