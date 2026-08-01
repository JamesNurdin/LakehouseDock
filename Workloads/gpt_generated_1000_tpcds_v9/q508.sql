WITH customer_return_summary AS (
  SELECT
    cr.cr_refunded_customer_sk AS customer_sk,
    reason.r_reason_desc AS reason_desc,
    SUM(cr.cr_net_loss) AS total_net_loss,
    MAX(d.d_date) AS latest_return_date,
    REGEXP_EXTRACT(reason.r_reason_desc, '(?i)(product)', 1) AS extracted_word,
    SUBSTR(reason.r_reason_desc, 1, 30) AS short_reason_desc
  FROM catalog_returns cr
  JOIN reason ON cr.cr_reason_sk = reason.r_reason_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE REGEXP_LIKE(reason.r_reason_desc, '(?i)product')
    AND reason.r_reason_desc LIKE '%product%'
    AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  GROUP BY cr.cr_refunded_customer_sk, reason.r_reason_desc
)
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  crs.total_net_loss,
  crs.latest_return_date,
  CONCAT('Reason: ', crs.short_reason_desc) AS reason_snippet,
  crs.extracted_word,
  (SELECT SUM(cs.cs_ext_sales_price)
   FROM catalog_sales cs
   WHERE cs.cs_bill_customer_sk = c.c_customer_sk) AS total_sales_amount
FROM customer_return_summary crs
JOIN customer c ON c.c_customer_sk = crs.customer_sk
WHERE crs.total_net_loss > (
    SELECT SUM(cs2.cs_ext_sales_price)
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
  ) * 0.05
ORDER BY crs.total_net_loss DESC
LIMIT 100
