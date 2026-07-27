WITH catalog_agg AS (
  SELECT
    ca.ca_state AS state,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    'catalog' AS src
  FROM catalog_returns cr
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE cr.cr_return_amount > 50
  GROUP BY ca.ca_state
),
web_agg AS (
  SELECT
    ca.ca_state AS state,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt,
    'web' AS src
  FROM web_returns wr
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_max_ad_count >= 2
  GROUP BY ca.ca_state
),
avg_return AS (
  SELECT AVG(total_return_amount) AS avg_total_return_amount
  FROM (
    SELECT SUM(cr.cr_return_amount) AS total_return_amount FROM catalog_returns cr
    UNION ALL
    SELECT SUM(wr.wr_return_amt) AS total_return_amount FROM web_returns wr
  ) t
)
SELECT
  u.state,
  u.src,
  u.total_return_amount,
  u.return_cnt,
  a.avg_total_return_amount
FROM (
  SELECT state, src, total_return_amount, return_cnt FROM catalog_agg
  UNION ALL
  SELECT state, src, total_return_amount, return_cnt FROM web_agg
) u
CROSS JOIN avg_return a
ORDER BY u.state, u.src
