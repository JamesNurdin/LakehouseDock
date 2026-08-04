WITH ss_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
agg AS (
    SELECT
        s.s_store_id,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS store_full_name,
        i.i_item_id,
        SUBSTRING(i.i_item_id, 1, 5) AS short_item_id,
        REGEXP_EXTRACT(i.i_item_desc, '^([^ ]+)', 1) AS first_word_desc,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_count
    FROM ss_sample ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE
        REGEXP_LIKE(i.i_item_desc, '(?i)brush|clean')
        AND p.p_promo_name LIKE '%Discount%'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        i.i_item_id,
        SUBSTRING(i.i_item_id, 1, 5),
        REGEXP_EXTRACT(i.i_item_desc, '^([^ ]+)', 1)
)
SELECT
    store_full_name,
    i_item_id,
    short_item_id,
    first_word_desc,
    total_profit,
    sales_count,
    CASE
        WHEN total_profit > 10000 THEN 'High'
        WHEN total_profit BETWEEN 1000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM agg
ORDER BY total_profit DESC
LIMIT 100
