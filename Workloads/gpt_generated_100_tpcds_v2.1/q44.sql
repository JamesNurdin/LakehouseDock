WITH returns_agg AS (
    SELECT
        w.w_city AS city,
        'return_amount' AS metric_type,
        SUM(cr.cr_return_amount) AS metric_value,
        DATE_TRUNC('month', d.d_date) AS period
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND w.w_country = 'United States'
      AND d.d_holiday = 'N'
    GROUP BY w.w_city, DATE_TRUNC('month', d.d_date)
),
inventory_agg AS (
    SELECT
        w.w_city AS city,
        'inventory_on_hand' AS metric_type,
        CAST(SUM(inv.inv_quantity_on_hand) AS decimal(12,2)) AS metric_value,
        DATE_TRUNC('month', d.d_date) AS period
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND w.w_city IN ('Five Points', 'Pine Grove', 'Riverside')
    GROUP BY w.w_city, DATE_TRUNC('month', d.d_date)
)
SELECT city, metric_type, metric_value, period
FROM returns_agg
UNION ALL
SELECT city, metric_type, metric_value, period
FROM inventory_agg
ORDER BY city, metric_type, period
LIMIT 100
