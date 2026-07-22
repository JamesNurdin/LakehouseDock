SELECT
   c.c_customer_sk,
   concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
   c.c_email_address,
   regexp_extract(c.c_email_address, '@(.+)$') AS email_domain,
   COUNT(DISTINCT wr.wr_order_number) AS num_returns,
   SUM(wr.wr_net_loss) AS total_net_loss,
   AVG(wr.wr_return_amt) AS avg_return_amount,
   (SELECT MAX(wr2.wr_return_amt) FROM web_returns wr2 WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk) AS max_refunded_return_amt
FROM web_returns wr
JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE regexp_like(c.c_email_address, '^[A-Za-z]+\\.[A-Za-z]+@.*\\.edu$')
  AND wp.wp_url LIKE 'http://%/products/%'
  AND wp.wp_autogen_flag = 'N'
  AND wr.wr_return_amt > 100
GROUP BY
   c.c_customer_sk,
   c.c_first_name,
   c.c_last_name,
   c.c_email_address,
   regexp_extract(c.c_email_address, '@(.+)$')
ORDER BY total_net_loss DESC
LIMIT 100
