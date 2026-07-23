SELECT
    sm.sm_carrier,
    sm.sm_contract,
    COUNT(*) AS order_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_list_price) AS avg_list_price
FROM
    web_sales ws
JOIN
    ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    sm.sm_carrier = 'MSC'
    AND ws.ws_list_price > 80
GROUP BY
    sm.sm_carrier,
    sm.sm_contract
ORDER BY
    total_net_profit DESC
