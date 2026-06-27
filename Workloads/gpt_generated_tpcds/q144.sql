WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d.d_date >= DATE '2000-01-01'
      AND d.d_date <= DATE '2000-12-31'
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    SUM(fs.ss_net_paid) AS total_net_paid,
    SUM(fs.ss_net_profit) AS total_net_profit,
    SUM(fs.ss_quantity) AS total_quantity,
    COUNT(DISTINCT fs.ss_customer_sk) AS distinct_customers,
    SUM(fs.ss_ext_discount_amt) / NULLIF(SUM(fs.ss_ext_sales_price), 0) AS avg_discount_rate
FROM filtered_sales fs
JOIN store s ON fs.ss_store_sk = s.s_store_sk
JOIN date_dim d ON fs.ss_sold_date_sk = d.d_date_sk
GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 10
