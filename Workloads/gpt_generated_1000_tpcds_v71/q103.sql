WITH ws_filtered AS (
    SELECT ws.ws_ship_mode_sk,
           ws.ws_net_paid_inc_tax,
           ws.ws_net_profit,
           ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_net_paid_inc_tax > 500
),
ship_mode_filtered AS (
    SELECT sm.sm_ship_mode_sk,
           sm.sm_code,
           sm.sm_carrier,
           sm.sm_contract,
           regexp_extract(sm.sm_contract, '([A-Z]+)', 1) AS contract_caps,
           CASE 
               WHEN sm.sm_contract LIKE '%FQ%' THEN 'ContainsFQ'
               WHEN sm.sm_contract LIKE '%Ek%' THEN 'ContainsEk'
               ELSE 'Other'
           END AS contract_category
    FROM ship_mode sm
    WHERE regexp_like(sm.sm_contract, '[A-Z]')
)
SELECT
    smf.sm_code,
    smf.sm_carrier,
    smf.contract_category,
    COUNT(DISTINCT wsf.ws_order_number) AS order_cnt,
    SUM(wsf.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(wsf.ws_net_profit) AS avg_net_profit,
    SUM(CASE WHEN wsf.ws_net_profit > 0 THEN 1 ELSE 0 END) AS profit_order_cnt,
    (SELECT COUNT(*) FROM web_sales ws2 WHERE ws2.ws_net_paid_inc_tax > 1000) AS high_value_order_total
FROM ship_mode_filtered smf
JOIN ws_filtered wsf
  ON wsf.ws_ship_mode_sk = smf.sm_ship_mode_sk
WHERE smf.contract_caps IS NOT NULL
GROUP BY smf.sm_code, smf.sm_carrier, smf.contract_category
HAVING SUM(wsf.ws_net_paid_inc_tax) > (
    SELECT AVG(ws3.ws_net_paid_inc_tax) FROM web_sales ws3
)
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
