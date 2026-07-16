WITH combined_sales AS (
    SELECT ss.ss_customer_sk AS cust_sk,
           td.t_shift AS shift_name,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    UNION ALL
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           td.t_shift AS shift_name,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           'web' AS channel
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
)
SELECT c.c_customer_id,
       cs.shift_name,
       SUM(CASE WHEN cs.channel = 'store' THEN cs.net_paid ELSE 0 END) AS total_store_net_paid,
       SUM(CASE WHEN cs.channel = 'store' THEN cs.net_profit ELSE 0 END) AS total_store_net_profit,
       SUM(CASE WHEN cs.channel = 'web' THEN cs.net_paid ELSE 0 END) AS total_web_net_paid,
       SUM(CASE WHEN cs.channel = 'web' THEN cs.net_profit ELSE 0 END) AS total_web_net_profit,
       (SUM(CASE WHEN cs.channel = 'web' THEN cs.net_profit ELSE 0 END) /
        NULLIF(SUM(CASE WHEN cs.channel = 'store' THEN cs.net_profit ELSE 0 END), 0)) AS web_to_store_profit_ratio
FROM combined_sales cs
JOIN customer c ON cs.cust_sk = c.c_customer_sk
GROUP BY c.c_customer_id, cs.shift_name
HAVING SUM(CASE WHEN cs.channel = 'store' THEN cs.net_profit ELSE 0 END) > 10000
ORDER BY web_to_store_profit_ratio DESC
LIMIT 10
