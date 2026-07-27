WITH sales_agg AS (
    SELECT
        cs_bill_customer_sk,
        cs_sold_time_sk,
        cs_sold_date_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        AVG(cs_wholesale_cost) AS avg_wholesale_cost
    FROM catalog_sales
    WHERE cs_ext_wholesale_cost > 2000
      AND cs_sold_date_sk BETWEEN 2450820 AND 2450840
      AND cs_quantity > 0
      AND cs_wholesale_cost BETWEEN 20 AND 70
      AND cs_net_paid > 0
    GROUP BY cs_bill_customer_sk, cs_sold_time_sk, cs_sold_date_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    t.t_sub_shift,
    s.total_net_paid,
    s.total_quantity,
    CASE
        WHEN s.avg_wholesale_cost > 30 THEN 'HIGH'
        ELSE 'LOW'
    END AS wholesale_cost_category,
    RANK() OVER (PARTITION BY t.t_sub_shift ORDER BY s.total_net_paid DESC) AS rank_by_shift,
    ROW_NUMBER() OVER (ORDER BY s.total_net_paid DESC) AS overall_rank
FROM sales_agg s
JOIN customer c
    ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN time_dim t
    ON s.cs_sold_time_sk = t.t_time_sk
WHERE c.c_birth_country IN ('KOREA', 'UKRAINE', 'SURINAME')
  AND c.c_birth_month = 5
  AND c.c_birth_year > 1970
  AND t.t_second BETWEEN 1 AND 20
  AND t.t_sub_shift <> 'night'
  AND EXISTS (
        SELECT 1 FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
          AND cs2.cs_ext_discount_amt > 100
        LIMIT 1
      )
ORDER BY s.total_net_paid DESC
LIMIT 100
