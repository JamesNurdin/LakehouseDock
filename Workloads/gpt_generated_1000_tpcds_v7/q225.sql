WITH returns AS (
  SELECT
    c.c_customer_id,
    sr.sr_net_loss AS net_loss,
    i.i_item_desc,
    i.i_units,
    ca.ca_zip
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND regexp_like(i.i_item_desc, '.*[0-9]{3}.*')
    AND c.c_email_address LIKE '%@gmail.com'
    AND substring(ca.ca_zip, 1, 5) = '9410'
  UNION ALL
  SELECT
    c.c_customer_id,
    wr.wr_net_loss AS net_loss,
    i.i_item_desc,
    i.i_units,
    ca.ca_zip
  FROM web_returns wr
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND regexp_like(i.i_item_desc, '.*[0-9]{3}.*')
    AND c.c_email_address LIKE '%@gmail.com'
    AND substring(ca.ca_zip, 1, 5) = '9410'
)
SELECT
  r.c_customer_id,
  COUNT(*) AS total_returns,
  SUM(r.net_loss) AS total_net_loss,
  CONCAT('Cust-', r.c_customer_id) AS customer_label,
  MAX(regexp_extract(r.i_item_desc, '(\\d{3})')) AS sample_three_digits
FROM returns r
GROUP BY r.c_customer_id
ORDER BY total_net_loss DESC
LIMIT 50
