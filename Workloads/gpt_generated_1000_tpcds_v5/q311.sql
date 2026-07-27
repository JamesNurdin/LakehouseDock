SELECT
    td.t_shift AS shift,
    'store' AS channel,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss.ss_net_profit) >= 10000 THEN 'high' ELSE 'low' END AS profit_category
FROM store_sales ss
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE td.t_hour BETWEEN 8 AND 20
GROUP BY td.t_shift
HAVING SUM(ss.ss_net_profit) > 0

UNION ALL

SELECT
    td.t_shift AS shift,
    'web' AS channel,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) >= 8000 THEN 'high' ELSE 'low' END AS profit_category
FROM web_sales ws
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE td.t_hour BETWEEN 8 AND 20
GROUP BY td.t_shift
HAVING SUM(ws.ws_net_profit) > 0

ORDER BY total_profit DESC, shift
LIMIT 100
