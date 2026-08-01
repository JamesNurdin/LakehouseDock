WITH
    latest_sales_year AS (
        SELECT MAX(d.d_year) AS max_year
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    ),
    sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq AS month_seq,
            'sales' AS record_type,
            SUM(cs.cs_net_paid) AS amount,
            COUNT(*) AS cnt
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = (SELECT max_year FROM latest_sales_year)
        GROUP BY ROLLUP (d.d_year, d.d_month_seq)
    ),
    returns_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq AS month_seq,
            'returns' AS record_type,
            SUM(wr.wr_net_loss) AS amount,
            COUNT(*) AS cnt
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = (SELECT max_year FROM latest_sales_year)
        GROUP BY ROLLUP (d.d_year, d.d_month_seq)
    )
SELECT
    combined.d_year,
    combined.month_seq,
    combined.record_type,
    combined.amount,
    combined.cnt
FROM (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
) AS combined
ORDER BY
    combined.d_year,
    combined.month_seq NULLS LAST,
    combined.record_type
