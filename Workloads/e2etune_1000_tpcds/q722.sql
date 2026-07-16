WITH filtered_sales AS (
  SELECT
    ss.ss_net_profit,
    ss.ss_ext_discount_amt,
    ss.ss_quantity,
    ss.ss_customer_sk,
    ss.ss_addr_sk,
    ss.ss_hdemo_sk
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE c.c_birth_month = 5
    AND c.c_birth_country = 'IRELAND'
    AND hd.hd_vehicle_count >= 2
    AND hd.hd_income_band_sk >= 5
),
state_agg AS (
  SELECT
    ca.ca_state,
    COUNT(DISTINCT fs.ss_customer_sk) AS distinct_customers,
    SUM(fs.ss_net_profit) AS total_net_profit,
    SUM(fs.ss_ext_discount_amt) AS total_discount,
    AVG(fs.ss_ext_discount_amt) AS avg_discount,
    SUM(fs.ss_quantity) AS total_quantity
  FROM filtered_sales fs
  JOIN customer_address ca ON fs.ss_addr_sk = ca.ca_address_sk
  GROUP BY ca.ca_state
  HAVING SUM(fs.ss_net_profit) > 0
)
SELECT
  sa.ca_state,
  sa.distinct_customers,
  sa.total_net_profit,
  sa.total_discount,
  sa.avg_discount,
  sa.total_quantity,
  RANK() OVER (ORDER BY sa.total_net_profit DESC) AS profit_rank
FROM state_agg sa
ORDER BY sa.total_net_profit DESC
LIMIT 10
