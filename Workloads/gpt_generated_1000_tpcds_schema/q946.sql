WITH cs_sample AS (
  SELECT
    cs_order_number,
    cs_bill_customer_sk,
    cs_ship_customer_sk,
    cs_call_center_sk,
    cs_bill_addr_sk,
    cs_ship_addr_sk,
    cs_net_paid_inc_ship_tax
  FROM catalog_sales
  TABLESAMPLE BERNOULLI (10)
  WHERE cs_net_paid_inc_ship_tax > 500
),
intersect_customers AS (
  SELECT cs_bill_customer_sk AS cust_id
  FROM cs_sample
  INTERSECT
  SELECT sr_customer_sk FROM store_returns
),
except_customers AS (
  SELECT cust_id FROM intersect_customers
  EXCEPT
  SELECT wr_refunded_customer_sk FROM web_returns
)
SELECT
  c.c_customer_sk,
  c.c_first_name,
  c.c_last_name,
  cc.cc_name AS call_center_name,
  ca_bill.ca_street_number,
  ca_bill.ca_street_name,
  ca_bill.ca_city,
  SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
  SUM(sr.sr_net_loss) AS total_store_loss,
  SUM(wr.wr_net_loss) AS total_web_loss
FROM intersect_customers ic
JOIN cs_sample cs ON cs.cs_bill_customer_sk = ic.cust_id
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c ON ic.cust_id = c.c_customer_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_returns sr ON sr.sr_customer_sk = ic.cust_id
JOIN web_returns wr ON wr.wr_refunded_customer_sk = ic.cust_id
JOIN web_page wp ON wp.wp_customer_sk = ic.cust_id
WHERE ic.cust_id NOT IN (
    SELECT c2.c_customer_sk
    FROM customer c2
    WHERE c2.c_preferred_cust_flag = 'Y'
)
AND EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_customer_sk = ic.cust_id
      AND wp2.wp_type = 'article'
)
GROUP BY
  c.c_customer_sk,
  c.c_first_name,
  c.c_last_name,
  cc.cc_name,
  ca_bill.ca_street_number,
  ca_bill.ca_street_name,
  ca_bill.ca_city
ORDER BY total_sales DESC
LIMIT 100
