WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        d.d_year,
        d.d_month_seq
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
)
SELECT
    s.s_store_id,
    s.s_store_name,
    fs.d_year,
    fs.d_month_seq AS month_seq,
    i.i_category,
    SUM(fs.ss_net_profit) AS total_net_profit,
    AVG(fs.ss_ext_discount_amt) AS avg_discount_amount,
    AVG(fs.ss_ext_discount_amt / NULLIF(fs.ss_ext_sales_price, 0)) AS avg_discount_pct
FROM filtered_sales fs
JOIN store s ON fs.ss_store_sk = s.s_store_sk
JOIN item i ON fs.ss_item_sk = i.i_item_sk
WHERE s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    fs.d_year,
    fs.d_month_seq,
    i.i_category
ORDER BY total_net_profit DESC
