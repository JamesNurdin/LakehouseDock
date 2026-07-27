WITH
  catalog AS (
    SELECT
      cr.cr_net_loss AS net_loss,
      r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damaged')
      AND ca.ca_street_number LIKE '5%'
  ),
  web AS (
    SELECT
      wr.wr_net_loss AS net_loss,
      r.r_reason_desc AS reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damaged')
      AND ca.ca_street_number LIKE '5%'
      AND wp.wp_url LIKE '%promo%'
  )
SELECT
  u.reason_desc,
  COUNT(*) AS return_cnt,
  SUM(u.net_loss) AS total_net_loss,
  regexp_extract(u.reason_desc, '(\\w+)\\s+was\\s+damaged', 1) AS damage_type
FROM (
  SELECT * FROM catalog
  UNION ALL
  SELECT * FROM web
) AS u
GROUP BY
  u.reason_desc,
  regexp_extract(u.reason_desc, '(\\w+)\\s+was\\s+damaged', 1)
HAVING SUM(u.net_loss) > 1000
ORDER BY total_net_loss DESC
