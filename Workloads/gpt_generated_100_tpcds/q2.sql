WITH monthly_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_quarter_name,
        SUM(ss.ss_net_profit) AS month_profit,
        SUM(ss.ss_net_paid) AS month_net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2022-01-01'
      AND d.d_date < DATE '2023-01-01'
    GROUP BY d.d_year, d.d_month_seq, d.d_quarter_name
)
SELECT
    d_year,
    d_month_seq,
    d_quarter_name,
    month_profit,
    month_net_paid,
    avg_discount,
    sum(month_profit) OVER (PARTITION BY d_year ORDER BY d_month_seq) AS cumulative_profit,
    rank() OVER (PARTITION BY d_year ORDER BY month_profit DESC) AS profit_rank
FROM monthly_sales
ORDER BY d_year, d_month_seq
