WITH combined AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        sm.sm_code AS source,
        SUM(ws.ws_ext_sales_price) AS metric_amount,
        COUNT(*) AS metric_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND sm.sm_code IN ('AIR', 'SEA')
    GROUP BY d.d_year, d.d_month_seq, sm.sm_code

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        'INV' AS source,
        SUM(inv.inv_quantity_on_hand) AS metric_amount,
        COUNT(*) AS metric_count
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT year,
       month_seq,
       source,
       metric_amount,
       metric_count
FROM combined
ORDER BY year DESC, month_seq DESC, source
LIMIT 100
