WITH catalog_agg AS (
  SELECT
    cs.cs_bill_customer_sk,
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    SUM(cs.cs_net_profit) AS catalog_profit
  FROM catalog_sales cs
  WHERE cs.cs_net_profit > 0
    AND cs.cs_quantity >= 1
    AND cs.cs_call_center_sk IS NOT NULL
    AND cs.cs_catalog_page_sk IS NOT NULL
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2455000
    AND cs.cs_ship_mode_sk IS NOT NULL
  GROUP BY cs.cs_bill_customer_sk, cs.cs_call_center_sk, cs.cs_catalog_page_sk
),
web_agg AS (
  SELECT
    ws.ws_bill_customer_sk,
    ws.ws_web_page_sk,
    SUM(ws.ws_net_profit) AS web_profit
  FROM web_sales ws
  WHERE ws.ws_net_profit > 0
    AND ws.ws_quantity >= 1
    AND ws.ws_web_page_sk IS NOT NULL
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
  GROUP BY ws.ws_bill_customer_sk, ws.ws_web_page_sk
)
SELECT
  c.c_customer_id,
  ca.ca_city,
  ca.ca_state,
  cc.cc_name AS call_center_name,
  cp.cp_type,
  wp.wp_url,
  (SELECT MAX(cs2.cs_sold_date_sk)
     FROM catalog_sales cs2
     WHERE cs2.cs_bill_customer_sk = c.c_customer_sk) AS max_catalog_sold_date_sk,
  (SELECT MAX(ws2.ws_sold_date_sk)
     FROM web_sales ws2
     WHERE ws2.ws_bill_customer_sk = c.c_customer_sk) AS max_web_sold_date_sk,
  caa.catalog_profit,
  wa.web_profit,
  (caa.catalog_profit + wa.web_profit) AS total_profit,
  CASE
    WHEN (caa.catalog_profit + wa.web_profit) > 20000 THEN 'HIGH'
    WHEN (caa.catalog_profit + wa.web_profit) > 0 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category
FROM customer c
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN catalog_agg caa
  ON c.c_customer_sk = caa.cs_bill_customer_sk
JOIN call_center cc
  ON caa.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON caa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_agg wa
  ON c.c_customer_sk = wa.ws_bill_customer_sk
JOIN web_page wp
  ON wa.ws_web_page_sk = wp.wp_web_page_sk
WHERE c.c_birth_year BETWEEN 1960 AND 1980
  AND ca.ca_state = 'TX'
  AND cc.cc_state = 'CA'
  AND cp.cp_type = 'monthly'
  AND wp.wp_link_count > 10
ORDER BY total_profit DESC
LIMIT 100
