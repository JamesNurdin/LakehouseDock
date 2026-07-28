WITH sales_data AS (
    SELECT
        i.i_category AS category,
        cd.cd_credit_rating AS credit_rating,
        ss.ss_net_profit,
        ss.ss_quantity,
        REGEXP_EXTRACT(i.i_item_id, '(\\d+)$') AS item_id_suffix,
        CONCAT(i.i_brand, ' ', i.i_product_name) AS brand_product,
        i.i_item_desc
    FROM tpcds.store_sales ss
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '(Eco|Premium)')
      AND cd.cd_credit_rating LIKE 'High%'
)
SELECT
    category,
    credit_rating,
    COUNT(*) AS sales_cnt,
    SUM(ss_net_profit) AS total_net_profit,
    AVG(ss_net_profit) AS avg_net_profit,
    SUM(ss_quantity) AS total_quantity,
    COUNT(DISTINCT item_id_suffix) AS distinct_item_suffixes
FROM sales_data
GROUP BY category, credit_rating
ORDER BY total_net_profit DESC
LIMIT 100
