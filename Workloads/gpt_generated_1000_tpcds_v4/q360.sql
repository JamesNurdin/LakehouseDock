WITH sales_agg AS (
    SELECT ss_customer_sk,
           SUM(ss_net_paid) AS total_net_paid
    FROM store_sales
    GROUP BY ss_customer_sk
)
SELECT r.r_reason_desc,
       COUNT(*) AS return_count,
       SUM(sr.sr_return_amt) AS total_return_amount,
       SUM(sr.sr_net_loss) AS total_net_loss,
       AVG(sr.sr_return_tax) AS avg_return_tax,
       arbitrary(REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1)) AS sample_email_domain,
       arbitrary(CONCAT(ca.ca_city, ', ', ca.ca_state)) AS sample_location
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN sales_agg sa ON c.c_customer_sk = sa.ss_customer_sk
WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
  AND ca.ca_suite_number LIKE 'Suite %'
  AND ca.ca_zip LIKE '7%'
  AND regexp_like(r.r_reason_desc, 'working')
  AND sa.total_net_paid > (SELECT AVG(total_net_paid) FROM sales_agg)
GROUP BY r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
