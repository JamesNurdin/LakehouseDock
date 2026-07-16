SELECT
    sm.sm_ship_mode_id,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM catalog_sales cs
INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN (
    SELECT cr_returned_date_sk, cr_returned_time_sk, cr_item_sk, cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount > 23.17
) cr ON cr.cr_order_number = cs.cs_order_number
GROUP BY sm.sm_ship_mode_id
HAVING sm.sm_ship_mode_id > 'AAAAAAAACBAAAAAA'
