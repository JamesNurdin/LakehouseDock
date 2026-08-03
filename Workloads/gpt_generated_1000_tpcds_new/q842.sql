WITH sampled_sales AS (
    SELECT cs_order_number,
           cs_bill_customer_sk,
           cs_ship_customer_sk,
           cs_net_paid_inc_ship,
           cs_coupon_amt,
           cs_promo_sk,
           cs_quantity,
           cs_ext_sales_price
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
sales_filtered AS (
    SELECT cs_order_number,
           cs_bill_customer_sk,
           cs_ship_customer_sk,
           cs_net_paid_inc_ship,
           cs_coupon_amt,
           cs_promo_sk,
           cs_quantity,
           cs_ext_sales_price
    FROM sampled_sales
    WHERE cs_net_paid_inc_ship > 3000
      AND cs_coupon_amt BETWEEN 100 AND 2000
      AND cs_promo_sk IN (479, 972, 1023)
),
cust_joined AS (
    SELECT sf.cs_order_number,
           sf.cs_net_paid_inc_ship,
           sf.cs_coupon_amt,
           sf.cs_quantity,
           sf.cs_ext_sales_price,
           c.c_customer_id,
           c.c_last_review_date,
           c.c_first_sales_date_sk,
           sf.cs_bill_customer_sk
    FROM sales_filtered sf
    JOIN customer c
      ON sf.cs_bill_customer_sk = c.c_customer_sk
),
ranked_sales AS (
    SELECT cj.cs_order_number,
           cj.c_customer_id,
           cj.cs_net_paid_inc_ship,
           cj.cs_coupon_amt,
           cj.cs_quantity,
           cj.cs_ext_sales_price,
           CASE
               WHEN cj.cs_coupon_amt > 1500 THEN 'HIGH'
               WHEN cj.cs_coupon_amt > 500 THEN 'MEDIUM'
               ELSE 'LOW'
           END AS coupon_category,
           RANK() OVER (ORDER BY cj.cs_net_paid_inc_ship DESC) AS sales_rank,
           ROW_NUMBER() OVER (PARTITION BY cj.c_customer_id ORDER BY cj.cs_net_paid_inc_ship DESC) AS rn
    FROM cust_joined cj
    WHERE cj.c_last_review_date > 2452400
),
top_ranked AS (
    SELECT cs_order_number,
           c_customer_id,
           cs_net_paid_inc_ship,
           coupon_category,
           sales_rank,
           rn
    FROM ranked_sales
    WHERE rn <= 5
),
other_set AS (
    SELECT cs_order_number,
           c_customer_id,
           cs_net_paid_inc_ship,
           coupon_category,
           sales_rank,
           rn
    FROM ranked_sales
    WHERE cs_net_paid_inc_ship BETWEEN 3000 AND 4000
)
SELECT *
FROM (
    SELECT *
    FROM top_ranked
    EXCEPT
    SELECT *
    FROM other_set
) AS diff
UNION DISTINCT
SELECT *
FROM top_ranked
WHERE coupon_category = 'HIGH'
ORDER BY cs_net_paid_inc_ship DESC
OFFSET 10
LIMIT 100
