WITH
  customer_sales_returns AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      c.c_preferred_cust_flag,
      SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
      SUM(ws.ws_ext_wholesale_cost) AS total_wholesale_cost,
      SUM(sr.sr_refunded_cash) AS total_refunded,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
      CASE
        WHEN SUM(ws.ws_net_paid_inc_ship_tax) > 10000 THEN 'HighValue'
        WHEN SUM(ws.ws_net_paid_inc_ship_tax) > 5000 THEN 'MidValue'
        ELSE 'LowValue'
      END AS customer_segment
    FROM tpcds.customer c
    JOIN tpcds.web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.store_returns sr
      ON sr.sr_customer_sk = c.c_customer_sk
    WHERE
      c.c_birth_year BETWEEN 1960 AND 1990
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_email_address LIKE '%@%org'
      AND ws.ws_net_paid_inc_ship_tax > 1000
      AND ws.ws_ext_wholesale_cost < 5000
      AND sr.sr_store_credit >= 20
      AND sr.sr_hdemo_sk IN (1497, 175, 1877)
    GROUP BY
      c.c_customer_sk,
      c.c_email_address,
      c.c_preferred_cust_flag
  ),
  filtered_customers AS (
    SELECT *
    FROM customer_sales_returns
    WHERE
      total_net_paid > 2000
      AND total_refunded < 500
      AND distinct_orders >= 2
  ),
  segment_summary AS (
    SELECT
      customer_segment,
      COUNT(*) AS num_customers,
      AVG(total_net_paid) AS avg_total_net_paid,
      SUM(total_refunded) AS sum_total_refunded
    FROM filtered_customers
    GROUP BY customer_segment
    HAVING AVG(total_net_paid) > 1500
  )
SELECT
  DISTINCT f.c_email_address,
  f.c_preferred_cust_flag,
  f.customer_segment,
  f.total_net_paid,
  f.total_refunded,
  f.distinct_orders,
  f.total_wholesale_cost,
  (f.total_net_paid - f.total_refunded) AS net_after_returns,
  s.num_customers,
  s.avg_total_net_paid,
  s.sum_total_refunded
FROM filtered_customers f
JOIN segment_summary s
  ON f.customer_segment = s.customer_segment
ORDER BY f.total_net_paid DESC, f.c_email_address
LIMIT 100
