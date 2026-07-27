WITH filtered_sales AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_ship_cost > 1000
      AND cs.cs_net_paid_inc_ship_tax BETWEEN 2000 AND 8000
      AND cs.cs_ship_cdemo_sk IN (445334, 212342)
      AND cs.cs_quantity >= 2
)
SELECT
    c.c_birth_year,
    c.c_birth_month,
    COUNT(DISTINCT f.cs_bill_customer_sk) AS distinct_customers,
    SUM(f.cs_net_paid_inc_ship_tax) AS total_paid_inc_ship_tax,
    AVG(f.cs_ext_ship_cost) AS avg_ship_cost,
    MIN(f.cs_net_profit) AS min_net_profit,
    MAX(f.cs_net_profit) AS max_net_profit
FROM filtered_sales f
JOIN customer c
    ON f.cs_bill_customer_sk = c.c_customer_sk
WHERE c.c_birth_day = 15
  AND EXISTS (
      SELECT 1
      FROM catalog_sales cs2
      WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
        AND cs2.cs_quantity > 5
  )
GROUP BY c.c_birth_year, c.c_birth_month
ORDER BY total_paid_inc_ship_tax DESC
LIMIT 100
