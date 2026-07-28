SELECT
    cd.cd_gender AS gender,
    cd.cd_credit_rating AS credit_rating,
    CASE
        WHEN cs.cs_net_profit > 1000 THEN 'High'
        ELSE 'Low'
    END AS profit_tier,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    MIN(cs.cs_sales_price) AS min_sales_price,
    MAX(cs.cs_sales_price) AS max_sales_price,
    COUNT(*) AS order_count
FROM catalog_sales cs
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE cs.cs_ext_discount_amt > 3000
  AND cs.cs_sales_price BETWEEN 20 AND 100
  AND cd.cd_credit_rating = 'Good'
  AND cd.cd_dep_college_count >= 2
  AND c.c_birth_year BETWEEN 1970 AND 1990
  AND EXISTS (
        SELECT 1
        FROM customer_demographics cd2
        WHERE cd2.cd_demo_sk = c.c_current_cdemo_sk
          AND cd2.cd_credit_rating = 'Good'
    )
GROUP BY cd.cd_gender,
         cd.cd_credit_rating,
         CASE
            WHEN cs.cs_net_profit > 1000 THEN 'High'
            ELSE 'Low'
         END
HAVING SUM(cs.cs_net_paid) > 50000
   AND COUNT(*) >= 10
ORDER BY total_net_paid DESC
LIMIT 100
