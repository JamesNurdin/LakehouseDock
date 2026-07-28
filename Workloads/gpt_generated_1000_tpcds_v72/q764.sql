-- goal: Summarize monthly store performance for items whose product name contains the word 'brand' and the pattern 'COOL', showing distinct item counts, profit metrics, and string‑derived attributes.
WITH filtered_sales AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_product_name,
        ss.ss_quantity,
        ss.ss_net_profit,
        CONCAT(i.i_color, '-', i.i_size) AS color_size,
        regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_product_name LIKE '%COOL%'
      AND regexp_like(i.i_product_name, '(?i)\\bbrand\\b')
)
SELECT
    fs.s_store_name,
    fs.d_year,
    fs.d_month_seq,
    COUNT(DISTINCT fs.i_item_sk) AS distinct_items_sold,
    SUM(fs.ss_quantity) AS total_quantity,
    SUM(fs.ss_net_profit) AS total_profit,
    AVG(fs.ss_net_profit) AS avg_profit_per_item,
    (SELECT avg(ss2.ss_net_profit) FROM store_sales ss2) AS avg_profit_all_stores,
    MAX(fs.profit_flag) AS overall_profit_flag
FROM filtered_sales fs
GROUP BY
    fs.s_store_name,
    fs.d_year,
    fs.d_month_seq
ORDER BY
    total_profit DESC,
    fs.s_store_name
LIMIT 100
