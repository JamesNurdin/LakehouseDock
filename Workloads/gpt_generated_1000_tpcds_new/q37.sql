WITH sales AS (
    SELECT
        d.d_year AS year,
        'catalog_sales' AS source,
        SUM(cs.cs_net_profit) AS amount
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
    GROUP BY d.d_year
),
returns AS (
    SELECT
        d.d_year AS year,
        'store_returns' AS source,
        SUM(sr.sr_net_loss) AS amount
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_current_year = 'Y'
      AND r.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY d.d_year
),
combined AS (
    SELECT year, source, amount FROM sales
    UNION ALL
    SELECT year, source, amount FROM returns
)
SELECT
    combined.year,
    combined.source,
    combined.amount
FROM combined
WHERE combined.amount > (
    SELECT MAX(cs.cs_ext_sales_price)
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
)
ORDER BY combined.year DESC, combined.amount DESC
LIMIT 100
