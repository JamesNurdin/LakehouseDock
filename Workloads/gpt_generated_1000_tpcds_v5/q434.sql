WITH ws_agg AS (
    SELECT
        ws_warehouse_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        AVG(ws_ext_tax) AS avg_tax
    FROM web_sales
    WHERE ws_ext_tax > 20
    GROUP BY ws_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    regexp_extract(w.w_suite_number, '\\d+', 1) AS suite_num,
    concat(w.w_street_number, ' ', w.w_street_name, ', ', w.w_suite_number) AS full_address,
    substring(w.w_zip, 1, 5) AS zip_prefix,
    ws_agg.total_profit,
    ws_agg.order_cnt,
    ws_agg.avg_tax
FROM warehouse w
JOIN ws_agg ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
WHERE regexp_like(w.w_suite_number, '^Suite\\s*\\d+')
  AND w.w_city LIKE 'S%'
ORDER BY ws_agg.total_profit DESC
LIMIT 100
