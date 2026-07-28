WITH
store_profit AS (
  SELECT
    s.s_store_id AS entity_id,
    s.s_city AS entity_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS metric1,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_quantity) AS avg_quantity,
    SUM(CASE WHEN p.p_channel_tv = 'Y' THEN ss.ss_net_profit ELSE 0 END) AS promo_profit,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN ss.ss_net_profit ELSE 0 END) AS gender_profit
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  WHERE s.s_state = 'CA'
    AND ca.ca_country = 'United States'
    AND p.p_discount_active = 'Y'
    AND cd.cd_education_status IN ('College','Advanced Degree')
    AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    AND ss.ss_quantity > 0
  GROUP BY s.s_store_id, s.s_city
  HAVING SUM(ss.ss_net_profit) > 10000
),
web_profit AS (
  SELECT
    CAST(ws.ws_web_site_sk AS VARCHAR) AS entity_id,
    w.web_name AS entity_name,
    COUNT(DISTINCT ws.ws_order_number) AS metric1,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(CASE WHEN p.p_channel_email = 'Y' THEN ws.ws_net_profit ELSE 0 END) AS promo_profit,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN ws.ws_net_profit ELSE 0 END) AS gender_profit
  FROM web_sales ws
  JOIN web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse wh
    ON ws.ws_warehouse_sk = wh.w_warehouse_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  WHERE w.web_state = 'TX'
    AND p.p_response_target >= 5
    AND cd.cd_purchase_estimate >= 3000
    AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    AND sm.sm_type = 'AIR'
    AND ca.ca_country = 'United States'
    AND wh.w_state = 'TX'
  GROUP BY ws.ws_web_site_sk, w.web_name
  HAVING SUM(ws.ws_net_profit) > 5000
)
SELECT entity_id, entity_name, metric1, total_profit, avg_quantity, promo_profit, gender_profit
FROM store_profit
UNION ALL
SELECT entity_id, entity_name, metric1, total_profit, avg_quantity, promo_profit, gender_profit
FROM web_profit
ORDER BY total_profit DESC
LIMIT 100
