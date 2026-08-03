WITH filtered_sales AS (
   SELECT
       cs.cs_bill_customer_sk,
       cs.cs_ship_customer_sk,
       cs.cs_ext_sales_price,
       cs.cs_net_profit,
       cs.cs_ext_discount_amt,
       cd_bill.cd_credit_rating AS bill_credit_rating,
       cd_ship.cd_credit_rating AS ship_credit_rating,
       cd_bill.cd_purchase_estimate
   FROM catalog_sales cs
   JOIN customer_demographics cd_bill
       ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_demographics cd_ship
       ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
   WHERE cs.cs_list_price > 20
     AND cs.cs_quantity BETWEEN 1 AND 5
     AND cd_bill.cd_credit_rating IN ('Good', 'Low Risk')
     AND cd_ship.cd_credit_rating = 'High Risk'
     AND cs.cs_ext_discount_amt < 500
),
agg_sales AS (
   SELECT
       cs_bill_customer_sk,
       cs_ship_customer_sk,
       bill_credit_rating,
       SUM(cs_ext_sales_price) AS total_sales,
       SUM(cs_net_profit) AS total_profit,
       CASE
           WHEN SUM(cs_ext_sales_price) > 10000 THEN 'High'
           WHEN SUM(cs_ext_sales_price) > 5000 THEN 'Medium'
           ELSE 'Low'
       END AS sales_category
   FROM filtered_sales
   WHERE cs_bill_customer_sk NOT IN (
       SELECT cs_bill_customer_sk FROM catalog_sales WHERE cs_ext_discount_amt > 2000
   )
   GROUP BY ROLLUP (cs_bill_customer_sk, cs_ship_customer_sk, bill_credit_rating)
   HAVING SUM(cs_ext_sales_price) IS NOT NULL
)
SELECT
   cs_bill_customer_sk,
   cs_ship_customer_sk,
   bill_credit_rating,
   total_sales,
   total_profit,
   sales_category,
   RANK() OVER (PARTITION BY bill_credit_rating ORDER BY total_sales DESC) AS sales_rank,
   (SELECT AVG(cs_ext_discount_amt) FROM catalog_sales) AS overall_avg_discount
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
