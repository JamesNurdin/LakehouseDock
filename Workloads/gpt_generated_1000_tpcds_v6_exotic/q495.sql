WITH sales_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        'sales' AS src
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = d.d_date_sk
            AND cs2.cs_ext_discount_amt > 0
      )
    GROUP BY d.d_year, d.d_month_seq
),
returns_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        -SUM(wr.wr_return_amt_inc_tax) AS total_sales,
        'returns' AS src
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    t.year,
    t.month_seq,
    t.src,
    t.total_sales,
    (SELECT AVG(p.p_cost) FROM promotion p) AS avg_promo_cost,
    SUM(t.total_sales) OVER (PARTITION BY t.src ORDER BY t.month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM (
    SELECT year, month_seq, total_sales, src FROM sales_monthly
    UNION ALL
    SELECT year, month_seq, total_sales, src FROM returns_monthly
) t
ORDER BY t.src, t.month_seq
LIMIT 100
