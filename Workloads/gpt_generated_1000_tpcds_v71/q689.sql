SELECT
  CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
  ca.ca_city,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  r.r_reason_desc,
  wp.wp_type,
  COUNT(*) AS num_returns,
  SUM(fr.cr_return_amount) AS total_return_amount,
  AVG(fr.cr_net_loss) AS avg_net_loss,
  CASE
    WHEN SUM(fr.cr_net_loss) > 0 THEN 'Net Loss'
    ELSE 'Net Gain'
  END AS net_loss_category,
  REGEXP_EXTRACT(r.r_reason_desc, '(price|warranty|service)', 1) AS matched_keyword,
  SUBSTR(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_prefix
FROM catalog_returns fr
JOIN reason r
  ON fr.cr_reason_sk = r.r_reason_sk
JOIN customer c
  ON fr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON fr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE REGEXP_LIKE(r.r_reason_desc, '(price|warranty|service)')
  AND ca.ca_city LIKE 'San%'
  AND REGEXP_LIKE(c.c_email_address, '@example\\.com$')
  AND wp.wp_url LIKE '%promo%'
GROUP BY
  CONCAT(c.c_first_name, ' ', c.c_last_name),
  ca.ca_city,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  r.r_reason_desc,
  wp.wp_type,
  REGEXP_EXTRACT(r.r_reason_desc, '(price|warranty|service)', 1),
  SUBSTR(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1)
ORDER BY total_return_amount DESC
LIMIT 100
