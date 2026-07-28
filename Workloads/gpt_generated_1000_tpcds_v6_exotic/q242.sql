WITH ws_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    WHERE ws.ws_net_paid_inc_tax > 1000
    GROUP BY ws.ws_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    CONCAT(w.w_city, ', ', w.w_state) AS location,
    w.w_street_name,
    REGEXP_EXTRACT(w.w_street_name, '(\\w+)') AS street_prefix,
    SUBSTR(w.w_zip, 1, 2) AS zip_prefix,
    ws_agg.total_net_profit,
    ws_agg.sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY ws_agg.total_net_profit DESC) AS rn_state
FROM ws_agg
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
WHERE
    REGEXP_LIKE(w.w_street_name, '^North|Ridge|Oak')
    AND w.w_city LIKE 'A%'
ORDER BY
    w.w_state,
    ws_agg.total_net_profit DESC
