WITH sales_agg AS (
   SELECT
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       CASE
           WHEN hd.hd_buy_potential = '0-500' THEN 'Low'
           WHEN hd.hd_buy_potential = '501-1000' THEN 'Medium'
           ELSE 'High'
       END AS buy_potential_category,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(*) AS transaction_count
   FROM catalog_sales cs
   LEFT JOIN household_demographics hd
       ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE cs.cs_ext_wholesale_cost > 1500.00
     AND cs.cs_ext_tax < 50.00
     AND cs.cs_quantity > 1
     AND c.c_birth_month IN (6, 12)
     AND c.c_birth_year BETWEEN 1960 AND 1985
     AND hd.hd_vehicle_count >= 1
     AND hd.hd_buy_potential NOT LIKE 'Unknown'
   GROUP BY
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       CASE
           WHEN hd.hd_buy_potential = '0-500' THEN 'Low'
           WHEN hd.hd_buy_potential = '501-1000' THEN 'Medium'
           ELSE 'High'
       END
)
SELECT
    s.c_customer_id,
    s.c_first_name,
    s.c_last_name,
    s.buy_potential_category,
    s.total_sales,
    s.total_profit,
    s.transaction_count,
    ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS sales_rank,
    RANK() OVER (PARTITION BY s.buy_potential_category ORDER BY s.total_profit DESC) AS profit_rank_within_category
FROM sales_agg s
ORDER BY s.total_sales DESC
LIMIT 100
