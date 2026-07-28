WITH returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'return' AS source,
        SUM(cr.cr_net_loss) AS amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_net_loss > 0
      AND d.d_date >= DATE '1999-01-01'
      AND d.d_date < DATE '2002-01-01'
    GROUP BY d.d_year, d.d_month_seq
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'sale' AS source,
        SUM(ss.ss_net_profit) AS amount
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_net_profit > 0
      AND d.d_date >= DATE '1999-01-01'
      AND d.d_date < DATE '2002-01-01'
    GROUP BY d.d_year, d.d_month_seq
),
combined AS (
    SELECT * FROM returns_agg
    UNION ALL
    SELECT * FROM sales_agg
)
SELECT
    c.d_year,
    c.d_month_seq,
    c.source,
    c.amount,
    SUM(c.amount) OVER (
        PARTITION BY c.source
        ORDER BY c.d_year, c.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM combined c
ORDER BY c.d_year, c.d_month_seq, c.source
LIMIT 100
