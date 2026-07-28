WITH joined AS (
  SELECT
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    ca.ca_suite_number,
    cs.cs_ext_ship_cost,
    cs.cs_net_paid AS cs_net_paid,
    ss.ss_list_price,
    ss.ss_net_paid AS ss_net_paid
  FROM catalog_sales cs
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN store_sales ss
    ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE cs.cs_ext_ship_cost > 500
    AND ss.ss_list_price > 50
    AND ca.ca_suite_number LIKE 'Suite %'
),
agg AS (
  SELECT
    ca_address_sk,
    ca_city,
    ca_state,
    ca_suite_number,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ss_net_paid) AS total_store_net_paid,
    SUM(cs_net_paid + ss_net_paid) AS total_combined_net_paid
  FROM joined
  GROUP BY ca_address_sk, ca_city, ca_state, ca_suite_number
)
SELECT
  ca_address_sk,
  ca_city,
  ca_state,
  ca_suite_number,
  total_catalog_net_paid,
  total_store_net_paid,
  total_combined_net_paid,
  RANK() OVER (ORDER BY total_combined_net_paid DESC) AS revenue_rank
FROM agg
ORDER BY total_combined_net_paid DESC
LIMIT 100
