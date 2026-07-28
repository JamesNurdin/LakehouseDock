WITH web_sales_agg AS (
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month,
            'sale' AS transaction_type,
            SUM(ws.ws_net_paid) AS amount
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 2001 AND 2002
        GROUP BY d.d_year, d.d_month_seq
    ),
    store_returns_agg AS (
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month,
            'return' AS transaction_type,
            SUM(sr.sr_net_loss) * -1 AS amount
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 2001 AND 2002
        GROUP BY d.d_year, d.d_month_seq
    ),
    combined AS (
        SELECT * FROM web_sales_agg
        UNION ALL
        SELECT * FROM store_returns_agg
    )
SELECT
    year,
    month,
    transaction_type,
    SUM(amount) AS total_amount,
    GROUPING(year) AS g_year,
    GROUPING(month) AS g_month,
    GROUPING(transaction_type) AS g_type
FROM combined
GROUP BY GROUPING SETS (
    (year, month, transaction_type),
    (year, month),
    (year),
    ()
)
ORDER BY
    COALESCE(year, 9999),
    COALESCE(month, 99),
    transaction_type
LIMIT 100
