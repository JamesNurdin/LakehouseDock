WITH
  store_cust AS (
    SELECT DISTINCT sr.sr_customer_sk AS c_customer_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z]+\.[A-Za-z]+@.*\\.com$')
      AND c.c_email_address LIKE '%@%.com'
      AND regexp_like(r.r_reason_desc, '(?i)damage')
  ),
  web_cust AS (
    SELECT DISTINCT wr.wr_refunded_customer_sk AS c_customer_sk
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z]+\.[A-Za-z]+@.*\\.com$')
      AND c.c_email_address LIKE '%@%.com'
      AND r.r_reason_id LIKE 'AAAA%'
  ),
  cust_intersect AS (
    SELECT c_customer_sk FROM store_cust
    INTERSECT
    SELECT c_customer_sk FROM web_cust
  ),
  agg_metrics AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss,
      SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss,
      SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
      CASE
        WHEN SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) >
             (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2)
        THEN 'Above Avg'
        ELSE 'Below Avg'
      END AS loss_category,
      regexp_extract(c.c_email_address, '@([^.]*)\\.com', 1) AS email_domain
    FROM cust_intersect ci
    JOIN customer c ON ci.c_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    GROUP BY
      c.c_customer_sk,
      c.c_email_address,
      regexp_extract(c.c_email_address, '@([^.]*)\\.com', 1)
    HAVING SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 1000
  )
SELECT
  am.c_customer_sk,
  am.c_email_address,
  am.email_domain,
  am.store_net_loss,
  am.web_net_loss,
  am.total_net_loss,
  am.loss_category,
  r.r_reason_desc,
  v.val
FROM agg_metrics am
CROSS JOIN (VALUES (1), (2), (3)) AS v(val)
LEFT JOIN reason r ON r.r_reason_desc LIKE '%return%'
WHERE EXISTS (
  SELECT 1
  FROM store_sales ss
  WHERE ss.ss_customer_sk = am.c_customer_sk
    AND ss.ss_net_paid > 0
)
ORDER BY am.total_net_loss DESC
LIMIT 100
