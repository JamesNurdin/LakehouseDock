WITH returns_agg AS (
  SELECT ca.ca_city AS city,
         ca.ca_state AS state,
         'return' AS source,
         SUM(r.sr_net_loss) AS amount,
         COUNT(*) AS txn_cnt
  FROM store_returns r
  JOIN customer_address ca ON r.sr_addr_sk = ca.ca_address_sk
  JOIN time_dim t ON r.sr_return_time_sk = t.t_time_sk
  WHERE regexp_like(ca.ca_street_name, '^G.*')
    AND t.t_meal_time = 'lunch'
  GROUP BY ca.ca_city, ca.ca_state
),
sales_agg AS (
  SELECT ca.ca_city AS city,
         ca.ca_state AS state,
         'sale' AS source,
         SUM(s.ss_net_paid) AS amount,
         COUNT(*) AS txn_cnt
  FROM store_sales s
  JOIN customer_address ca ON s.ss_addr_sk = ca.ca_address_sk
  JOIN time_dim t ON s.ss_sold_time_sk = t.t_time_sk
  WHERE ca.ca_street_name LIKE '%College%'
    AND t.t_meal_time = 'dinner'
    AND regexp_extract(ca.ca_address_id, '(A{5,})', 1) IS NOT NULL
  GROUP BY ca.ca_city, ca.ca_state
),
combined AS (
  SELECT * FROM returns_agg
  UNION ALL
  SELECT * FROM sales_agg
)
SELECT c.city,
       c.state,
       c.source,
       c.amount,
       c.txn_cnt,
       concat(c.city, ', ', c.state) AS location
FROM combined c
WHERE NOT EXISTS (
  SELECT 1
  FROM customer_address ca2
  WHERE ca2.ca_city = c.city
    AND ca2.ca_state = c.state
    AND ca2.ca_zip LIKE '9%'
)
ORDER BY c.amount DESC, c.city
LIMIT 100
