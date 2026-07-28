WITH daily_summary AS (
    SELECT
        d.d_date,
        d.d_year,
        r.r_reason_desc,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
      AND d.d_holiday = 'N'
      AND wr.wr_account_credit > 0
      AND wr.wr_return_quantity >= 1
      AND wr.wr_return_tax IS NOT NULL
    GROUP BY d.d_date, d.d_year, r.r_reason_desc
),
year_summary AS (
    SELECT
        ds.d_year,
        ds.r_reason_desc,
        SUM(ds.total_return_amt) AS year_return_total,
        AVG(ds.distinct_orders) AS avg_distinct_orders_per_day
    FROM daily_summary ds
    WHERE ds.r_reason_desc IS NOT NULL
      AND ds.r_reason_desc NOT IN (
          SELECT DISTINCT r2.r_reason_desc
          FROM reason r2
          WHERE r2.r_reason_id LIKE 'AAAAAAA%'
      )
      AND EXISTS (
          SELECT 1
          FROM date_dim d2
          WHERE d2.d_year = ds.d_year
            AND d2.d_quarter_seq = 1
      )
    GROUP BY ds.d_year, ds.r_reason_desc
)
SELECT
    ys.d_year,
    ys.r_reason_desc,
    ys.year_return_total,
    ys.avg_distinct_orders_per_day,
    CASE WHEN ys.year_return_total > 5000 THEN 'HIGH_YEAR' ELSE 'LOW_YEAR' END AS year_return_category
FROM year_summary ys
ORDER BY ys.year_return_total DESC
LIMIT 100
