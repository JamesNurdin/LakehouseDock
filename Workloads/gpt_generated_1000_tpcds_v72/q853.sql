WITH preferred_customers AS (
    SELECT c_customer_sk, c_email_address
    FROM tpcds.customer
    WHERE c_preferred_cust_flag = 'Y'
)
SELECT
    pc.c_customer_sk,
    pc.c_email_address,
    'catalog' AS channel,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    MIN(cs.cs_sold_date_sk) AS first_sold_date_sk
FROM tpcds.catalog_sales cs
JOIN tpcds.time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN preferred_customers pc
  ON cs.cs_bill_customer_sk = pc.c_customer_sk
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE td.t_hour BETWEEN 9 AND 17
GROUP BY pc.c_customer_sk, pc.c_email_address

UNION ALL

SELECT
    pc.c_customer_sk,
    pc.c_email_address,
    'web' AS channel,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    MIN(ws.ws_sold_date_sk) AS first_sold_date_sk
FROM tpcds.web_sales ws
JOIN tpcds.time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN preferred_customers pc
  ON ws.ws_bill_customer_sk = pc.c_customer_sk
JOIN tpcds.ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE td.t_hour BETWEEN 9 AND 17
GROUP BY pc.c_customer_sk, pc.c_email_address

ORDER BY total_net_profit DESC
LIMIT 100
