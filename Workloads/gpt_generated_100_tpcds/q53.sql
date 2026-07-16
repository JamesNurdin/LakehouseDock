WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '1998-01-01' AND d.d_date < DATE '1999-01-01'
    GROUP BY s.s_store_id, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '1998-01-01' AND d.d_date < DATE '1999-01-01'
    GROUP BY s.s_store_id, d.d_year, d.d_moy
)
SELECT
    s.store_id,
    s.year,
    s.month,
    s.total_net_paid,
    s.total_net_profit,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    s.total_net_paid - COALESCE(r.total_return_amt, 0) AS net_revenue,
    s.distinct_customers
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.store_id = r.store_id
   AND s.year = r.year
   AND s.month = r.month
ORDER BY s.total_net_paid DESC
LIMIT 100
