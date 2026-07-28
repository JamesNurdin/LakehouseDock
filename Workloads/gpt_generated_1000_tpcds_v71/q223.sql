WITH aggregated AS (
  SELECT
    ca.ca_state,
    ca.ca_city,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_returns,
    SUM(wr.wr_fee) AS total_fee,
    SUM(ss.ss_ext_sales_price) - SUM(wr.wr_return_amt) AS net_sales_after_returns
  FROM store_sales ss
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN web_returns wr
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE ca.ca_state = 'CA'                                   -- predicate 1
    AND ca.ca_city IN ('Main', 'Smith', 'Elm')               -- predicate 2
    AND ca.ca_location_type = 'single family'               -- predicate 3
    AND ss.ss_coupon_amt > 100                               -- predicate 4
    AND ss.ss_net_paid_inc_tax BETWEEN 100 AND 20000         -- predicate 5
    AND wr.wr_fee > 30                                       -- predicate 6
    AND wr.wr_returning_addr_sk IN (4798793, 5161586)        -- predicate 7
  GROUP BY ROLLUP (ca.ca_state, ca.ca_city)
)
SELECT
  a.ca_state,
  a.ca_city,
  a.total_store_sales,
  a.total_return_amount,
  a.distinct_tickets,
  a.distinct_returns,
  CASE WHEN a.total_fee > (SELECT AVG(wr3.wr_fee) FROM web_returns wr3) THEN 'HIGH' ELSE 'LOW' END AS fee_category,
  RANK() OVER (PARTITION BY a.ca_state ORDER BY a.total_store_sales DESC) AS sales_rank_within_state,
  a.net_sales_after_returns
FROM aggregated a
WHERE a.ca_state IS NOT NULL
ORDER BY a.ca_state, sales_rank_within_state
LIMIT 100
