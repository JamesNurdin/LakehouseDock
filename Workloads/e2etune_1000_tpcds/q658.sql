WITH agg AS (
  SELECT
    c.c_birth_country,
    r.r_reason_desc,
    wp.wp_type,
    COUNT(DISTINCT sr.sr_customer_sk) AS num_customers,
    SUM(sr.sr_refunded_cash) AS total_refunded,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    SUM(sr.sr_net_loss) AS total_net_loss
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_country IN ('CHILE', 'MEXICO', 'FIJI')
    AND wp.wp_type = 'product'
    AND sr.sr_returned_date_sk >= 2450000
  GROUP BY c.c_birth_country, r.r_reason_desc, wp.wp_type
  HAVING SUM(sr.sr_refunded_cash) > 1000
)
SELECT
  c_birth_country,
  r_reason_desc,
  wp_type,
  num_customers,
  total_refunded,
  avg_return_qty,
  total_net_loss,
  RANK() OVER (PARTITION BY c_birth_country ORDER BY total_refunded DESC) AS refund_rank_by_country
FROM agg
ORDER BY total_refunded DESC
LIMIT 100
