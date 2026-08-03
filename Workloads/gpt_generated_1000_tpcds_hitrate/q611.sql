WITH combined_sales AS (
  SELECT 
    c.c_customer_id AS customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    SUM(ss.ss_net_paid) AS total_sales,
    'Store' AS sales_channel,
    CASE WHEN SUM(ss.ss_net_paid) > 20000 THEN 'High' ELSE 'Low' END AS sales_category
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
  GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
  HAVING SUM(ss.ss_net_paid) > 5000

  UNION

  SELECT 
    c.c_customer_id AS customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    SUM(ws.ws_net_paid) AS total_sales,
    'Web' AS sales_channel,
    CASE WHEN SUM(ws.ws_net_paid) > 20000 THEN 'High' ELSE 'Low' END AS sales_category
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE wp.wp_type = 'content'
    AND p.p_discount_active = 'Y'
  GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
  HAVING SUM(ws.ws_net_paid) > 5000
)
SELECT 
  cs.customer_id,
  cs.customer_name,
  cs.total_sales,
  cs.sales_channel,
  cs.sales_category
FROM combined_sales cs
WHERE EXISTS (
  SELECT 1
  FROM customer c2
  JOIN customer_address ca ON c2.c_current_addr_sk = ca.ca_address_sk
  WHERE c2.c_customer_id = cs.customer_id
    AND ca.ca_city = 'SPRINGFIELD'
)
ORDER BY cs.total_sales DESC
LIMIT 100
