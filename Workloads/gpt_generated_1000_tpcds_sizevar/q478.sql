WITH eligible_customers AS (
   SELECT cs_bill_customer_sk AS customer_sk
   FROM catalog_sales
   JOIN date_dim ON cs_sold_date_sk = d_date_sk
   JOIN promotion ON cs_promo_sk = p_promo_sk
   WHERE d_year = 2001
     AND d_quarter_seq = 1
     AND p_channel_email = 'Y'
   GROUP BY cs_bill_customer_sk
),
air_ship_customers AS (
   SELECT cs_bill_customer_sk AS customer_sk
   FROM catalog_sales
   JOIN ship_mode ON cs_ship_mode_sk = sm_ship_mode_sk
   WHERE sm_type = 'AIR'
   GROUP BY cs_bill_customer_sk
),
intersect_customers AS (
   SELECT customer_sk FROM eligible_customers
   INTERSECT
   SELECT customer_sk FROM air_ship_customers
),
ca_customers AS (
   SELECT cs_bill_customer_sk AS customer_sk
   FROM catalog_sales
   JOIN customer_address ON cs_bill_addr_sk = ca_address_sk
   WHERE ca_state = 'CA'
   GROUP BY cs_bill_customer_sk
),
discount_active_customers AS (
   SELECT cs_bill_customer_sk AS customer_sk
   FROM catalog_sales
   JOIN promotion ON cs_promo_sk = p_promo_sk
   WHERE p_discount_active = 'Y'
   GROUP BY cs_bill_customer_sk
),
except_customers AS (
   SELECT customer_sk FROM ca_customers
   EXCEPT
   SELECT customer_sk FROM discount_active_customers
),
combined_customers AS (
   SELECT customer_sk FROM intersect_customers
   UNION ALL
   SELECT customer_sk FROM except_customers
),
sampled_sales AS (
   SELECT cs_bill_customer_sk AS customer_sk,
          SUM(cs_net_paid) AS total_spent
   FROM catalog_sales TABLESAMPLE BERNOULLI (10)
   GROUP BY cs_bill_customer_sk
)
SELECT cc.customer_sk,
       CASE WHEN ss.total_spent > 1000 THEN 'HIGH' ELSE 'LOW' END AS spend_category
FROM combined_customers cc
LEFT JOIN sampled_sales ss ON cc.customer_sk = ss.customer_sk
ORDER BY spend_category DESC, cc.customer_sk
LIMIT 100
