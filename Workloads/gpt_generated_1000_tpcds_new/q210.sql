WITH
  catalog_part AS (
    SELECT
      ca.ca_state,
      ca.ca_city,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_city, '^S.*')
      AND ca.ca_street_number LIKE '5%'
    GROUP BY ca.ca_state, ca.ca_city
  ),
  web_part AS (
    SELECT
      ca.ca_state,
      ca.ca_city,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(*) AS order_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_address ca
      ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_city, 'field$')
      AND regexp_extract(ca.ca_zip, '(\\d{3})\\d{2}', 1) = '123'
    GROUP BY ca.ca_state, ca.ca_city
  ),
  combined AS (
    SELECT ca_state, ca_city, total_profit, order_cnt FROM catalog_part
    UNION DISTINCT
    SELECT ca_state, ca_city, total_profit, order_cnt FROM web_part
  )
SELECT
  ca_state,
  ca_city,
  total_profit,
  order_cnt,
  ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_profit DESC) AS city_rank
FROM combined
ORDER BY total_profit DESC
LIMIT 100
