WITH returns_agg AS (
    SELECT
        d.d_date AS report_date,
        wp.wp_type AS category,
        SUM(wr.wr_return_amt) AS amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_weekend = 'Y'
      AND t.t_shift = 'first'
    GROUP BY d.d_date, wp.wp_type
),
inventory_agg AS (
    SELECT
        d.d_date AS report_date,
        CAST('Inventory' AS varchar) AS category,
        SUM(i.inv_quantity_on_hand) AS amount
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_following_holiday = 'Y'
    GROUP BY d.d_date
),
combined AS (
    SELECT report_date, category, amount FROM returns_agg
    UNION ALL
    SELECT report_date, category, amount FROM inventory_agg
)
SELECT DISTINCT report_date, category, amount
FROM combined
ORDER BY report_date DESC, category
LIMIT 100
