WITH
  catalog_agg AS (
    SELECT
      p.p_promo_name AS promo_name,
      ca.ca_state AS state,
      SUM(cs.cs_net_profit) AS total_net_profit
    FROM
      catalog_sales cs
      INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      INNER JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE
      cs.cs_sold_date_sk BETWEEN 2451910 AND 2451915
      AND p.p_channel_email = 'N'
    GROUP BY ROLLUP (p.p_promo_name, ca.ca_state)
  ),
  web_agg AS (
    SELECT
      p.p_promo_name AS promo_name,
      ca.ca_state AS state,
      SUM(ws.ws_net_profit) AS total_net_profit
    FROM
      web_sales ws
      INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      INNER JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE
      ws.ws_sold_date_sk BETWEEN 2451910 AND 2451915
      AND p.p_channel_email = 'N'
    GROUP BY ROLLUP (p.p_promo_name, ca.ca_state)
  )
SELECT
  'catalog' AS sales_channel,
  promo_name,
  state,
  total_net_profit
FROM
  catalog_agg
UNION ALL
SELECT
  'web' AS sales_channel,
  promo_name,
  state,
  total_net_profit
FROM
  web_agg
ORDER BY
  total_net_profit DESC
LIMIT 100
