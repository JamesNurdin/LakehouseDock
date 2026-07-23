WITH bill_cust AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_country,
        c.c_birth_year,
        c.c_birth_day
    FROM customer c
    WHERE c.c_birth_country IN ('KOREA', 'BHUTAN', 'VANUATU')
)
SELECT
    bc.c_birth_country,
    bc.c_birth_year,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(cs.cs_ext_discount_amt) AS max_discount,
    SUM(CASE WHEN cs.cs_quantity > 10 THEN cs.cs_ext_sales_price ELSE 0 END) AS large_qty_sales
FROM catalog_sales cs
JOIN bill_cust bc
    ON cs.cs_bill_customer_sk = bc.c_customer_sk
WHERE cs.cs_ext_list_price > 5000
  AND cs.cs_ship_date_sk BETWEEN 2450890 AND 2450900
  AND EXISTS (
      SELECT 1
      FROM customer sc
      WHERE sc.c_customer_sk = cs.cs_ship_customer_sk
        AND sc.c_birth_country = 'KOREA'
  )
GROUP BY bc.c_birth_country, bc.c_birth_year
ORDER BY total_net_paid DESC
LIMIT 100
