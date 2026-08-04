WITH sampled_sales AS (
    SELECT cs_bill_customer_sk,
           cs_ship_customer_sk,
           cs_ext_discount_amt,
           cs_coupon_amt,
           cs_net_profit,
           cs_sold_date_sk
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
profit_customers AS (
    SELECT DISTINCT cs_bill_customer_sk AS customer_sk
    FROM sampled_sales s
    JOIN customer c
      ON s.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month IN (5, 7, 12)
      AND s.cs_net_profit > 500.00
),
coupon_customers AS (
    SELECT DISTINCT cs_ship_customer_sk AS customer_sk
    FROM sampled_sales s
    JOIN customer c
      ON s.cs_ship_customer_sk = c.c_customer_sk
    WHERE s.cs_coupon_amt > 200.00
      AND c.c_preferred_cust_flag = 'Y'
),
intersect_customers AS (
    SELECT customer_sk FROM profit_customers
    INTERSECT
    SELECT customer_sk FROM coupon_customers
)
SELECT
    ic.customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(s.cs_net_profit) AS total_net_profit,
    CASE WHEN SUM(s.cs_net_profit) > 1000 THEN 'High' ELSE 'Medium' END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY ic.customer_sk ORDER BY SUM(s.cs_net_profit) DESC) AS profit_rank
FROM intersect_customers ic
JOIN customer c
  ON ic.customer_sk = c.c_customer_sk
JOIN sampled_sales s
  ON s.cs_bill_customer_sk = ic.customer_sk OR s.cs_ship_customer_sk = ic.customer_sk
GROUP BY ic.customer_sk, c.c_first_name, c.c_last_name
ORDER BY total_net_profit DESC
LIMIT 100
