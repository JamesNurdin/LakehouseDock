WITH income_bounds AS (
   SELECT ib_income_band_sk,
          CONCAT('Band ', CAST(ib_lower_bound AS VARCHAR), '-', CAST(ib_upper_bound AS VARCHAR)) AS income_band_label
   FROM income_band
),
customer_info AS (
   SELECT c.c_customer_sk,
          c.c_email_address,
          ca.ca_street_number,
          ca.ca_street_name,
          ca.ca_city,
          ca.ca_state,
          CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address,
          SUBSTRING(c.c_email_address FROM 1 FOR POSITION('@' IN c.c_email_address) - 1) AS email_user
   FROM customer c
   JOIN customer_address ca
     ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    ib.income_band_label,
    ci.full_address,
    ci.email_user,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(CASE WHEN sr.sr_fee > 30 THEN sr.sr_fee ELSE 0 END) AS high_fee_total
FROM store_returns sr
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_bounds ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_info ci
  ON sr.sr_customer_sk = ci.c_customer_sk
WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)price|product')
  AND i.i_product_name LIKE '%Gold%'
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = ci.c_customer_sk
          AND wp.wp_url LIKE 'https://%'
      )
GROUP BY
    ib.income_band_label,
    ci.full_address,
    ci.email_user
ORDER BY total_return_amount DESC
LIMIT 100
