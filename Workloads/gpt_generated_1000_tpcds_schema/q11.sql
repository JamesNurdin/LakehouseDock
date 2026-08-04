WITH
  scalar_max_profit AS (
    SELECT max(cs_net_profit) AS max_profit
    FROM catalog_sales
    WHERE cs_promo_sk = 408
  ),
  small_states AS (
    SELECT DISTINCT ca_state
    FROM customer_address
    WHERE ca_state IS NOT NULL
    LIMIT 5
  ),
  promo_values AS (
    SELECT promo_sk
    FROM (VALUES (408), (745), (974)) AS v(promo_sk)
  ),
  cross_data AS (
    SELECT ss.ca_state, pv.promo_sk
    FROM small_states ss
    CROSS JOIN promo_values pv
  )
SELECT
  final_state,
  addr_type,
  total_sales,
  order_cnt
FROM (
  -- Sub‑query 1: right outer join keeps all billing addresses
  SELECT
    ca.ca_state AS final_state,
    CAST('BILL' AS VARCHAR) AS addr_type,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt
  FROM catalog_sales cs
  RIGHT OUTER JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE cs.cs_net_profit > (SELECT max_profit FROM scalar_max_profit)
    AND ca.ca_state = 'CA'
  GROUP BY ca.ca_state

  UNION ALL

  -- Sub‑query 2: inner join with a cross‑joined dimension set
  SELECT
    cd.ca_state AS final_state,
    CAST('CROSS' AS VARCHAR) AS addr_type,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt
  FROM catalog_sales cs
  INNER JOIN customer_address cd
    ON cs.cs_ship_addr_sk = cd.ca_address_sk
  INNER JOIN cross_data cr
    ON cd.ca_state = cr.ca_state
    AND cs.cs_promo_sk = cr.promo_sk
  WHERE cd.ca_gmt_offset = -5.00
  GROUP BY cd.ca_state
) combined
ORDER BY total_sales DESC
LIMIT 100
