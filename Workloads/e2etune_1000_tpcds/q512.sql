WITH sales_by_store_quarter AS (
    SELECT
        ss.ss_store_sk,
        d.d_quarter_name,
        d.d_quarter_seq,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_net_paid) AS total_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'N'
      AND d.d_dow BETWEEN 2 AND 6               -- Monday to Friday (assuming 1=Sunday)
      AND d.d_year = 2022
    GROUP BY
        ss.ss_store_sk,
        d.d_quarter_name,
        d.d_quarter_seq,
        d.d_year
)
SELECT
    s.d_year,
    s.d_quarter_name,
    s.ss_store_sk,
    s.total_profit,
    s.total_paid,
    s.avg_discount,
    s.total_quantity,
    s.distinct_customers,
    RANK() OVER (PARTITION BY s.d_quarter_name ORDER BY s.total_profit DESC) AS profit_rank,
    AVG(s.total_profit) OVER (
        PARTITION BY s.ss_store_sk
        ORDER BY s.d_quarter_seq
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS profit_3q_moving_avg
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY d_quarter_name ORDER BY total_profit DESC) AS rn
    FROM sales_by_store_quarter
) s
WHERE s.rn <= 5                               -- top 5 stores per quarter
ORDER BY s.d_year, s.d_quarter_seq, profit_rank
