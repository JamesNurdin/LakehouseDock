WITH store_sales_agg AS (
  SELECT
    ca.ca_state AS state,
    regexp_extract(p.p_promo_name, '([A-Z]{3}[0-9]{2})', 1) AS promo_code,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
    SUM(ss.ss_net_profit) AS net_profit,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE
    regexp_like(p.p_promo_name, '(?i)discount|sale')
    AND ca.ca_city LIKE '%ville%'
    AND p.p_channel_email = 'Y'
  GROUP BY
    ca.ca_state,
    regexp_extract(p.p_promo_name, '([A-Z]{3}[0-9]{2})', 1),
    CONCAT(ca.ca_city, ', ', ca.ca_state)
  HAVING
    SUM(ss.ss_net_profit) > 10000
),
web_sales_agg AS (
  SELECT
    ca.ca_state AS state,
    regexp_extract(p.p_promo_name, '([A-Z]{3}[0-9]{2})', 1) AS promo_code,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
    SUM(ws.ws_net_profit) AS net_profit,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE
    regexp_like(wp.wp_url, '^https?://[^/]+/sale/')
    AND ca.ca_state LIKE 'C%'
    AND p.p_channel_dmail = 'Y'
  GROUP BY
    ca.ca_state,
    regexp_extract(p.p_promo_name, '([A-Z]{3}[0-9]{2})', 1),
    CONCAT(ca.ca_city, ', ', ca.ca_state)
  HAVING
    SUM(ws.ws_net_profit) > 5000
),
combined AS (
  SELECT state, promo_code, net_profit FROM store_sales_agg
  UNION ALL
  SELECT state, promo_code, net_profit FROM web_sales_agg
)
SELECT
  state,
  promo_code,
  SUM(net_profit) AS total_net_profit,
  COUNT(*) AS contributing_segments
FROM combined
GROUP BY state, promo_code
HAVING SUM(net_profit) > 20000
ORDER BY total_net_profit DESC
LIMIT 10
