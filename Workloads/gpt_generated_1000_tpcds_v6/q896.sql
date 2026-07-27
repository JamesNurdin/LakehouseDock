WITH sales_agg AS (
  SELECT
    cs.cs_order_number,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_order_sales,
    SUM(cs.cs_coupon_amt) AS total_coupon,
    ca.ca_country,
    ca.ca_state,
    ca.ca_address_id
  FROM catalog_sales cs
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE cs.cs_net_paid_inc_ship_tax > 500
    AND ca.ca_country = 'United States'
  GROUP BY cs.cs_order_number, ca.ca_country, ca.ca_state, ca.ca_address_id
  HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 1500
),
returns_filtered AS (
  SELECT
    wr.wr_order_number,
    SUM(wr.wr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt,
    ca.ca_country AS refund_country,
    ca.ca_state AS refund_state
  FROM web_returns wr
  JOIN customer_address ca
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE wr.wr_return_amt > 0
    AND wr.wr_reason_sk IN (21, 58, 64)
    AND ca.ca_country = 'United States'
  GROUP BY wr.wr_order_number, ca.ca_country, ca.ca_state
)
SELECT
  s.cs_order_number,
  s.total_order_sales,
  s.total_coupon,
  s.ca_state,
  COALESCE(r.total_return_amt, 0) AS total_return_amt,
  CASE
    WHEN COALESCE(r.total_return_amt, 0) > 500 THEN 'HIGH_RETURN'
    WHEN COALESCE(r.total_return_amt, 0) > 100 THEN 'MEDIUM_RETURN'
    ELSE 'LOW_RETURN'
  END AS return_category,
  ROW_NUMBER() OVER (PARTITION BY s.ca_state ORDER BY s.total_order_sales DESC) AS state_sales_rank,
  AVG(s.total_order_sales) OVER (PARTITION BY s.ca_state) AS avg_sales_state
FROM sales_agg s
LEFT JOIN returns_filtered r
  ON s.cs_order_number = r.wr_order_number
WHERE s.total_order_sales > 2000
  AND (r.total_return_amt IS NULL OR r.total_return_amt > 50)
ORDER BY s.total_order_sales DESC, state_sales_rank
LIMIT 100
