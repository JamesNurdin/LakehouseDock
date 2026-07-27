WITH returns_agg AS (
    SELECT d.d_date AS report_date,
           'return_amount' AS metric_type,
           CAST(SUM(wr.wr_return_amt_inc_tax) AS double) AS metric_value
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_current_quarter = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY d.d_date
),
inventory_agg AS (
    SELECT d.d_date AS report_date,
           'inventory_on_hand' AS metric_type,
           CAST(SUM(i.inv_quantity_on_hand) AS double) AS metric_value
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_current_quarter = 'Y'
      AND i.inv_quantity_on_hand > 100
    GROUP BY d.d_date
)
SELECT report_date, metric_type, metric_value
FROM returns_agg
UNION ALL
SELECT report_date, metric_type, metric_value
FROM inventory_agg
ORDER BY report_date, metric_type
LIMIT 100
