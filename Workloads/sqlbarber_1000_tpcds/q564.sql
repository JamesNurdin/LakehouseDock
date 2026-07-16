SELECT
    sm.sm_ship_mode_id,
    sm.sm_ship_mode_sk,
    SUM(cs.cs_net_paid) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    (SELECT ws2.ws_ship_mode_sk FROM web_sales ws2 WHERE ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk LIMIT 1) AS ws_ship_mode_ref
FROM catalog_sales cs
INNER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
INNER JOIN web_sales ws
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type = 'REGULAR                       '
GROUP BY sm.sm_ship_mode_id, sm.sm_ship_mode_sk
HAVING SUM(cs.cs_net_paid) > 413.91
