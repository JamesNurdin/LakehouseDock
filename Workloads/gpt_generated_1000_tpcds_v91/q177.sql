WITH
  billing AS (
    SELECT
      ca.ca_state AS state,
      t.part AS email_domain,
      cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    CROSS JOIN UNNEST(split(c.c_email_address, '@')) WITH ORDINALITY AS t(part, idx)
    WHERE c.c_last_review_date > 2452400
      AND idx = 2
  ),
  shipping AS (
    SELECT
      ca.ca_state AS state,
      t.part AS email_domain,
      cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    CROSS JOIN UNNEST(split(c.c_email_address, '@')) WITH ORDINALITY AS t(part, idx)
    WHERE c.c_first_shipto_date_sk BETWEEN 2450500 AND 2452000
      AND idx = 2
  ),
  combined AS (
    SELECT
      state,
      email_domain,
      net_profit
    FROM billing
    UNION ALL
    SELECT
      state,
      email_domain,
      net_profit
    FROM shipping
  )
SELECT
  state,
  email_domain,
  SUM(net_profit) AS total_net_profit,
  GROUPING(state) AS is_state_total,
  GROUPING(email_domain) AS is_email_total
FROM combined
GROUP BY GROUPING SETS (
  (state, email_domain),
  (state),
  (email_domain),
  ()
)
HAVING SUM(net_profit) > 5000
ORDER BY is_state_total, is_email_total, state, email_domain, total_net_profit DESC
LIMIT 100
