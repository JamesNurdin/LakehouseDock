WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE td.t_meal_time = 'lunch'
      AND s.s_store_name LIKE '%Store%'
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
),
item_info AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        regexp_extract(i.i_item_desc, '(\\d{3,})', 1) AS extracted_code,
        substring(i.i_product_name, 1, 10) AS short_product_name,
        concat(i.i_brand, ' ', i.i_category) AS brand_category
    FROM item i
    WHERE regexp_like(i.i_item_desc, '\\d{3,}')
),
avg_item_profit AS (
    SELECT
        ss_item_sk AS item_sk,
        AVG(ss_net_profit) AS avg_net_profit
    FROM store_sales
    GROUP BY ss_item_sk
)
SELECT
    s.s_store_name,
    ii.i_product_name,
    ii.short_product_name,
    ii.extracted_code,
    agg.total_quantity,
    agg.total_net_paid,
    agg.total_net_profit,
    aip.avg_net_profit,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = ii.i_item_sk) AS return_count
FROM sales_agg agg
JOIN store s ON agg.store_sk = s.s_store_sk
JOIN item_info ii ON agg.item_sk = ii.i_item_sk
JOIN avg_item_profit aip ON agg.item_sk = aip.item_sk
WHERE agg.total_net_profit > aip.avg_net_profit * 1.5
ORDER BY agg.total_net_profit DESC
LIMIT 100
