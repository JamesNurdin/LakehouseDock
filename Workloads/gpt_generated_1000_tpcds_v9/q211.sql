WITH sampled_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        ss_store_sk,
        ss_cdemo_sk,
        ss_quantity,
        ss_net_profit,
        ss_sales_price
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
)
SELECT
    s.s_store_id,
    s.s_store_name,
    CONCAT(s.s_city, '-', s.s_state) AS store_location,
    REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{2}[0-9]{2})', 1) AS item_code,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price
FROM sampled_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE
    REGEXP_LIKE(i.i_item_desc, '[A-Z]{2}[0-9]{2}')
    AND s.s_store_name LIKE '%Super%'
    AND cd.cd_gender = 'M'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    CONCAT(s.s_city, '-', s.s_state),
    REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{2}[0-9]{2})', 1)
ORDER BY total_net_profit DESC
LIMIT 100
