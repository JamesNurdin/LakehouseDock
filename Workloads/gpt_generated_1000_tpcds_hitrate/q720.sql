WITH filtered_sales AS (
   SELECT
       cs_bill_customer_sk,
       cs_ship_customer_sk,
       cs_item_sk,
       cs_promo_sk,
       cs_ext_tax,
       cs_ext_list_price,
       cs_net_profit,
       CASE WHEN cs_ext_tax > 50 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS tax_category
   FROM catalog_sales
   WHERE cs_ext_tax > 20
     AND cs_ext_list_price BETWEEN 1000 AND 8000
     AND cs_net_profit IS NOT NULL
),
eligible_customers AS (
   SELECT c_customer_sk
   FROM customer
   WHERE c_birth_year BETWEEN 1960 AND 1980
     AND c_preferred_cust_flag = 'Y'
),
excluded_customers AS (
   SELECT c_customer_sk
   FROM customer
   WHERE c_current_hdemo_sk = 9999
),
valid_customers AS (
   SELECT c_customer_sk
   FROM eligible_customers
   EXCEPT
   SELECT c_customer_sk
   FROM excluded_customers
)
SELECT
   bc.c_customer_sk AS bill_customer_sk,
   COUNT(DISTINCT f.cs_item_sk) AS distinct_items,
   COUNT(DISTINCT f.cs_promo_sk) AS distinct_promos,
   SUM(f.cs_net_profit) AS total_profit,
   AVG(f.cs_ext_tax) AS avg_tax,
   CASE WHEN SUM(f.cs_net_profit) > 10000 THEN 'BIG_PROFIT' ELSE 'SMALL_PROFIT' END AS profit_category,
   (SELECT SUM(cs_ext_discount_amt)
    FROM catalog_sales cs_sub
    WHERE cs_sub.cs_ship_customer_sk = sc.c_customer_sk) AS ship_customer_total_discount,
   (SELECT COUNT(*)
    FROM catalog_sales cs_check
    WHERE cs_check.cs_bill_customer_sk = bc.c_customer_sk
      AND cs_check.cs_ext_tax > 30) AS high_tax_bill_count
FROM filtered_sales f
JOIN valid_customers vc ON f.cs_bill_customer_sk = vc.c_customer_sk
JOIN customer bc ON bc.c_customer_sk = vc.c_customer_sk
JOIN customer sc ON sc.c_customer_sk = f.cs_ship_customer_sk
WHERE bc.c_current_hdemo_sk IN (3577, 1708, 4094)
  AND bc.c_birth_month = 5
  AND sc.c_birth_day = 12
GROUP BY bc.c_customer_sk, bc.c_current_hdemo_sk, bc.c_birth_month, sc.c_customer_sk
HAVING COUNT(DISTINCT f.cs_item_sk) > 5
ORDER BY total_profit DESC
LIMIT 100
