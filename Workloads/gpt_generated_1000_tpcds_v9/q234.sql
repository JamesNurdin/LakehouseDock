WITH web_agg AS (
    SELECT
        w.w_state AS state,
        'WEB_PROFIT' AS metric_type,
        SUM(ws.ws_net_profit) AS total_amount,
        COUNT(*) AS record_count
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE regexp_like(w.w_warehouse_name, '^WH.*')
      AND s.web_name LIKE '%Shop%'
    GROUP BY w.w_state
),
return_agg AS (
    SELECT
        w.w_state AS state,
        'WEB_RETURN_LOSS' AS metric_type,
        SUM(wr.wr_net_loss) AS total_amount,
        COUNT(*) AS record_count
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_city, '^[A-Z][a-z]+')
      AND regexp_like(w.w_street_name, '^Oak.*')
    GROUP BY w.w_state
),
combined AS (
    SELECT * FROM web_agg
    UNION ALL
    SELECT * FROM return_agg
)
SELECT
    state,
    metric_type,
    SUM(total_amount) AS total_amount,
    SUM(record_count) AS record_count,
    MAX(CONCAT(state, '-', metric_type)) AS state_metric_label,
    (
        SELECT COUNT(DISTINCT ib.ib_income_band_sk)
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_buy_potential = '0-500'
    ) AS low_income_band_cnt
FROM combined
GROUP BY GROUPING SETS (
    (state, metric_type),
    (state),
    (metric_type),
    ()
)
ORDER BY state, metric_type
LIMIT 100
