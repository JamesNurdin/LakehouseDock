WITH combined AS (
    SELECT year, month, source_type, amount, profit
    FROM (
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month,
            'catalog_sales' AS source_type,
            SUM(cs.cs_ext_sales_price) AS amount,
            SUM(cs.cs_net_profit) AS profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
          AND NOT EXISTS (
              SELECT 1
              FROM catalog_returns cr
              WHERE cr.cr_order_number = cs.cs_order_number
          )
        GROUP BY d.d_year, d.d_month_seq
        UNION ALL
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month,
            'web_returns' AS source_type,
            -SUM(wr.wr_return_amt_inc_tax) AS amount,
            -SUM(wr.wr_net_loss) AS profit
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
        GROUP BY d.d_year, d.d_month_seq
    ) u
)
SELECT
    agg.year,
    agg.month,
    agg.source_type,
    agg.total_amount,
    agg.total_profit,
    CASE WHEN agg.total_amount > 100000 THEN 'high' ELSE 'low' END AS amount_category,
    SUM(agg.total_amount) OVER (
        PARTITION BY agg.source_type
        ORDER BY agg.year, agg.month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_amount
FROM (
    SELECT
        year,
        month,
        source_type,
        SUM(amount) AS total_amount,
        SUM(profit) AS total_profit
    FROM combined
    GROUP BY year, month, source_type
    HAVING SUM(amount) <> 0
) agg
ORDER BY agg.source_type, agg.year, agg.month
LIMIT 100
