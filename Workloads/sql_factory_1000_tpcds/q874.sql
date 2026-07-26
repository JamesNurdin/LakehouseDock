WITH combined_sales AS (
  SELECT
    cs.cs_bill_customer_sk AS cust_sk,
    cs.cs_bill_addr_sk AS addr_sk,
    cs.cs_promo_sk AS promo_sk,
    cs.cs_net_profit AS net_profit,
    cs.cs_net_paid AS net_paid,
    cs.cs_ext_discount_amt AS discount_amt
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ws.ws_bill_customer_sk,
    ws.ws_bill_addr_sk,
    ws.ws_promo_sk,
    ws.ws_net_profit,
    ws.ws_net_paid,
    ws.ws_ext_discount_amt
  FROM web_sales ws
)
SELECT
  ca.ca_address_id,
  ca.ca_city,
  ca.ca_state,
  c.cust_sk,
  SUM(c.net_profit) AS total_net_profit,
  SUM(c.net_paid) AS total_net_paid,
  SUM(c.discount_amt) AS total_discount,
  CASE
    WHEN SUM(c.net_profit) > 100000 THEN 'High'
    WHEN SUM(c.net_profit) > 50000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_category,
  RANK() OVER (ORDER BY SUM(c.net_profit) DESC) AS profit_rank,
  p.p_promo_name,
  CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
FROM combined_sales c
JOIN customer_address ca ON c.addr_sk = ca.ca_address_sk
JOIN promotion p ON c.promo_sk = p.p_promo_sk
GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state, c.cust_sk, p.p_promo_name, p.p_discount_active
ORDER BY total_net_profit DESC
LIMIT 10
