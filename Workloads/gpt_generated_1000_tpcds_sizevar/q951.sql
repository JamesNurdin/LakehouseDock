WITH web_agg AS (
  SELECT
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_state AS state,
    SUM(ws.ws_ext_sales_price) AS total_amount,
    SUM(ws.ws_net_profit) AS total_profit
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE regexp_like(i.i_item_desc, '^.*[A-Z]{2,}.*$')
    AND ca.ca_city LIKE '%Washington%'
    AND EXISTS (
      SELECT 1 FROM store_returns sr
      WHERE sr.sr_customer_sk = c.c_customer_sk
    )
  GROUP BY
    CONCAT(c.c_first_name, ' ', c.c_last_name),
    ca.ca_state
),
store_agg AS (
  SELECT
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_state AS state,
    SUM(sr.sr_return_amt) AS total_amount,
    SUM(sr.sr_net_loss) AS total_profit
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE regexp_extract(i.i_item_desc, '(\\d{3})', 1) IS NOT NULL
    AND ca.ca_city LIKE '%Washington%'
    AND EXISTS (
      SELECT 1 FROM web_sales ws
      WHERE ws.ws_bill_customer_sk = c.c_customer_sk
    )
  GROUP BY
    CONCAT(c.c_first_name, ' ', c.c_last_name),
    ca.ca_state
),
combined AS (
  SELECT customer_name, state, total_amount, total_profit FROM web_agg
  UNION
  SELECT customer_name, state, total_amount, total_profit FROM store_agg
)
SELECT *
FROM (
  SELECT
    customer_name,
    state,
    total_amount,
    CASE
      WHEN total_profit > 10000 THEN 'High'
      WHEN total_profit > 0 THEN 'Medium'
      ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_amount DESC) AS rn
  FROM combined
) ranked
WHERE rn <= 3
ORDER BY state, total_amount DESC
LIMIT 100
