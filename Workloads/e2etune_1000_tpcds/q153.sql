WITH customer_returns AS (
  SELECT
    sr.sr_customer_sk,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    COUNT(*) AS return_events
  FROM store_returns sr
  WHERE sr.sr_returned_date_sk BETWEEN 2449500 AND 2450500
    AND sr.sr_return_amt > 0
  GROUP BY sr.sr_customer_sk
),
preferred_customers AS (
  SELECT
    c.c_customer_sk,
    c.c_birth_month,
    c.c_salutation,
    c.c_preferred_cust_flag,
    c.c_current_hdemo_sk
  FROM customer c
  WHERE c.c_preferred_cust_flag = 'Y'
),
aggregated AS (
  SELECT
    pc.c_birth_month,
    pc.c_salutation,
    pc.c_current_hdemo_sk,
    COUNT(DISTINCT pc.c_customer_sk) AS num_customers,
    SUM(cr.total_return_amount) AS sum_return_amount,
    AVG(cr.total_return_quantity) AS avg_return_quantity
  FROM preferred_customers pc
  JOIN customer_returns cr
    ON pc.c_customer_sk = cr.sr_customer_sk
  GROUP BY pc.c_birth_month, pc.c_salutation, pc.c_current_hdemo_sk
  HAVING SUM(cr.total_return_amount) > 1000
)
SELECT
  a.c_birth_month,
  a.c_salutation,
  a.c_current_hdemo_sk,
  a.num_customers,
  a.sum_return_amount,
  a.avg_return_quantity,
  ROW_NUMBER() OVER (ORDER BY a.sum_return_amount DESC) AS rank_by_return_amount
FROM aggregated a
ORDER BY a.sum_return_amount DESC
LIMIT 10
