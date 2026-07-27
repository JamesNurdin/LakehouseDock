WITH returns_agg AS (
    SELECT
        d.d_fy_year AS fiscal_year,
        'return_amount' AS metric,
        SUM(wr.wr_return_amt) AS metric_value
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wp.wp_type = 'ad'
      AND d.d_fy_year BETWEEN 1910 AND 1915
      AND ib.ib_upper_bound >= 50000
    GROUP BY d.d_fy_year
),
inventory_agg AS (
    SELECT
        d.d_fy_year AS fiscal_year,
        'inventory_qty' AS metric,
        SUM(i.inv_quantity_on_hand) AS metric_value
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_fy_year BETWEEN 1910 AND 1915
      AND ws.web_state = 'CA'
    GROUP BY d.d_fy_year
)
SELECT fiscal_year, metric, metric_value
FROM returns_agg
UNION ALL
SELECT fiscal_year, metric, metric_value
FROM inventory_agg
ORDER BY fiscal_year, metric
LIMIT 100
