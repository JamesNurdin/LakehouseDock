WITH recent_dates AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
),
combined AS (
    SELECT
        CAST('web_returns' AS varchar) AS source,
        d.d_date AS event_date,
        d.d_year AS year,
        CAST(SUM(wr.wr_net_loss) AS decimal(15,2)) AS metric_val,
        COUNT(*) AS metric_cnt,
        CASE WHEN SUM(wr.wr_return_quantity) > 10 THEN 'High' ELSE 'Low' END AS volume_category
    FROM web_returns wr
    JOIN recent_dates d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_shift = 'first'
    GROUP BY d.d_date, d.d_year
    HAVING SUM(wr.wr_net_loss) > 0

    UNION ALL

    SELECT
        CAST('store_tax' AS varchar) AS source,
        d.d_date AS event_date,
        d.d_year AS year,
        CAST(AVG(s.s_tax_percentage) AS decimal(15,2)) AS metric_val,
        COUNT(s.s_store_sk) AS metric_cnt,
        CASE WHEN AVG(s.s_tax_percentage) > 0.05 THEN 'HighTax' ELSE 'LowTax' END AS volume_category
    FROM store s
    FULL OUTER JOIN recent_dates d
      ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year
)
SELECT
    source,
    event_date,
    year,
    metric_val,
    metric_cnt,
    volume_category,
    ROW_NUMBER() OVER (ORDER BY metric_val DESC) AS overall_rank
FROM combined
ORDER BY year, metric_val DESC
LIMIT 100
