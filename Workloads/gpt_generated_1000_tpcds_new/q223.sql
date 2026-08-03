WITH combined AS (
  -- First branch: Catalog sales joined to address and promotion
  SELECT
    cs.cs_order_number AS order_number,
    cs.cs_net_profit   AS net_profit,
    ca.ca_state        AS state,
    p.p_promo_name     AS promo_name
  FROM catalog_sales cs
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  WHERE p.p_channel_dmail = 'Y'
    AND p.p_item_sk = 17185
    AND cs.cs_ext_tax > 50

  UNION

  -- Second branch: Web sales joined to promotion, web page and shipping address
  SELECT
    ws.ws_order_number AS order_number,
    ws.ws_net_profit   AS net_profit,
    ca2.ca_state       AS state,
    p2.p_promo_name    AS promo_name
  FROM web_sales ws
  JOIN promotion p2
    ON ws.ws_promo_sk = p2.p_promo_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN customer_address ca2
    ON ws.ws_ship_addr_sk = ca2.ca_address_sk
  WHERE wp.wp_max_ad_count >= 2
    AND ws.ws_quantity >= 2
),
agg AS (
  SELECT
    state,
    promo_name,
    SUM(net_profit)               AS total_profit,
    COUNT(DISTINCT order_number)  AS orders_cnt,
    MIN(net_profit)                AS min_profit,
    MAX(net_profit)                AS max_profit
  FROM combined
  GROUP BY state, promo_name
)
SELECT
  ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS row_num,
  state,
  promo_name,
  total_profit,
  orders_cnt,
  min_profit,
  max_profit
FROM agg
ORDER BY total_profit DESC
LIMIT 100
