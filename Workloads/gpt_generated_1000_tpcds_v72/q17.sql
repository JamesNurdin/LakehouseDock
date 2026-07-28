WITH sales_detail AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_product_name,
        regexp_extract(i.i_product_name, '^([^ ]+)', 1) AS product_first_word,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE
        regexp_like(i.i_product_name, 'Co[\\w]*')
        AND s.s_store_name LIKE 'A%'
        AND d.d_year = 2002
),
sales_by_store_month AS (
    SELECT
        s_store_id,
        s_store_name,
        d_year,
        d_month_seq,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS txn_cnt,
        COUNT(DISTINCT product_first_word) AS distinct_first_word_cnt
    FROM sales_detail
    GROUP BY
        s_store_id,
        s_store_name,
        d_year,
        d_month_seq
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    d_month_seq,
    total_profit,
    txn_cnt,
    distinct_first_word_cnt,
    CASE
        WHEN total_profit > 100000 THEN 'High'
        WHEN total_profit > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    CONCAT(s_store_name, ' (', CAST(d_year AS VARCHAR), ')') AS store_year_label,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_year
FROM sales_by_store_month
ORDER BY d_year, profit_rank_year
