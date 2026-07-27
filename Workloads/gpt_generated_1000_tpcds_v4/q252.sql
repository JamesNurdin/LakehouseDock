WITH sales AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(cs.cs_net_paid) AS amount,
        'sales' AS source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_category = 'Electronics'
    GROUP BY d.d_year, d.d_month_seq
),
returns AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_return_amount) AS amount,
        'returns' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_category = 'Electronics'
    GROUP BY d.d_year, d.d_month_seq
),
combined AS (
    SELECT source, year, month_seq, amount FROM sales
    UNION ALL
    SELECT source, year, month_seq, amount FROM returns
)
SELECT
    source,
    year,
    month_seq,
    amount,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY year, month_seq) AS rn,
    SUM(amount) OVER (PARTITION BY source ORDER BY year, month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_amount
FROM combined
ORDER BY source, year, month_seq
