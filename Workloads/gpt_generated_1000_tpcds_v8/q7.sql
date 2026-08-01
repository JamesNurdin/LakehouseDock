WITH
  store_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      SUM(sr.sr_return_amt) AS metric_value,
      'store_return' AS source_type
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_quantity > 10
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_sk, c.c_email_address
  ),
  web_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      SUM(wp.wp_char_count) AS metric_value,
      'web_page' AS source_type
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND wp.wp_char_count > 2000
    GROUP BY c.c_customer_sk, c.c_email_address
  ),
  combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
  )
SELECT
  c.c_customer_sk,
  c.c_email_address,
  c.source_type,
  c.metric_value,
  SUM(c.metric_value) OVER (
    PARTITION BY c.source_type
    ORDER BY c.metric_value DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total,
  LAG(c.metric_value) OVER (
    PARTITION BY c.source_type
    ORDER BY c.metric_value DESC
  ) AS previous_metric
FROM combined c
ORDER BY c.source_type, c.metric_value DESC
LIMIT 100
