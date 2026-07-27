SELECT
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    CONCAT(sm.sm_code, '-', sm.sm_carrier) AS ship_desc,
    regexp_extract(sm.sm_ship_mode_id, '(A{3})(A{4})', 1) AS id_part,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    CASE WHEN SUM(ws.ws_ext_ship_cost) > 500 THEN 'High Ship Cost' ELSE 'Low Ship Cost' END AS ship_cost_category
FROM ship_mode sm
JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
WHERE sm.sm_carrier LIKE '%UPS%'
  AND regexp_like(sm.sm_ship_mode_id, '^A{8}')
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    sm.sm_code,
    regexp_extract(sm.sm_ship_mode_id, '(A{3})(A{4})', 1)
ORDER BY total_net_profit DESC
LIMIT 100
