WITH cc_filtered AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        cc_hours
    FROM call_center
    WHERE cc_name LIKE 'A%'
      AND SUBSTRING(cc_hours, 1, 3) = '9am'
)
SELECT
    w.w_warehouse_name,
    sm.sm_ship_mode_id,
    CONCAT('Warehouse ', w.w_warehouse_name) AS warehouse_label,
    REGEXP_EXTRACT(w.w_street_number, '(\\d+)') AS street_number_extracted,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    CASE
        WHEN SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS profit_category
FROM cc_filtered cc
JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
WHERE REGEXP_LIKE(w.w_county, 'County$')
GROUP BY
    w.w_warehouse_name,
    sm.sm_ship_mode_id,
    w.w_street_number
HAVING SUM(cs.cs_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 50
