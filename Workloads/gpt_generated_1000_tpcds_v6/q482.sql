WITH sales_2022 AS (
  SELECT
    ca.ca_state,
    '2022_catalog' AS source,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2022
    AND p.p_channel_catalog = 'Y'
  GROUP BY ca.ca_state
  HAVING SUM(ss.ss_net_profit) > 10000
),
sales_2023 AS (
  SELECT
    ca.ca_state,
    '2023_press' AS source,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2023
    AND p.p_channel_press = 'Y'
  GROUP BY ca.ca_state
  HAVING SUM(ss.ss_net_profit) > 15000
)
SELECT DISTINCT
  state,
  source,
  total_profit,
  ticket_cnt,
  ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_profit DESC) AS profit_rank
FROM (
  SELECT ca_state AS state, source, total_profit, ticket_cnt FROM sales_2022
  UNION ALL
  SELECT ca_state AS state, source, total_profit, ticket_cnt FROM sales_2023
) combined
ORDER BY total_profit DESC, source
LIMIT 100
